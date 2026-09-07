import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/core/errors/app_exceptions.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockYtDlpService extends YtDlpService {
  VideoInfo? mockResult;
  Exception? mockError;

  MockYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    if (mockError != null) {
      throw mockError!;
    }
    return mockResult ??
        const VideoInfo(
          id: 'test-id',
          title: 'Mock Video',
          formats: [],
        );
  }
}

class _DummyProcessService implements ProcessService {
  @override
  Future<io.ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment}) async {
    return io.ProcessResult(1, 0, '', '');
  }

  @override
  Future<io.Process> start(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      io.ProcessStartMode mode = io.ProcessStartMode.normal}) {
    throw UnimplementedError();
  }
}

void main() {
  group('VideoController', () {
    late MockYtDlpService mockService;
    late VideoController controller;

    setUp(() {
      mockService = MockYtDlpService();
      controller = VideoController(ytDlpService: mockService);
    });

    test('initial state is idle', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.currentVideo, isNull);
      expect(controller.hasVideo, isFalse);
    });

    test('analyzeUrl transitions to success state', () async {
      mockService.mockResult = const VideoInfo(
        id: 'success-id',
        title: 'Success Title',
        formats: [],
      );

      final future = controller.analyzeUrl('https://example.com/video');
      expect(controller.isLoading, isTrue);

      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.hasVideo, isTrue);
      expect(controller.currentVideo?.title, equals('Success Title'));
      expect(controller.errorMessage, isNull);
    });

    test('analyzeUrl captures AppException user message', () async {
      mockService.mockError = const InvalidUrlException('Invalid test URL');

      await controller.analyzeUrl('https://bad-url.com');

      expect(controller.isLoading, isFalse);
      expect(controller.hasVideo, isFalse);
      expect(controller.errorMessage, equals('Invalid test URL'));
    });

    test('clear resets controller state', () async {
      mockService.mockResult = const VideoInfo(
        id: '1',
        title: 'Title',
        formats: [],
      );
      await controller.analyzeUrl('https://example.com/video');
      expect(controller.hasVideo, isTrue);

      controller.clear();

      expect(controller.hasVideo, isFalse);
      expect(controller.currentVideo, isNull);
      expect(controller.analyzedUrl, isNull);
      expect(controller.errorMessage, isNull);
    });
  });
}
