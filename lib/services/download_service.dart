import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import '../core/errors/app_exceptions.dart';
import '../models/download_task.dart';
import '../models/quality_option.dart';
import '../models/video_info.dart';
import 'process_service.dart';

typedef DownloadProgressCallback = void Function(DownloadTask task);
typedef DownloadLogCallback = void Function(String line);

/// Service responsible for managing real-time video downloading,
/// progress parsing, and process lifecycle cancellation.
class DownloadService {
  final ProcessService _processService;
  final String? executableOverride;

  io.Process? _activeProcess;
  DownloadTask? _currentTask;
  bool _cancelled = false;

  DownloadService({
    ProcessService? processService,
    this.executableOverride,
  }) : _processService = processService ?? const SystemProcessService();

  String get executablePath {
    final override = executableOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return io.Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
  }

  /// Whether a download is currently running.
  bool get isDownloading =>
      _currentTask != null &&
      _currentTask!.status == DownloadStatus.downloading;

  /// Starts downloading a video with the specified quality option to the target directory.
  Future<void> startDownload({
    required VideoInfo video,
    required QualityOption quality,
    required String destinationDirectory,
    required DownloadProgressCallback onProgress,
    DownloadLogCallback? onLog,
  }) async {
    if (isDownloading) {
      throw const ProcessExecutionException('A download is already in progress.');
    }

    _cancelled = false;

    final task = DownloadTask(
      id: video.id,
      url: video.webpageUrl ?? 'https://www.youtube.com/watch?v=${video.id}',
      title: video.title,
      destinationPath: destinationDirectory,
      formatId: quality.id,
      status: DownloadStatus.downloading,
      progress: 0.0,
    );

    _currentTask = task;
    onProgress(task);

    final arguments = [
      '--newline',
      '--progress-template',
      'download:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s',
      // Allow yt-dlp to fetch the JS challenge solver (needed for YouTube
      // n-challenge / bot detection) and enable the local JS runtime.
      '--remote-components',
      'ejs:github',
      '-f',
      quality.formatSpecifier,
      if (quality.isAudioOnly) ...[
        '-x',
        '--audio-format',
        quality.extension,
      ] else ...[
        '--merge-output-format',
        'mp4',
      ],
      '-o',
      '$destinationDirectory/%(title)s.%(ext)s',
      '--no-playlist',
      task.url,
    ];

    final stderrBuffer = StringBuffer();

    try {
      final process = await _processService.start(
        executablePath,
        arguments,
      );
      _activeProcess = process;

      if (_cancelled) {
        process.kill(io.ProcessSignal.sigterm);
        _activeProcess = null;
        task.status = DownloadStatus.cancelled;
        onProgress(task);
        return;
      }

      // Handle standard output stream
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _parseStdoutLine(line, task);
        onProgress(task);
        if (onLog != null) {
          final clean = sanitizeLog(line);
          if (clean.isNotEmpty) onLog(clean);
        }
      });

