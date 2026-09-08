import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';

void main() {
  group('QualityOption', () {
    test('generates expected presets from high-res video formats', () {
      const video = VideoInfo(
        id: 'test-1',
        title: '4K Test',
        formats: [
          VideoFormat(formatId: '1', height: 2160, videoCodec: 'vp9'),
          VideoFormat(formatId: '2', height: 1080, videoCodec: 'h264'),
          VideoFormat(formatId: '3', height: 720, videoCodec: 'h264'),
          VideoFormat(formatId: '4', height: 480, videoCodec: 'h264'),
          VideoFormat(formatId: '5', audioCodec: 'aac'),
        ],
      );

      final options = QualityOption.fromVideoInfo(video);

      expect(options.any((o) => o.id == 'best'), isTrue);
      expect(options.any((o) => o.id == '2160p'), isTrue);
      expect(options.any((o) => o.id == '1080p'), isTrue);
      expect(options.any((o) => o.id == '720p'), isTrue);
      expect(options.any((o) => o.id == '480p'), isTrue);
      expect(options.any((o) => o.id == 'audio_best'), isTrue);
    });

    test('generates only achievable resolutions for low-res video', () {
      const video = VideoInfo(
        id: 'test-2',
        title: 'SD Test',
        formats: [
          VideoFormat(formatId: '1', height: 480, videoCodec: 'h264'),
          VideoFormat(formatId: '2', height: 360, videoCodec: 'h264'),
        ],
      );

      final options = QualityOption.fromVideoInfo(video);

      expect(options.any((o) => o.id == '1080p'), isFalse);
      expect(options.any((o) => o.id == '720p'), isFalse);
      expect(options.any((o) => o.id == '480p'), isTrue);
      expect(options.any((o) => o.id == '360p'), isTrue);
    });

    test('strict format specifier targets exact resolution without falling back to /best', () {
      const video = VideoInfo(
        id: 'test-3',
        title: 'HD Test',
        formats: [
          VideoFormat(formatId: '1', height: 1080, videoCodec: 'h264'),
          VideoFormat(formatId: '2', height: 720, videoCodec: 'h264'),
        ],
      );

      final options = QualityOption.fromVideoInfo(video);
      final option720 = options.firstWhere((o) => o.id == '720p');

      expect(option720.formatSpecifier.contains('/best'), isFalse);
      expect(option720.formatSpecifier, contains('height=720'));
      expect(option720.formatSpecifier, contains('height<=720'));
    });

    test('calculates estimated bytes when video and audio sizes are present', () {
      const video = VideoInfo(
        id: 'test-4',
        title: 'Size Test',
        formats: [
          VideoFormat(
            formatId: '1',
            height: 1080,
            videoCodec: 'h264',
            fileSize: 40000000,
          ),
          VideoFormat(
            formatId: '2',
            audioCodec: 'aac',
            fileSize: 5000000,
          ),
        ],
      );

      final options = QualityOption.fromVideoInfo(video);
      final option1080 = options.firstWhere((o) => o.id == '1080p');

      expect(option1080.estimatedBytes, equals(45000000));
      expect(option1080.formattedSize, isNotEmpty);
    });
  });
}
