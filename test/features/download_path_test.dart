import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/main.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/time_range_clip.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockPathYtDlpService extends YtDlpService {
  MockPathYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    return const VideoInfo(
      id: 'path-test-vid',
      title: 'Path Testing Video',
      uploader: 'File System Lab',
      duration: Duration(minutes: 3, seconds: 15),
      formats: [
        VideoFormat(
          formatId: '137',
          extension: 'mp4',
          height: 1080,
          videoCodec: 'h264',
          audioCodec: 'none',
        ),
      ],
    );
  }
}

class MockPathDownloadService extends DownloadService {
  MockPathDownloadService() : super(processService: _DummyProcessService());

  @override
  Future<void> startDownload({
    required VideoInfo video,
    required QualityOption quality,
    required String destinationDirectory,
    required DownloadProgressCallback onProgress,
    DownloadLogCallback? onLog,
    dynamic audioConfig,
    dynamic speedLimit,
    TimeRangeClip? clip,
  }) async {
    onProgress(DownloadTask(
      id: video.id,
      url: video.webpageUrl ?? 'https://example.com',
      title: video.title,
      status: DownloadStatus.completed,
      progress: 1.0,
    ));
  }
}

class MockPathStorageService extends StorageService {
  String? lastOpenedDirectory;
  String currentPickedPath = '/custom/picked/path';

  @override
  Future<String> getDefaultDownloadsDirectory() async => '/home/spidey/Downloads';

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async => currentPickedPath;

  @override
  Future<void> openDirectory(String directoryPath) async {
    lastOpenedDirectory = directoryPath;
  }

  @override
  Future<Map<String, String>> getQuickDirectories() async => {
        'Downloads': '/home/spidey/Downloads',
        'Videos': '/home/spidey/Videos',
        'Desktop': '/home/spidey/Desktop',
      };
}

class _DummyProcessService implements ProcessService {
  @override
  Future<io.ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment}) async {
    return io.ProcessResult(1, 0, '', '');
  }

  @override
  Future<io.Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('Choosing download path via header pill, custom dialog, and empty state',
      (WidgetTester tester) async {
    final mockYt = MockPathYtDlpService();
    final mockDl = MockPathDownloadService();
    final mockStorage = MockPathStorageService();

    final videoController = VideoController(ytDlpService: mockYt);
    final downloadController = DownloadController(
      downloadService: mockDl,
      storageService: mockStorage,
    );

    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      VideoDownloaderApp(
        videoController: videoController,
        downloadController: downloadController,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // 1. Initial State: Header folder pill displays 'Downloads'
    expect(find.byKey(const ValueKey('faceplate_folder_button')), findsOneWidget);
    expect(find.text('Downloads'), findsWidgets);

    // 2. Empty state card displays DESTINATION and CHOOSE FOLDER button
    expect(find.textContaining('DESTINATION'), findsOneWidget);
    expect(find.text('CHOOSE FOLDER'), findsOneWidget);

    // 3. Tap CHOOSE FOLDER in empty state card -> updates path
    await tester.tap(find.text('CHOOSE FOLDER'));
    await tester.pumpAndSettle();
    expect(downloadController.downloadDirectory, equals('/custom/picked/path'));
    expect(find.text('path'), findsWidgets);

    // 4. Open Header Folder Pill popup menu
    await tester.tap(find.byKey(const ValueKey('faceplate_folder_button')));
    await tester.pumpAndSettle();

    expect(find.text('Browse Folder...'), findsOneWidget);
    expect(find.text('Enter Custom Path...'), findsOneWidget);
    expect(find.text('Open in File Manager'), findsOneWidget);

    // 5. Tap 'Enter Custom Path...' to open dialog
    await tester.tap(find.text('Enter Custom Path...'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom_path_input')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom_path_apply_button')), findsOneWidget);

    // Enter a new custom path
    await tester.enterText(
      find.byKey(const ValueKey('custom_path_input')),
      '/storage/media/SpiderVideos',
    );
    await tester.pump();

    // Tap APPLY
    await tester.tap(find.byKey(const ValueKey('custom_path_apply_button')));
    await tester.pumpAndSettle();

    expect(downloadController.downloadDirectory, equals('/storage/media/SpiderVideos'));
    expect(find.text('SpiderVideos'), findsWidgets);

    // 6. Test 'Open in File Manager' via header pill
    await tester.tap(find.byKey(const ValueKey('faceplate_folder_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open in File Manager'));
    await tester.pumpAndSettle();
    expect(mockStorage.lastOpenedDirectory, equals('/storage/media/SpiderVideos'));

    // 7. Analyze video and verify SAVING TO row in preview deck with CHANGE and OPEN buttons
    await tester.enterText(find.byType(TextField).first, 'https://youtube.com/watch?v=path-test');
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('SAVING TO'), findsOneWidget);
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('OPEN'), findsWidgets);

    // Tap CHANGE button in preview card
    mockStorage.currentPickedPath = '/movies/hero_action';
    await tester.tap(find.text('CHANGE'));
    await tester.pumpAndSettle();

    expect(downloadController.downloadDirectory, equals('/movies/hero_action'));
  });
}
