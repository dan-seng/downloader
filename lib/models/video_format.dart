import '../core/utils/formatters.dart';

/// Represents a single media stream/format provided by yt-dlp.
class VideoFormat {
  final String formatId;
  final String? extension;
  final int? width;
  final int? height;
  final double? fps;
  final String? videoCodec;
  final String? audioCodec;
  final int? fileSize;
  final String? formatNote;
  final String? resolution;
  final double? tbr;

  const VideoFormat({
    required this.formatId,
    this.extension,
    this.width,
    this.height,
    this.fps,
    this.videoCodec,
    this.audioCodec,
    this.fileSize,
    this.formatNote,
    this.resolution,
    this.tbr,
  });

  /// Factory constructor to parse yt-dlp format JSON with resilient type conversion.
  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    // Parse formatId safely
    final formatId = json['format_id']?.toString() ?? '';

    // File size can be given as 'filesize' or 'filesize_approx'
    final rawSize = json['filesize'] ?? json['filesize_approx'];
    int? fileSize;
    if (rawSize is num) {
      fileSize = rawSize.toInt();
    }

    // Width & Height
    final width = (json['width'] is num) ? (json['width'] as num).toInt() : null;
    final height = (json['height'] is num) ? (json['height'] as num).toInt() : null;

    // FPS
    final fps = (json['fps'] is num) ? (json['fps'] as num).toDouble() : null;

    // Total Bitrate
    final tbr = (json['tbr'] is num) ? (json['tbr'] as num).toDouble() : null;

    return VideoFormat(
      formatId: formatId,
      extension: json['ext'] as String?,
      width: width,
      height: height,
      fps: fps,
      videoCodec: json['vcodec'] as String?,
      audioCodec: json['acodec'] as String?,
      fileSize: fileSize,
      formatNote: json['format_note'] as String?,
      resolution: json['resolution'] as String?,
      tbr: tbr,
    );
  }

  /// Whether this format contains a video track.
  bool get hasVideo => videoCodec != null && videoCodec != 'none';

  /// Whether this format contains an audio track.
  bool get hasAudio => audioCodec != null && audioCodec != 'none';

  /// Whether this stream is video-only (no audio).
  bool get isVideoOnly => hasVideo && !hasAudio;

  /// Whether this stream is audio-only (no video).
  bool get isAudioOnly => hasAudio && !hasVideo;

  /// Whether this format contains both video and audio tracks.
  bool get isCombined => hasVideo && hasAudio;

  /// Human-readable resolution label (e.g. "1080p", "720p", or "Audio only").
  String get resolutionLabel {
    if (height != null && height! > 0) {
      return '${height}p';
    }
    if (resolution != null && resolution!.isNotEmpty && resolution != 'none') {
      return resolution!;
    }
    if (isAudioOnly) {
      return 'Audio only';
    }
    return 'Unknown resolution';
  }

  /// Formatted file size string.
  String get formattedFileSize => Formatters.formatBytes(fileSize);

  @override
  String toString() =>
      'VideoFormat(id: $formatId, ext: $extension, res: $resolutionLabel, vcodec: $videoCodec, acodec: $audioCodec, size: $formattedFileSize)';
}
