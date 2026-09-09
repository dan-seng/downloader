import '../core/utils/formatters.dart';
import 'video_format.dart';
import 'video_info.dart';

/// Represents a simplified, user-friendly download quality and format option.
class QualityOption {
  final String id;
  final String label;
  final String extension;
  final int? height;
  final bool isAudioOnly;
  final String formatSpecifier;
  final int? estimatedBytes;

  const QualityOption({
    required this.id,
    required this.label,
    required this.extension,
    this.height,
    this.isAudioOnly = false,
    required this.formatSpecifier,
    this.estimatedBytes,
  });

  String get formattedSize =>
      estimatedBytes != null ? Formatters.formatBytes(estimatedBytes) : '';

  /// Derives user-friendly quality choices from a [VideoInfo] payload.
  static List<QualityOption> fromVideoInfo(VideoInfo videoInfo) {
    final options = <QualityOption>[];

    // Collect available video heights
    final heights = <int>{};
    for (final f in videoInfo.formats) {
      if (f.height != null && f.height! > 0) {
        heights.add(f.height!);
      }
    }

    final sortedHeights = heights.toList()..sort((a, b) => b.compareTo(a));

    // Helper to calculate estimated bytes for a resolution
    int? getEstimatedBytes(int targetHeight) {
      final vFormat = videoInfo.formats.cast<VideoFormat?>().firstWhere(
        (f) =>
            f != null &&
            f.hasVideo &&
            (f.height == targetHeight ||
                (f.height != null &&
                    (f.height! - targetHeight).abs() <= 16)),
        orElse: () => null,
      );
      final aFormat = videoInfo.formats.cast<VideoFormat?>().firstWhere(
        (f) =>
            f != null &&
            f.isAudioOnly &&
            f.fileSize != null &&
            f.fileSize! > 0,
        orElse: () => null,
      );

      final vSize = vFormat?.fileSize;
      final aSize = aFormat?.fileSize;
      if (vSize != null && aSize != null) {
        return vSize + aSize;
      } else if (vSize != null) {
        return vSize;
      }
      return null;
    }

    final maxHeight = sortedHeights.isNotEmpty ? sortedHeights.first : null;
    final bestEstimatedBytes =
        maxHeight != null ? getEstimatedBytes(maxHeight) : null;
    final bestLabel = maxHeight != null
        ? 'Best Quality (${maxHeight}p)'
        : 'Best Available Quality';

    // Best Video + Audio option
    options.add(
      QualityOption(
        id: 'best',
        label: bestLabel,
        extension: 'mp4',
        height: maxHeight,
        formatSpecifier: 'bv*+ba/b',
        estimatedBytes: bestEstimatedBytes,
      ),
    );

    // Dynamically generate quality options for all stream resolutions present in the video
    String getResolutionName(int height) {
      switch (height) {
        case 4320:
          return '8K (4320p)';
        case 2160:
          return '4K (2160p)';
        case 1440:
          return '2K (1440p)';
        case 1080:
          return 'Full HD (1080p)';
        case 720:
          return 'HD (720p)';
        case 480:
          return 'SD (480p)';
        case 360:
          return '360p';
        default:
          return '${height}p';
      }
    }

    for (final targetHeight in sortedHeights) {
      final name = getResolutionName(targetHeight);
      options.add(
        QualityOption(
          id: '${targetHeight}p',
          label: '$name — MP4',
          extension: 'mp4',
          height: targetHeight,
          formatSpecifier:
              'bv*[height=$targetHeight]+ba/b[height=$targetHeight]/bv*[height<=$targetHeight]+ba/b[height<=$targetHeight]',
          estimatedBytes: getEstimatedBytes(targetHeight),
        ),
      );
    }

    // Audio-only option
    final audioFormat = videoInfo.formats.cast<VideoFormat?>().firstWhere(
      (f) =>
          f != null &&
          f.isAudioOnly &&
          f.fileSize != null &&
          f.fileSize! > 0,
      orElse: () => null,
    );

    options.add(
      QualityOption(
        id: 'audio_best',
        label: 'Audio Only — M4A/MP3',
        extension: 'm4a',
        isAudioOnly: true,
        formatSpecifier: 'ba/b',
        estimatedBytes: audioFormat?.fileSize,
      ),
    );

    return options;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QualityOption($label)';
}
