import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/main.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockYtDlpService extends YtDlpService {
  VideoInfo? mockResult;

  MockYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    return mockResult ??
        const VideoInfo(
          id: 'test-123',
          title: 'Sample Video Title',
          uploader: 'Sample Creator',
          duration: Duration(minutes: 5, seconds: 30),
          formats: [
            VideoFormat(
              formatId: '1',
              extension: 'mp4',
              height: 1080,
              videoCodec: 'h264',
              audioCodec: 'aac',
            ),
          ],
        );
  }
}

class MockDownloadService extends DownloadService {
  MockDownloadService() : super(processService: _DummyProcessService());

  @override
  Future<void> startDownload({
    required VideoInfo video,
    required QualityOption quality,
    required String destinationDirectory,
    required DownloadProgressCallback onProgress,
  }) async {
    final task = DownloadTask(
      id: video.id,
      url: 'https://example.com',
      title: video.title,
      status: DownloadStatus.downloading,
      progress: 0.45,
    );
    onProgress(task);
  }
}

class MockStorageService extends StorageService {
  @override
  Future<String> getDefaultDownloadsDirectory() async => '/home/user/Downloads';
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
  testWidgets('Full analyze, quality selection, and download flow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockYtDlp = MockYtDlpService();
    final mockDownload = MockDownloadService();
    final mockStorage = MockStorageService();

    final videoController = VideoController(ytDlpService: mockYtDlp);
    final downloadController = DownloadController(
      downloadService: mockDownload,
      storageService: mockStorage,
    );

    await tester.pumpWidget(VideoDownloaderApp(
      videoController: videoController,
      downloadController: downloadController,
    ));

    // Verify initial state
    expect(find.text('Video Downloader'), findsOneWidget);
    expect(find.text('Ready when you are!'), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);

    // Enter a URL
    await tester.enterText(
        find.byType(TextField), 'https://www.youtube.com/watch?v=123');
    await tester.pump();

    // Tap Analyze
    await tester.tap(find.text('Analyze'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify video preview card
    expect(find.text('Sample Video Title'), findsOneWidget);
    expect(find.text('Sample Creator'), findsOneWidget);
    expect(find.text('05:30'), findsNWidgets(2));

    // Verify download configuration card
    expect(find.text('Select Quality & Format'), findsOneWidget);
    expect(find.text('Save location'), findsOneWidget);
    expect(find.text('Start Download'), findsOneWidget);

    // Tap Start Download
    await tester.tap(find.text('Start Download'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify live progress card
    expect(find.textContaining('Downloading: Sample Video Title'), findsOneWidget);
    expect(find.text('45.0%'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
