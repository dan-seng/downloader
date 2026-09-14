import 'dart:convert';
import 'dart:io' as io;
import '../core/network/mobile_youtube_client.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/url_validator.dart';
import '../models/playlist_info.dart';
import '../models/video_format.dart';
import '../models/video_info.dart';
import 'engine_service.dart';
import 'process_service.dart';

/// Service responsible for invoking `yt-dlp` and parsing media metadata.
class YtDlpService {
  final ProcessService _processService;
  final String? executableOverride;
  final EngineService? engineService;

  YtDlpService({
    ProcessService? processService,
    this.executableOverride,
    this.engineService,
  }) : _processService = processService ?? const SystemProcessService();

  /// Resolves the yt-dlp executable command/path.
  ///
  /// Priority: explicit override -> engineService cached path -> OS default.
  String get executablePath {
    final override = executableOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final resolved = engineService?.cachedEngineInfo?.ytdlpPath;
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
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

    if (io.Platform.isAndroid) {
      return await _fetchPlaylistFromExplode(validatedUrl);
    }

    final ffmpegDir = engineService?.getFfmpegDirectory();
    final arguments = [
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      '--skip-download',
      if (ffmpegDir != null && ffmpegDir.isNotEmpty) ...[
        '--ffmpeg-location',
        ffmpegDir,
      ],
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

    if (io.Platform.isAndroid) {
      return await _fetchVideoFromExplode(validatedUrl);
    }

    final ffmpegDir = engineService?.getFfmpegDirectory();
    final arguments = [
      '--dump-single-json',
      '--no-warnings',
      '--no-playlist',
      '--skip-download',
      if (ffmpegDir != null && ffmpegDir.isNotEmpty) ...[
        '--ffmpeg-location',
        ffmpegDir,
      ],
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

  /// Extracts playlist metadata using the pure Dart youtube_explode_dart engine on Android.
  Future<PlaylistInfo> _fetchPlaylistFromExplode(String url) async {
    final yt = createMobileYoutubeExplode();
    try {
      final playlist = await yt.playlists.get(url);
      final items = <PlaylistItem>[];
      await for (final vid in yt.playlists.getVideos(playlist.id)) {
        items.add(PlaylistItem(
          id: vid.id.value,
          title: vid.title,
          url: vid.url,
          duration: vid.duration,
          uploader: vid.author,
          thumbnail: vid.thumbnails.highResUrl,
        ));
      }
      return PlaylistInfo(
        id: playlist.id.value,
        title: playlist.title,
        uploader: playlist.author,
        webpageUrl: playlist.url,
        items: items,
      );
    } catch (e) {
      throw YtDlpException(
        'Failed to interpret playlist: $e',
        technicalDetails: e.toString(),
      );
    } finally {
      yt.close();
    }
  }

  /// Extracts video metadata using the pure Dart youtube_explode_dart engine on Android.
  Future<VideoInfo> _fetchVideoFromExplode(String url) async {
    final yt = createMobileYoutubeExplode();
    try {
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);

      final formats = <VideoFormat>[];

      // 1. Muxed streams (both video + audio ready to play without external ffmpeg)
      for (final stream in manifest.muxed) {
        final height = stream.videoResolution.height;
        final width = stream.videoResolution.width;
        formats.add(VideoFormat(
          formatId: stream.tag.toString(),
          extension: stream.container.name,
          width: width,
          height: height,
          resolution: '${height}p',
          fileSize: stream.size.totalBytes,
          videoCodec: stream.videoCodec,
          audioCodec: stream.audioCodec,
          fps: stream.framerate.framesPerSecond.toDouble(),
          tbr: stream.bitrate.bitsPerSecond / 1000.0,
          formatNote: '${height}p (Video+Audio)',
        ));
      }

      // 2. High-res video-only streams (1080p, 1440p, 2160p 4K)
      for (final stream in manifest.videoOnly) {
        final height = stream.videoResolution.height;
        final width = stream.videoResolution.width;
        formats.add(VideoFormat(
          formatId: stream.tag.toString(),
          extension: stream.container.name,
          width: width,
          height: height,
          resolution: '${height}p',
          fileSize: stream.size.totalBytes,
          videoCodec: stream.videoCodec,
          audioCodec: 'none',
          fps: stream.framerate.framesPerSecond.toDouble(),
          tbr: stream.bitrate.bitsPerSecond / 1000.0,
          formatNote: '${height}p (${stream.videoCodec})',
        ));
      }

      // 3. Audio-only streams
      for (final stream in manifest.audioOnly) {
        formats.add(VideoFormat(
          formatId: stream.tag.toString(),
          extension: stream.container.name,
          resolution: 'Audio only',
          fileSize: stream.size.totalBytes,
          videoCodec: 'none',
          audioCodec: stream.audioCodec,
          tbr: stream.bitrate.bitsPerSecond / 1000.0,
          formatNote: '${stream.audioCodec} (${(stream.bitrate.bitsPerSecond / 1000).round()} kbps)',
        ));
      }

      return VideoInfo(
        id: video.id.value,
        title: video.title,
        thumbnail: video.thumbnails.highResUrl,
        duration: video.duration,
        uploader: video.author,
        formats: formats,
        webpageUrl: video.url,
        description: video.description,
      );
    } catch (e) {
      throw YtDlpException(
        'Failed to fetch video details: $e',
        technicalDetails: e.toString(),
      );
    } finally {
      yt.close();
    }
  }
}
