import 'dart:convert';
import 'dart:io' as io;
import '../core/errors/app_exceptions.dart';
import '../core/utils/url_validator.dart';
import '../models/playlist_info.dart';
import '../models/video_info.dart';
import 'process_service.dart';

/// Service responsible for invoking `yt-dlp` and parsing media metadata.
class YtDlpService {
  final ProcessService _processService;
  final String? executableOverride;

  YtDlpService({
    ProcessService? processService,
    this.executableOverride,
  }) : _processService = processService ?? const SystemProcessService();

  /// Resolves the yt-dlp executable command/path.
  ///
  /// Can be overridden for production bundled binaries or custom setups.
  String get executablePath {
    final override = executableOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    // Default to PATH executable based on platform
    return io.Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
  }

  /// Checks whether a given URL is likely a playlist or multi-track album.
  bool isPlaylistUrl(String rawUrl) {
    final lower = rawUrl.toLowerCase().trim();
    return lower.contains('list=') ||
        lower.contains('/playlist') ||
        lower.contains('/sets/') ||
        lower.contains('/album/');
  }

  /// Rapidly extracts playlist metadata and tracklist using `--flat-playlist`.
  Future<PlaylistInfo> fetchPlaylistInfo(String rawUrl) async {
    final validatedUrl = UrlValidator.validate(rawUrl);

    final arguments = [
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      '--skip-download',
      validatedUrl,
    ];

    final result = await _processService.run(
      executablePath,
      arguments,
    );

    if (result.exitCode != 0) {
      final stderrText = result.stderr?.toString().trim() ?? '';
      final userMessage = _mapErrorMessage(stderrText);

      throw YtDlpException(
        userMessage,
        exitCode: result.exitCode,
        technicalDetails: stderrText.isNotEmpty ? stderrText : 'Exit code: ${result.exitCode}',
      );
    }

    final stdoutText = result.stdout?.toString().trim() ?? '';
    if (stdoutText.isEmpty) {
      throw const YtDlpException(
        'No metadata received from playlist service.',
        technicalDetails: 'Empty output returned by engine',
      );
    }

    try {
      final dynamic decoded = jsonDecode(stdoutText);
      if (decoded is! Map<String, dynamic>) {
        throw const YtDlpException(
          'Unexpected data format received from playlist service.',
          technicalDetails: 'Decoded JSON is not a Map<String, dynamic>',
        );
      }
      return PlaylistInfo.fromJson(decoded);
    } on FormatException catch (e) {
      throw YtDlpException(
        'Failed to interpret playlist information.',
        technicalDetails: 'JSON decode error: ${e.message}',
      );
    }
  }

  /// Extracts metadata for a given media URL.
  ///
  /// Validates the URL, executes `yt-dlp --dump-single-json`, and returns
  /// a strongly typed [VideoInfo] instance.
  ///
  /// Throws [InvalidUrlException] on malformed input or [YtDlpException]
  /// if yt-dlp fails.
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    final validatedUrl = UrlValidator.validate(rawUrl);

    final arguments = [
      '--dump-single-json',
      '--no-warnings',
      '--no-playlist',
      '--skip-download',
      validatedUrl,
    ];

    final result = await _processService.run(
      executablePath,
      arguments,
    );

    if (result.exitCode != 0) {
      final stderrText = result.stderr?.toString().trim() ?? '';
      final userMessage = _mapErrorMessage(stderrText);

      throw YtDlpException(
        userMessage,
        exitCode: result.exitCode,
        technicalDetails: stderrText.isNotEmpty ? stderrText : 'Exit code: ${result.exitCode}',
      );
    }

    final stdoutText = result.stdout?.toString().trim() ?? '';
    if (stdoutText.isEmpty) {
      throw const YtDlpException(
        'No metadata received from video service.',
        technicalDetails: 'Empty output returned by engine',
      );
    }

    try {
      final dynamic decoded = jsonDecode(stdoutText);
      if (decoded is! Map<String, dynamic>) {
        throw const YtDlpException(
          'Unexpected data format received from video service.',
          technicalDetails: 'Decoded JSON is not a Map<String, dynamic>',
        );
      }
      return VideoInfo.fromJson(decoded);
    } on FormatException catch (e) {
      throw YtDlpException(
        'Failed to interpret video information.',
        technicalDetails: 'JSON decode error: ${e.message}',
      );
    }
  }

  /// Maps yt-dlp stderr output into user-friendly error messages.
  String _mapErrorMessage(String stderr) {
    final lower = stderr.toLowerCase();

    if (lower.contains('name or service not known') ||
        lower.contains('getaddrinfo failed') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('timed out')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    if (lower.contains('unsupported url') || lower.contains('is not a valid url')) {
      return 'This URL is not supported. Please check the address and try again.';
    }

    if (lower.contains('private video') || lower.contains('this video is private')) {
      return 'This video is private and cannot be accessed.';
    }

    if (lower.contains('video unavailable') || lower.contains('this video is not available')) {
      return 'This video is unavailable or has been removed.';
    }

    if (lower.contains('sign in to confirm your age') ||
        lower.contains('age-restricted') ||
        lower.contains('requires authentication')) {
      return 'This video is age-restricted or requires login.';
    }

    if (lower.contains('http error 404')) {
      return 'The requested video was not found (404).';
    }

    return 'Unable to retrieve video information. Please check the URL and try again.';
  }
}
