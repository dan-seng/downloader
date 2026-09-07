import '../core/utils/formatters.dart';
import 'video_format.dart';

/// Strongly typed model representing parsed video metadata from yt-dlp.
class VideoInfo {
  final String id;
  final String title;
  final String? thumbnail;
  final Duration? duration;
  final String? uploader;
  final List<VideoFormat> formats;
  final String? webpageUrl;
  final String? description;

  const VideoInfo({
    required this.id,
    required this.title,
    this.thumbnail,
    this.duration,
    this.uploader,
    required this.formats,
    this.webpageUrl,
    this.description,
  });

  /// Resiliently parses yt-dlp's `--dump-single-json` output.
  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    // Parse duration (yt-dlp provides duration in seconds)
    Duration? duration;
    final rawDuration = json['duration'];
    if (rawDuration is num && rawDuration > 0) {
      duration = Duration(seconds: rawDuration.toInt());
    }

    // Parse formats list
    final rawFormats = json['formats'];
    final formats = <VideoFormat>[];
    if (rawFormats is List) {
      for (final item in rawFormats) {
        if (item is Map<String, dynamic>) {
          formats.add(VideoFormat.fromJson(item));
        } else if (item is Map) {
          formats.add(VideoFormat.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Thumbnail selection: yt-dlp provides 'thumbnail' string or 'thumbnails' array
    String? thumbnail = json['thumbnail'] as String?;
    if (thumbnail == null || thumbnail.isEmpty) {
      final thumbnailsList = json['thumbnails'];
      if (thumbnailsList is List && thumbnailsList.isNotEmpty) {
        final lastThumbnail = thumbnailsList.last;
        if (lastThumbnail is Map && lastThumbnail['url'] is String) {
          thumbnail = lastThumbnail['url'] as String;
        }
      }
    }

    return VideoInfo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Video',
      thumbnail: thumbnail,
      duration: duration,
      uploader: json['uploader'] as String? ?? json['channel'] as String?,
      formats: formats,
      webpageUrl: json['webpage_url'] as String? ?? json['original_url'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Human-readable duration (e.g. "12:42").
  String get formattedDuration => Formatters.formatDuration(duration);

  /// Formats containing a video stream.
  List<VideoFormat> get videoFormats => formats.where((f) => f.hasVideo).toList();

  /// Formats containing an audio stream.
  List<VideoFormat> get audioFormats => formats.where((f) => f.hasAudio).toList();

  @override
  String toString() =>
      'VideoInfo(id: $id, title: $title, uploader: $uploader, duration: $formattedDuration, formats: ${formats.length})';
}
