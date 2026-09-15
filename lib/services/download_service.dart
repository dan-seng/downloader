import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import '../core/network/mobile_youtube_client.dart';
import 'storage_service.dart';

import '../core/errors/app_exceptions.dart';
import '../models/audio_config.dart';
import '../models/download_task.dart';
import '../models/quality_option.dart';
import '../models/speed_limit.dart';
import '../models/time_range_clip.dart';
import '../models/video_info.dart';
import 'engine_service.dart';
import 'process_service.dart';

extension _IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

typedef DownloadProgressCallback = void Function(DownloadTask task);
typedef DownloadLogCallback = void Function(String line);

/// Service responsible for managing real-time video downloading,
/// progress parsing, and process lifecycle cancellation.
class DownloadService {
  final ProcessService _processService;
  final String? executableOverride;
  final EngineService? engineService;

  io.Process? _activeProcess;
  http.Client? _activeHttpClient;
  yt_exp.YoutubeExplode? _activeMobileYt;
  DownloadTask? _currentTask;
  bool _cancelled = false;

  DownloadService({
    ProcessService? processService,
    this.executableOverride,
    this.engineService,
  }) : _processService = processService ?? const SystemProcessService();

  String get executablePath {
    final override = executableOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final resolved = engineService?.cachedEngineInfo?.ytdlpPath;
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
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
    AudioConfig? audioConfig,
    SpeedLimit? speedLimit,
    TimeRangeClip? clip,
  }) async {
    if (isDownloading) {
      throw const ProcessExecutionException('A download is already in progress.');
    }

    _cancelled = false;

    final task = DownloadTask(
      id: video.id,
      url: (video.webpageUrl != null && video.webpageUrl!.isNotEmpty)
          ? video.webpageUrl!
          : video.id,
      title: video.title,
      destinationPath: destinationDirectory,
      formatId: quality.id,
      status: DownloadStatus.downloading,
      progress: 0.0,
    );

    _currentTask = task;
    onProgress(task);

    if (io.Platform.isAndroid) {
      await _startAndroidDownload(
        video: video,
        quality: quality,
        destinationDirectory: destinationDirectory,
        onProgress: onProgress,
        onLog: onLog,
        audioConfig: audioConfig,
      );
      return;
    }

    final ffmpegDir = engineService?.getFfmpegDirectory();

    final arguments = [
      '--newline',
      '--progress-template',
      'download:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress.downloaded_bytes)s|%(progress.total_bytes)s',
      if (ffmpegDir != null && ffmpegDir.isNotEmpty) ...[
        '--ffmpeg-location',
        ffmpegDir,
      ],
      // Allow yt-dlp to fetch the JS challenge solver (needed for YouTube
      // n-challenge / bot detection) and enable the local JS runtime.
      '--remote-components',
      'ejs:github',
      '-f',
      quality.formatSpecifier,
      if (speedLimit != null && speedLimit.rateFlag != null) ...[
        '--limit-rate',
        speedLimit.rateFlag!,
      ],
      if (clip != null && clip.isEnabled) ...[
        '--download-sections',
        clip.toSectionArgument(),
        '--force-keyframes-at-cuts',
      ],
      if (quality.isAudioOnly) ...[
        '-x',
        '--audio-format',
        audioConfig?.format.id ?? quality.extension,
        if (audioConfig != null) ...[
          '--audio-quality',
          audioConfig.bitrate.qualityFlag,
          if (audioConfig.embedThumbnail) ...[
            '--embed-thumbnail',
            '--convert-thumbnails',
            'jpg',
          ],
          if (audioConfig.embedMetadata) '--add-metadata',
        ],
      ] else ...[
        '--merge-output-format',
        'mp4',
        if (audioConfig?.embedMetadata == true) '--add-metadata',
      ],
      '-o',
      '$destinationDirectory/%(title)s.%(ext)s',
      '--no-playlist',
      task.url,
    ];

    final stderrBuffer = StringBuffer();

    if (clip != null && clip.isEnabled) {
      onLog?.call('spidey-trim: slicing section ${clip.toSectionArgument()} with keyframe precision');
    }

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

    try {
      _activeHttpClient?.close();
    } catch (_) {}
    _activeHttpClient = null;

    try {
      _activeMobileYt?.close();
    } catch (_) {}
    _activeMobileYt = null;
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

    if (parts.length >= 4) {
      final downloadedStr = parts[3].trim();
      if (downloadedStr != 'NA' && downloadedStr.isNotEmpty) {
        task.transferredBytes = int.tryParse(downloadedStr);
      }
    }

    if (parts.length >= 5) {
      final totalStr = parts[4].trim();
      if (totalStr != 'NA' && totalStr.isNotEmpty) {
        task.totalBytes = int.tryParse(totalStr);
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

  /// Downloads video/audio directly on Android using the resilient chunked stream engine.
  Future<void> _startAndroidDownload({
    required VideoInfo video,
    required QualityOption quality,
    required String destinationDirectory,
    required DownloadProgressCallback onProgress,
    DownloadLogCallback? onLog,
    AudioConfig? audioConfig,
  }) async {
    final yt = createMobileYoutubeExplode();
    _activeMobileYt = yt;

    try {
      onLog?.call('\$ vinx-native-download --id ${video.id}');
      onLog?.call('[Engine] Initializing mobile stream pipeline...');

      final manifest = await yt.videos.streamsClient
          .getManifest(video.id)
          .timeout(const Duration(seconds: 25));

      yt_exp.StreamInfo? targetStream;
      String fileExt = 'mp4';

      if (quality.isAudioOnly) {
        final matchAudio = manifest.audioOnly.firstWhereOrNull((s) => s.tag.toString() == quality.id);
        targetStream = matchAudio ?? manifest.audioOnly.withHighestBitrate();
        fileExt = targetStream.container.name;
        if (fileExt == 'mp4') fileExt = 'm4a';
      } else {
        // Video mode: first prefer muxed streams (video + audio in one container)
        final targetHeight = quality.height;
        if (targetHeight != null) {
          targetStream = manifest.muxed.firstWhereOrNull(
            (s) => s.videoResolution.height == targetHeight,
          );
        }
        targetStream ??= manifest.muxed.firstWhereOrNull((s) => s.tag.toString() == quality.id);
        // If not exact match, prefer highest muxed stream so the video has sound
        targetStream ??= manifest.muxed.isNotEmpty ? manifest.muxed.withHighestBitrate() : null;
        // Fallback to video-only if no muxed stream exists
        targetStream ??= manifest.videoOnly.firstWhereOrNull((s) => s.tag.toString() == quality.id) ??
            (manifest.videoOnly.isNotEmpty ? manifest.videoOnly.withHighestBitrate() : null);

        if (targetStream != null) {
          fileExt = targetStream.container.name;
        }
      }

      if (targetStream == null) {
        throw const ProcessExecutionException('No compatible stream found for this video.');
      }

      // Ensure destination directory is accessible and writable on Android
      var activeDirectory = destinationDirectory;
      var destDir = io.Directory(activeDirectory);
      try {
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }
        final probe = io.File('${destDir.path}/.write_test');
        await probe.writeAsString('ok');
        await probe.delete();
      } catch (e) {
        onLog?.call('[Storage] Storage access restricted; resolving fallback directory...');
        activeDirectory = await const StorageService().getDefaultDownloadsDirectory();
        destDir = io.Directory(activeDirectory);
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }
      }

      final sanitizedTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final targetFile = io.File('$activeDirectory/$sanitizedTitle.$fileExt');

      onLog?.call('[Engine] Destination: ${targetFile.path}');
      final totalBytes = targetStream.size.totalBytes;
      if (totalBytes > 0) {
        onLog?.call('[Engine] Stream size: ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB (${targetStream.container.name})');
      }

      var receivedBytes = 0;
      final startTime = DateTime.now();
      var lastEmitTime = DateTime.fromMillisecondsSinceEpoch(0);
      var lastWindowBytes = 0;
      var lastWindowTime = DateTime.now();

      final task = _currentTask;
      if (task != null) {
        task.transferredBytes = 0;
        task.totalBytes = totalBytes > 0 ? totalBytes : null;
        task.destinationPath = targetFile.path;
        onProgress(task);
      }

      final output = targetFile.openWrite();
      final httpClient = http.Client();
      _activeHttpClient = httpClient;

      try {
        if (targetStream.fragments.isEmpty && totalBytes > 0) {
          // Discrete 2 MB HTTP Range chunks
          const chunkSize = 2 * 1024 * 1024;
          while (!_cancelled && receivedBytes < totalBytes) {
            final endByte = (receivedBytes + chunkSize - 1).clamp(0, totalBytes - 1);

            var attempt = 0;
            var success = false;
            Object? lastError;

            while (!_cancelled && attempt < 3 && !success) {
              attempt++;
              try {
                final req = http.Request('GET', targetStream.url);
                req.headers['Range'] = 'bytes=$receivedBytes-$endByte';
                req.headers['User-Agent'] =
                    'com.google.android.youtube/19.29.37 (Linux; U; Android 11)';

                final streamedRes = await httpClient
                    .send(req)
                    .timeout(const Duration(seconds: 20));

                if (streamedRes.statusCode != 200 && streamedRes.statusCode != 206) {
                  throw ProcessExecutionException(
                    'Server returned HTTP ${streamedRes.statusCode} for chunk bytes $receivedBytes-$endByte',
                  );
                }

                await for (final byteChunk in streamedRes.stream.timeout(const Duration(seconds: 20))) {
                  if (_cancelled) break;
                  output.add(byteChunk);
                  receivedBytes += byteChunk.length;

                  final now = DateTime.now();
                  final timeSinceLastEmit = now.difference(lastEmitTime).inMilliseconds;

                  if (timeSinceLastEmit >= 100 || receivedBytes >= totalBytes) {
                    lastEmitTime = now;

                    final windowElapsed = now.difference(lastWindowTime).inMilliseconds / 1000.0;
                    double currentSpeed = 0.0;
                    if (windowElapsed >= 0.8) {
                      currentSpeed = (receivedBytes - lastWindowBytes) / windowElapsed;
                      lastWindowBytes = receivedBytes;
                      lastWindowTime = now;
                    } else {
                      final lifetimeElapsed = now.difference(startTime).inMilliseconds / 1000.0;
                      currentSpeed = lifetimeElapsed > 0 ? (receivedBytes / lifetimeElapsed) : 0.0;
                    }

                    final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
                    final remainingBytes = totalBytes - receivedBytes;
                    Duration? eta;
                    if (currentSpeed > 0 && remainingBytes > 0) {
                      eta = Duration(seconds: (remainingBytes / currentSpeed).round());
                    }

                    if (task != null && !_cancelled) {
                      task.transferredBytes = receivedBytes;
                      task.totalBytes = totalBytes;
                      task.progress = progress;
                      task.speed = currentSpeed;
                      task.eta = eta;
                      task.destinationPath = targetFile.path;
                      onProgress(task);
                    }
                  }
                }
                success = true;
              } catch (err) {
                if (_cancelled) break;
                lastError = err;
                if (attempt < 3) {
                  onLog?.call('[Network] Retrying chunk transfer ($attempt/3)...');
                  await Future.delayed(const Duration(milliseconds: 1000));
                }
              }
            }

            if (!success && !_cancelled) {
              throw ProcessExecutionException(
                'Failed to download media chunk after 3 attempts: ${lastError ?? "Connection timed out"}',
              );
            }
          }
        } else {
          // Fallback stream for HLS or indeterminate streams
          final stream = yt.videos.streamsClient.get(targetStream);
          await for (final chunk in stream.timeout(const Duration(seconds: 25))) {
            if (_cancelled) break;
            output.add(chunk);
            receivedBytes += chunk.length;

            final now = DateTime.now();
            final timeSinceLastEmit = now.difference(lastEmitTime).inMilliseconds;
            if (timeSinceLastEmit >= 100) {
              lastEmitTime = now;
              final elapsedSeconds = now.difference(startTime).inMilliseconds / 1000.0;
              final speedBytesPerSec = elapsedSeconds > 0 ? (receivedBytes / elapsedSeconds) : 0.0;
              final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

              if (task != null && !_cancelled) {
                task.transferredBytes = receivedBytes;
                task.totalBytes = totalBytes > 0 ? totalBytes : null;
                task.progress = progress;
                task.speed = speedBytesPerSec;
                task.destinationPath = targetFile.path;
                onProgress(task);
              }
            }
          }
        }
      } finally {
        await output.flush();
        await output.close();
        httpClient.close();
        _activeHttpClient = null;
      }

      if (_cancelled) {
        if (await targetFile.exists()) await targetFile.delete();
        if (task != null) {
          task.status = DownloadStatus.cancelled;
          task.progress = 0.0;
          task.errorMessage = 'Download cancelled by user.';
          onProgress(task);
        }
        onLog?.call('[Engine] Download cancelled.');
        return;
      }

      if (task != null) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        task.transferredBytes = totalBytes > 0 ? totalBytes : receivedBytes;
        task.totalBytes = totalBytes > 0 ? totalBytes : receivedBytes;
        task.speed = 0.0;
        task.eta = Duration.zero;
        task.destinationPath = targetFile.path;
        onProgress(task);
      }
      onLog?.call('[Engine] Download successfully finished!');

      // Register file in Android MediaStore so it appears in Gallery & Files app
      if (io.Platform.isAndroid) {
        await const StorageService().scanMediaFile(targetFile.path);
        onLog?.call('[Storage] File indexed into Android MediaStore.');
      }
    } catch (e) {
      if (_cancelled) return;
      final task = _currentTask;
      if (task != null) {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        onProgress(task);
      }
      onLog?.call('[Error] $e');
      rethrow;
    } finally {
      yt.close();
      _activeMobileYt = null;
      _activeProcess = null;
    }
  }
}