      // Handle standard error stream
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderrBuffer.writeln(line);
      });

      final exitCode = await process.exitCode;
      _activeProcess = null;

      if (task.status == DownloadStatus.cancelled || _cancelled) {
        task.status = DownloadStatus.cancelled;
        onProgress(task);
        return;
      }

      if (exitCode == 0) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        task.eta = Duration.zero;
        onProgress(task);
      } else {
        task.status = DownloadStatus.failed;
        final error = stderrBuffer.toString().trim();
        task.errorMessage = error.isNotEmpty
            ? error
            : 'Download process exited with code $exitCode';
        onProgress(task);
      }
    } catch (e) {
      _activeProcess = null;
      if (task.status != DownloadStatus.cancelled && !_cancelled) {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        onProgress(task);
      }
    }
  }

  /// Cancels the current ongoing download process.
  Future<void> cancelCurrentDownload() async {
    _cancelled = true;
    final process = _activeProcess;
    final task = _currentTask;

    if (task != null) {
      task.status = DownloadStatus.cancelled;
      task.errorMessage = 'Download cancelled by user.';
    }

    if (process != null) {
      process.kill(io.ProcessSignal.sigterm);
      _activeProcess = null;
    }
  }

  void _parseStdoutLine(String line, DownloadTask task) {
    final trimmed = line.trim();

    // Handle raw progress lines from --newline / --progress-template.
    // Format: `0.0%| Unknown B/s|Unknown` (possibly with a leading `download:` key).
    if (trimmed.startsWith('download:')) {
      _parseProgressPayload(trimmed.substring(9), task);
      return;
    }

    // Raw form: `<percent>%|<speed>|<eta>` e.g. `17.7%|   2.07MiB/s|00:04`
    if (RegExp(r'^\d[\d\.]*%.*\|').hasMatch(trimmed)) {
      _parseProgressPayload(trimmed, task);
      return;
    }

    // Destination file output: `[download] Destination: /path/to/file.mp4`
    if (trimmed.startsWith('[download] Destination: ')) {
      task.destinationPath = trimmed.substring(24).trim();
    } else if (trimmed.startsWith('[Merger] Merging formats into "')) {
      // Merged file output: `[Merger] Merging formats into "/path/to/file.mp4"`
      final path = trimmed.substring(31).replaceAll('"', '').trim();
      task.destinationPath = path;
    } else if (trimmed.startsWith('[ExtractAudio] Destination: ')) {
      // Audio extracted output: `[ExtractAudio] Destination: /path/to/file.m4a`
      task.destinationPath = trimmed.substring(28).trim();
    } else if (trimmed.contains('has already been downloaded')) {
      task.progress = 1.0;
    }
  }

  void _parseProgressPayload(String payload, DownloadTask task) {
    final parts = payload.split('|');
    if (parts.isNotEmpty) {
      // Percent
      final percentStr = parts[0].replaceAll('%', '').trim();
      final parsedPercent = double.tryParse(percentStr);
      if (parsedPercent != null) {
        task.progress = (parsedPercent / 100.0).clamp(0.0, 1.0);
      }
    }

    // Speed & ETA
    if (parts.length >= 2) {
      final speedStr = parts[1].trim();
      if (speedStr != 'NA' && speedStr != 'Unknown B/s' && speedStr.isNotEmpty) {
        task.speed = _parseSpeedToBytes(speedStr);
      }
    }

    if (parts.length >= 3) {
      final etaStr = parts[2].trim();
      if (etaStr != 'NA' && etaStr != 'Unknown' && etaStr.isNotEmpty) {
        task.eta = _parseEtaDuration(etaStr);
      }
    }
  }

  double? _parseSpeedToBytes(String speedStr) {
    // Examples: "4.20MiB/s", "500KiB/s", "1.2GiB/s"
    final regex = RegExp(r'^([\d\.]+)\s*([A-Za-z]+)/s$');
    final match = regex.firstMatch(speedStr);
    if (match != null) {
      final value = double.tryParse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      if (value != null) {
        if (unit.startsWith('k')) return value * 1024;
        if (unit.startsWith('m')) return value * 1024 * 1024;
        if (unit.startsWith('g')) return value * 1024 * 1024 * 1024;
        return value;
      }
    }
    return null;
  }

  Duration? _parseEtaDuration(String etaStr) {
    // Formats: "00:35" (mm:ss) or "01:05:20" (hh:mm:ss)
    final parts = etaStr.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) {
        return Duration(minutes: m, seconds: s);
      }
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) {
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }
    return null;
  }

  /// Sanitizes output lines to remove internal engine and binary names.
  static String sanitizeLog(String raw) {
    return raw
        .replaceAll(RegExp(r'yt[-_]?dlp', caseSensitive: false), 'spidey_engine')
        .replaceAll(RegExp(r'\[youtube\]', caseSensitive: false), '[engine]')
        .trim();
  }
}
