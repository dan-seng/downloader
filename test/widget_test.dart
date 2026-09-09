import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/main.dart';
import 'package:video_downloader/models/audio_config.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/speed_limit.dart';
import 'package:video_downloader/models/time_range_clip.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/download_archive_item.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/archive_service.dart';
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
    AudioConfig? audioConfig,
    SpeedLimit? speedLimit,
    TimeRangeClip? clip,
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

class MockArchiveService extends ArchiveService {
  MockArchiveService() : super(customStoragePath: '/tmp/test_widget_archive.json');

  @override
  Future<List<DownloadArchiveItem>> loadArchive() async => [];

  @override
  Future<void> saveItem(DownloadArchiveItem item) async {}
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

class _CompleterYtDlpService extends YtDlpService {
  final Completer<VideoInfo> completer;

  _CompleterYtDlpService(this.completer)
      : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) => completer.future;
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
      archiveService: MockArchiveService(),
    );

    await tester.pumpWidget(VideoDownloaderApp(
      videoController: videoController,
      downloadController: downloadController,
    ));

    // Verify initial VINX faceplate & deck state
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('VINX'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('ULTRA-FAST MEDIA ENGINE'), findsOneWidget);
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

  testWidgets(
      'Analyze button transforms into loading circle when looking for videos',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<VideoInfo>();
    final mockYtDlp = _CompleterYtDlpService(completer);
    final mockDownload = MockDownloadService();
    final mockStorage = MockStorageService();

    final videoController = VideoController(ytDlpService: mockYtDlp);
    final downloadController = DownloadController(
      downloadService: mockDownload,
      storageService: mockStorage,
      archiveService: MockArchiveService(),
    );

    await tester.pumpWidget(VideoDownloaderApp(
      videoController: videoController,
      downloadController: downloadController,
    ));

    // Initially: ANALYZE button is present, no loading circle
    expect(find.text('ANALYZE'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Enter URL and trigger analyze
    await tester.enterText(
        find.byType(TextField), 'https://www.youtube.com/watch?v=123');
    await tester.pump();
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();

    // While looking for videos:
    // 1. Loading circle indicator is visible inside the button
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // 2. ANALYZE text is replaced
    expect(find.text('ANALYZE'), findsNothing);
    // 3. TextField is disabled
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);

    // Complete the fetch
    completer.complete(const VideoInfo(
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
    ));
    await tester.pumpAndSettle();

    // After completion: ANALYZE text restored, loading circle removed, TextField enabled
    expect(find.text('ANALYZE'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final restoredTextField = tester.widget<TextField>(find.byType(TextField));
    expect(restoredTextField.enabled, isTrue);
  });

  testWidgets(
      'Theme toggle switch alternates between dark and light modes with icon knob',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
    final mockYtDlp = MockYtDlpService();
    final mockDownload = MockDownloadService();
    final mockStorage = MockStorageService();

    final videoController = VideoController(ytDlpService: mockYtDlp);
    final downloadController = DownloadController(
      downloadService: mockDownload,
      storageService: mockStorage,
      archiveService: MockArchiveService(),
    );

    await tester.pumpWidget(VideoDownloaderApp(
      videoController: videoController,
      downloadController: downloadController,
      themeModeNotifier: themeModeNotifier,
    ));

    // Dark mode initially: crescent moon icon knob is rendered
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byTooltip('Switch to Light mode'), findsOneWidget);

    // Ensure visible and tap the switch to change to Light Mode
    await tester.ensureVisible(find.byTooltip('Switch to Light mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to Light mode'));
    await tester.pumpAndSettle();

    // Verify Light mode state and sun icon knob
    expect(themeModeNotifier.value, ThemeMode.light);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byTooltip('Switch to Dark mode'), findsOneWidget);

    // Ensure visible and tap again to switch back to Dark Mode
    await tester.ensureVisible(find.byTooltip('Switch to Dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to Dark mode'));
    await tester.pumpAndSettle();

    // Verify Dark mode restored
    expect(themeModeNotifier.value, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
