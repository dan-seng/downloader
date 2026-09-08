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

    // Standard preset resolutions
    const standardPresets = [
      {'height': 2160, 'name': '4K (2160p)'},
      {'height': 1440, 'name': '2K (1440p)'},
      {'height': 1080, 'name': 'Full HD (1080p)'},
      {'height': 720, 'name': 'HD (720p)'},
      {'height': 480, 'name': 'SD (480p)'},
      {'height': 360, 'name': '360p'},
    ];

    for (final preset in standardPresets) {
      final targetHeight = preset['height'] as int;
      final name = preset['name'] as String;

      // Check if video actually has streams matching this resolution or dimensions
      final hasFormat = videoInfo.formats.any((f) {
        if (f.height == targetHeight) return true;
        if (f.height != null && (f.height! - targetHeight).abs() <= 16) {
          return true;
        }
        if (targetHeight == 2160 && (f.width == 3840 || f.height == 2160)) {
          return true;
        }
        if (targetHeight == 1440 && (f.width == 2560 || f.height == 1440)) {
          return true;
        }
        if (targetHeight == 1080 && (f.width == 1920 || f.height == 1080)) {
          return true;
        }
        if (targetHeight == 720 && (f.width == 1280 || f.height == 720)) {
          return true;
        }
        if (targetHeight == 480 && (f.width == 854 || f.height == 480)) {
          return true;
        }
        if (targetHeight == 360 && (f.width == 640 || f.height == 360)) {
          return true;
        }
        return false;
      });

      if (hasFormat) {
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
