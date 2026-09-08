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
      expect(options.any((o) => o.id == 'audio_best'), isTrue);
    });
  });
}
