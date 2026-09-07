import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';

void main() {
  group('VideoFormat', () {
    test('parses complete format json correctly', () {
      final json = {
        'format_id': '137',
        'ext': 'mp4',
        'width': 1920,
        'height': 1080,
        'fps': 60,
        'vcodec': 'avc1.64002a',
        'acodec': 'none',
        'filesize': 154800000,
        'format_note': '1080p60',
        'tbr': 4500.5,
      };

      final format = VideoFormat.fromJson(json);

      expect(format.formatId, equals('137'));
      expect(format.extension, equals('mp4'));
      expect(format.width, equals(1920));
      expect(format.height, equals(1080));
      expect(format.fps, equals(60.0));
      expect(format.videoCodec, equals('avc1.64002a'));
      expect(format.audioCodec, equals('none'));
      expect(format.fileSize, equals(154800000));
      expect(format.hasVideo, isTrue);
      expect(format.hasAudio, isFalse);
      expect(format.isVideoOnly, isTrue);
      expect(format.isAudioOnly, isFalse);
      expect(format.resolutionLabel, equals('1080p'));
    });

    test('parses audio-only format correctly', () {
      final json = {
        'format_id': '140',
        'ext': 'm4a',
        'vcodec': 'none',
        'acodec': 'mp4a.40.2',
        'filesize_approx': 12000000,
        'format_note': 'medium',
      };

      final format = VideoFormat.fromJson(json);

      expect(format.formatId, equals('140'));
      expect(format.hasVideo, isFalse);
      expect(format.hasAudio, isTrue);
      expect(format.isAudioOnly, isTrue);
      expect(format.resolutionLabel, equals('Audio only'));
      expect(format.fileSize, equals(12000000));
    });

    test('handles missing or malformed fields safely', () {
      final format = VideoFormat.fromJson({});
      expect(format.formatId, equals(''));
      expect(format.hasVideo, isFalse);
      expect(format.hasAudio, isFalse);
      expect(format.resolutionLabel, equals('Unknown resolution'));
    });
  });

  group('VideoInfo', () {
    test('parses yt-dlp metadata json correctly', () {
      final json = {
        'id': 'aqz-KE-bpKQ',
        'title': 'Big Buck Bunny 60fps 4K',
        'thumbnail': 'https://i.ytimg.com/vi/aqz-KE-bpKQ/maxresdefault.jpg',
        'duration': 635,
        'uploader': 'Blender',
        'webpage_url': 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
        'formats': [
          {
            'format_id': '137',
            'ext': 'mp4',
            'height': 1080,
            'vcodec': 'avc1',
            'acodec': 'none',
          },
          {
            'format_id': '140',
            'ext': 'm4a',
            'vcodec': 'none',
            'acodec': 'mp4a',
          },
          {
            'format_id': '18',
            'ext': 'mp4',
            'height': 360,
            'vcodec': 'avc1',
            'acodec': 'mp4a',
          }
        ],
      };

      final info = VideoInfo.fromJson(json);

      expect(info.id, equals('aqz-KE-bpKQ'));
      expect(info.title, equals('Big Buck Bunny 60fps 4K'));
      expect(info.thumbnail, equals('https://i.ytimg.com/vi/aqz-KE-bpKQ/maxresdefault.jpg'));
      expect(info.duration, equals(const Duration(seconds: 635)));
      expect(info.formattedDuration, equals('10:35'));
      expect(info.uploader, equals('Blender'));
      expect(info.formats.length, equals(3));
      expect(info.videoFormats.length, equals(2));
      expect(info.audioFormats.length, equals(2));
    });

    test('handles empty json gracefully', () {
      final info = VideoInfo.fromJson({});
      expect(info.id, equals(''));
      expect(info.title, equals('Untitled Video'));
      expect(info.duration, isNull);
      expect(info.formattedDuration, equals('Unknown'));
      expect(info.formats, isEmpty);
    });
  });
}
