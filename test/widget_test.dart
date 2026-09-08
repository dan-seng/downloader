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
  bool _isDownloading = false;

  MockDownloadService() : super(processService: _DummyProcessService());

  @override
  bool get isDownloading => _isDownloading;

  @override
  Future<void> startDownload({
    required VideoInfo video,
    required QualityOption quality,
    required String destinationDirectory,
    required DownloadProgressCallback onProgress,
    DownloadLogCallback? onLog,
  }) async {
    _isDownloading = true;
    onLog?.call('[download] Destination: /tmp/sample.mp4');
    onLog?.call('[download] 45.0% of 25.00MiB at 4.50MiB/s ETA 00:03');
    final task = DownloadTask(
      id: video.id,
      url: 'https://example.com',
      title: video.title,
      status: DownloadStatus.downloading,
      progress: 0.45,
      speed: 4.5 * 1024 * 1024,
      eta: const Duration(seconds: 3),
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
  testWidgets('SPIDEY_DLX full analyze, quality selection, and download flow',
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

    // Verify initial SPIDEY_DLX faceplate & deck state
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('SPIDEY_DLX'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('WEB-SLINGING VIDEO GRABBER'), findsOneWidget);
    expect(find.text('ANALYZE'), findsOneWidget);
    expect(find.text('No media target loaded'), findsOneWidget);

    // Enter a URL
    await tester.enterText(
        find.byType(TextField), 'https://www.youtube.com/watch?v=123');
    await tester.pump();

    // Tap ANALYZE
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify video preview card details (title appears in both sidebar queue and preview deck)
    expect(find.text('Sample Video Title'), findsNWidgets(2));
    expect(find.textContaining('Sample Creator'), findsOneWidget);
    expect(find.text('05:30'), findsWidgets);
    expect(find.text('FORMAT'), findsOneWidget);
    expect(find.text('QUALITY'), findsOneWidget);
    expect(find.textContaining('SAVING TO'), findsOneWidget);
    expect(find.text('DOWNLOAD'), findsOneWidget);

    // Tap DOWNLOAD
    await tester.tap(find.text('DOWNLOAD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify downloading state in faceplate status pill and transport button
    expect(find.text('DOWNLOADING'), findsNWidgets(2));
    expect(find.text('SUBPROCESS OUTPUT'), findsOneWidget);
  });
}
