import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/core/errors/app_exceptions.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class FakeProcessService implements ProcessService {
  io.ProcessResult Function(String executable, List<String> arguments)? onRun;

  @override
  Future<io.ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (onRun != null) {
      return onRun!(executable, arguments);
    }
    return io.ProcessResult(1, 0, '{}', '');
  }

  @override
  Future<io.Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) {
    throw UnimplementedError('start is not used for fetchVideoInfo');
  }
}

void main() {
  group('YtDlpService', () {
    late FakeProcessService fakeProcess;
    late YtDlpService service;

    setUp(() {
      fakeProcess = FakeProcessService();
      service = YtDlpService(processService: fakeProcess);
    });

    test('successfully fetches and parses video metadata', () async {
      final sampleMetadata = {
        'id': 'test-123',
        'title': 'Test Video Title',
        'uploader': 'Test Creator',
        'duration': 120,
        'formats': [
          {'format_id': '1', 'ext': 'mp4', 'height': 720, 'vcodec': 'h264'}
        ]
      };

      fakeProcess.onRun = (executable, arguments) {
        expect(arguments, contains('--dump-single-json'));
        expect(arguments, contains('--no-playlist'));
        expect(arguments.last, equals('https://example.com/watch?v=123'));
        return io.ProcessResult(1, 0, jsonEncode(sampleMetadata), '');
      };

      final info = await service.fetchVideoInfo('https://example.com/watch?v=123');

      expect(info.id, equals('test-123'));
      expect(info.title, equals('Test Video Title'));
      expect(info.uploader, equals('Test Creator'));
      expect(info.duration, equals(const Duration(seconds: 120)));
      expect(info.formats.length, equals(1));
    });

    test('translates network error into user-friendly message', () async {
      fakeProcess.onRun = (executable, arguments) {
        return io.ProcessResult(
          1,
          1,
          '',
          'ERROR: [generic] notfound: Unable to download webpage: [Errno -2] Name or service not known',
        );
      };

      expect(
        () => service.fetchVideoInfo('https://example.com/video'),
        throwsA(
          isA<YtDlpException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('internet connection'),
          ),
        ),
      );
    });

    test('translates unsupported url error into user-friendly message', () async {
      fakeProcess.onRun = (executable, arguments) {
        return io.ProcessResult(
          1,
          1,
          '',
          'ERROR: Unsupported URL: https://some-unknown-site.com',
        );
      };

      expect(
        () => service.fetchVideoInfo('https://some-unknown-site.com'),
        throwsA(
          isA<YtDlpException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('URL is not supported'),
          ),
        ),
      );
    });

    test('throws on empty stdout', () async {
      fakeProcess.onRun = (executable, arguments) {
        return io.ProcessResult(1, 0, '   ', '');
      };

      expect(
        () => service.fetchVideoInfo('https://example.com/video'),
        throwsA(isA<YtDlpException>()),
      );
    });
  });
}
