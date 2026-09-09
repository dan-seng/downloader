import 'dart:async';
import 'dart:io' as io;
import 'process_service.dart';

/// Indicates the resolution origin of the yt-dlp executable.
enum EngineBinarySource {
  /// Installed/updated in user space (~/.spidey_dlx/bin/yt-dlp). Has highest priority.
  userBin,

  /// Bundled with the application package (e.g., inside AppImage or release bundle).
  bundled,

  /// Installed system-wide and discovered via system PATH.
  systemPath,

  /// Not found in any location.
  missing,
}

/// Snapshot of the media extraction engines on the host system.
class EngineInfo {
  final String? ytdlpPath;
  final String? ytdlpVersion;
  final EngineBinarySource ytdlpSource;
  final bool ffmpegAvailable;
  final String? ffmpegVersion;

  const EngineInfo({
    this.ytdlpPath,
    this.ytdlpVersion,
    required this.ytdlpSource,
    required this.ffmpegAvailable,
    this.ffmpegVersion,
  });

  bool get isYtdlpReady => ytdlpSource != EngineBinarySource.missing && ytdlpPath != null;

  String get sourceLabel {
    switch (ytdlpSource) {
      case EngineBinarySource.userBin:
        return 'USER VAULT (~/.spidey_dlx/bin)';
      case EngineBinarySource.bundled:
        return 'APP BUNDLE';
      case EngineBinarySource.systemPath:
        return 'SYSTEM PATH';
      case EngineBinarySource.missing:
        return 'NOT FOUND';
    }
  }

  @override
  String toString() =>
      'EngineInfo(ytdlp: $ytdlpVersion via $ytdlpSource ($ytdlpPath), ffmpeg: $ffmpegAvailable ($ffmpegVersion))';
}

/// Signature for custom binary downloaders to allow dependency injection during testing.
typedef BinaryDownloader = Future<void> Function(
  Uri uri,
  io.File destination, {
  void Function(double progress, String status)? onProgress,
});

/// Service responsible for discovering, validating, and updating yt-dlp and FFmpeg binaries.
class EngineService {
  final ProcessService _processService;
  final String? customHomeDir;
  final String? customBundleDir;
  final BinaryDownloader? binaryDownloader;

  EngineInfo? _cachedEngineInfo;
  EngineInfo? get cachedEngineInfo => _cachedEngineInfo;

  EngineService({
    ProcessService? processService,
    this.customHomeDir,
    this.customBundleDir,
    this.binaryDownloader,
  }) : _processService = processService ?? const SystemProcessService();

  /// Returns the executable name appropriate for the host OS.
  String get exeName {
    if (io.Platform.isWindows) return 'yt-dlp.exe';
    return 'yt-dlp';
  }

  /// Resolves the user-writable binary directory (~/.spidey_dlx/bin).
  String getUserBinDirectory() {
    if (customHomeDir != null && customHomeDir!.isNotEmpty) {
      return '$customHomeDir/.spidey_dlx/bin';
    }
    final home = io.Platform.environment['HOME'] ??
        io.Platform.environment['USERPROFILE'] ??
        io.Directory.current.path;
    return '$home/.spidey_dlx/bin';
  }

  /// Full path to the user-space yt-dlp binary.
  String getUserYtDlpPath() {
    return '${getUserBinDirectory()}/$exeName';
  }

  /// Candidate paths for bundled binaries next to the running executable.
  List<String> getBundledCandidates() {
    final bundleDir = customBundleDir ??
        (io.Platform.resolvedExecutable.isNotEmpty
            ? io.File(io.Platform.resolvedExecutable).parent.path
            : null);

    if (bundleDir == null || bundleDir.isEmpty) return const [];
    return [
      '$bundleDir/data/bin/$exeName',
      '$bundleDir/bin/$exeName',
      '$bundleDir/$exeName',
    ];
  }

