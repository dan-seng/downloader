import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/core/errors/app_exceptions.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

void main() {
  group('YtDlpService Real Integration', () {
    late YtDlpService service;

    setUp(() {
      service = YtDlpService(processService: const SystemProcessService());
    });

    test('fetches real metadata from YouTube via system yt-dlp', () async {
      const testUrl = 'https://www.youtube.com/watch?v=aqz-KE-bpKQ';
      final info = await service.fetchVideoInfo(testUrl);

      expect(info.id, equals('aqz-KE-bpKQ'));
      expect(info.title, contains('Big Buck Bunny'));
      expect(info.uploader, isNotEmpty);
      expect(info.duration, isNotNull);
      expect(info.duration!.inSeconds, greaterThan(600));
      expect(info.thumbnail, isNotNull);
      expect(info.formats, isNotEmpty);
      expect(info.videoFormats, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 90)));

    test('handles unsupported/non-video URLs gracefully', () async {
      const badUrl = 'https://invalid-host-name-does-not-exist.test/video';
      expect(
        () => service.fetchVideoInfo(badUrl),
        throwsA(isA<YtDlpException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
