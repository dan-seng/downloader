import '../core/utils/formatters.dart';
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

    // Best Video + Audio option
    options.add(
      const QualityOption(
        id: 'best',
        label: 'Best Available Quality',
        extension: 'mp4',
        formatSpecifier: 'bv*+ba/b',
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

      // Check if video has streams matching or greater than this height
      if (sortedHeights.any((h) => h >= targetHeight)) {
        options.add(
          QualityOption(
            id: '${targetHeight}p',
            label: '$name — MP4',
            extension: 'mp4',
            height: targetHeight,
            formatSpecifier:
                'bv*[height<=$targetHeight]+ba/b[height<=$targetHeight]/best',
          ),
        );
      }
    }

    // Audio-only option
    options.add(
      const QualityOption(
        id: 'audio_best',
        label: 'Audio Only — M4A/MP3',
        extension: 'm4a',
        isAudioOnly: true,
        formatSpecifier: 'ba/b',
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