  /// Performs a complete discovery scan across the hybrid hierarchy:
  /// 1. User Vault (~/.spidey_dlx/bin/yt-dlp)
  /// 2. Application Bundle candidates
  /// 3. System PATH
  Future<EngineInfo> checkEngine() async {
    String? resolvedPath;
    String? resolvedVersion;
    EngineBinarySource resolvedSource = EngineBinarySource.missing;

    // 1. Check User Bin Vault
    final userPath = getUserYtDlpPath();
    if (io.File(userPath).existsSync()) {
      final version = await _testExecutable(userPath);
      if (version != null) {
        resolvedPath = userPath;
        resolvedVersion = version;
        resolvedSource = EngineBinarySource.userBin;
      }
    }

    // 2. Check App Bundle
    if (resolvedSource == EngineBinarySource.missing) {
      for (final candidate in getBundledCandidates()) {
        if (io.File(candidate).existsSync()) {
          final version = await _testExecutable(candidate);
          if (version != null) {
            resolvedPath = candidate;
            resolvedVersion = version;
            resolvedSource = EngineBinarySource.bundled;
            break;
          }
        }
      }
    }

    // 3. Check System PATH
    if (resolvedSource == EngineBinarySource.missing) {
      final version = await _testExecutable(exeName);
      if (version != null) {
        resolvedPath = exeName;
        resolvedVersion = version;
        resolvedSource = EngineBinarySource.systemPath;
      }
    }

    // Check FFmpeg
    final ffmpegInfo = await _checkFFmpeg();

    final info = EngineInfo(
      ytdlpPath: resolvedPath,
      ytdlpVersion: resolvedVersion,
      ytdlpSource: resolvedSource,
      ffmpegAvailable: ffmpegInfo.$1,
      ffmpegVersion: ffmpegInfo.$2,
    );

    _cachedEngineInfo = info;
    return info;
  }

  /// Executes `--version` on the binary candidate to verify execution and retrieve version.
  Future<String?> _testExecutable(String executable) async {
    try {
      final result = await _processService.run(executable, ['--version']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim();
        if (version.isNotEmpty) {
          return version;
        }
      }
    } catch (_) {
      // Ignored: executable missing or not executable
    }
    return null;
  }

  /// Checks if FFmpeg is available on the system.
  Future<(bool, String?)> _checkFFmpeg() async {
    final ffmpegExe = io.Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    try {
      final result = await _processService.run(ffmpegExe, ['-version']);
      if (result.exitCode == 0) {
        final out = result.stdout.toString();
        final firstLine = out.split('\n').firstWhere(
              (line) => line.toLowerCase().contains('ffmpeg version'),
              orElse: () => out.split('\n').first,
            );
        return (true, firstLine.trim());
      }
    } catch (_) {
      // FFmpeg not found
    }
    return (false, null);
  }

  /// Resolves the official standalone GitHub release URL for the host OS.
  Uri getReleaseDownloadUri() {
    if (io.Platform.isWindows) {
      return Uri.parse('https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe');
    } else if (io.Platform.isMacOS) {
      return Uri.parse('https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos');
    } else {
      return Uri.parse('https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp');
    }
  }

  /// Downloads the latest standalone yt-dlp binary from GitHub releases into
  /// the user bin vault (~/.spidey_dlx/bin/yt-dlp) and sets executable permissions.
  Future<EngineInfo> downloadOrUpdateYtDlp({
    void Function(double progress, String status)? onProgress,
  }) async {
    final targetPath = getUserYtDlpPath();
    final targetFile = io.File(targetPath);
    final targetDir = targetFile.parent;

    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final downloadUri = getReleaseDownloadUri();
    onProgress?.call(0.05, 'Connecting to GitHub releases...');

    final downloader = binaryDownloader ?? _defaultDownloader;
    await downloader(downloadUri, targetFile, onProgress: onProgress);

    // Apply executable permissions on non-Windows platforms
    if (!io.Platform.isWindows) {
      onProgress?.call(0.95, 'Setting executable permissions (chmod +x)...');
      try {
        await _processService.run('chmod', ['+x', targetPath]);
      } catch (_) {
        // Fallback or ignore
      }
    }

    onProgress?.call(1.0, 'Verifying engine installation...');
    final newInfo = await checkEngine();
    return newInfo;
  }

  /// Default production implementation of the binary downloader using dart:io HttpClient.
  static Future<void> _defaultDownloader(
    Uri uri,
    io.File destination, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final client = io.HttpClient();
    client.autoUncompress = true;

    try {
      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close();
      if (response.statusCode != io.HttpStatus.ok) {
        throw io.HttpException(
          'Engine download failed with HTTP status ${response.statusCode}',
          uri: uri,
        );
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;

      final tmpFile = io.File('${destination.path}.tmp');
      if (tmpFile.existsSync()) {
        try {
          tmpFile.deleteSync();
        } catch (_) {}
      }

      final sink = tmpFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          final ratio = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(ratio, 'Downloading engine (${(ratio * 100).toStringAsFixed(0)}%)...');
        }
      }

      await sink.flush();
      await sink.close();

      if (destination.existsSync()) {
        try {
          destination.deleteSync();
        } catch (_) {}
      }

      tmpFile.renameSync(destination.path);
    } finally {
      client.close();
    }
  }
}
