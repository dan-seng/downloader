import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/main.dart';
import 'package:video_downloader/models/audio_config.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/playlist_info.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/speed_limit.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockPlaylistYtDlpService extends YtDlpService {
  PlaylistInfo? mockPlaylist;

  MockPlaylistYtDlpService() : super(processService: _DummyProcessService());

  @override
  bool isPlaylistUrl(String rawUrl) {
    return rawUrl.contains('playlist') || rawUrl.contains('list=');
  }

  @override
  Future<PlaylistInfo> fetchPlaylistInfo(String rawUrl) async {
    return mockPlaylist ??
        PlaylistInfo(
          id: 'PL_TEST_123',
          title: 'Cyber Synth Playlist',
          uploader: 'Synth Master',
          webpageUrl: rawUrl,
          items: [
            PlaylistItem(
              id: 'track-1',
              url: 'https://youtube.com/watch?v=t1',
              title: 'Neon Horizon',
              uploader: 'Synth Master',
              duration: const Duration(minutes: 3, seconds: 45),
            ),
            PlaylistItem(
              id: 'track-2',
              url: 'https://youtube.com/watch?v=t2',
              title: 'Midnight Driver',
              uploader: 'Synth Master',
              duration: const Duration(minutes: 4, seconds: 20),
            ),
            PlaylistItem(
              id: 'track-3',
              url: 'https://youtube.com/watch?v=t3',
              title: 'Electric Dream',
              uploader: 'Synth Master',
              duration: const Duration(minutes: 2, seconds: 55),
            ),
          ],
        );
  }
}

class MockBatchDownloadService extends DownloadService {
  bool _isDownloading = false;

  MockBatchDownloadService() : super(processService: _DummyProcessService());

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
  }) async {
    _isDownloading = true;
    onLog?.call('[spidey_engine] Downloading track ${video.title}');
    final task = DownloadTask(
      id: video.id,
      url: video.webpageUrl ?? 'https://example.com',
      title: video.title,
      status: DownloadStatus.downloading,
      progress: 0.50,
      speed: 3.5 * 1024 * 1024,
      eta: const Duration(seconds: 5),
    );
    onProgress(task);
    // Complete download after reporting progress
    task.status = DownloadStatus.completed;
    task.progress = 1.0;
    onProgress(task);
    _isDownloading = false;
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
  testWidgets('SPIDEY_DLX Playlist batch deck renders, toggles selection, and executes batch',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockYtDlp = MockPlaylistYtDlpService();
    final mockDownload = MockBatchDownloadService();
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

    // Input a playlist link
    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/playlist?list=PL_TEST_123',
    );
    await tester.pump();

    // Tap ANALYZE
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify Playlist deck loaded
    expect(find.text('Cyber Synth Playlist'), findsOneWidget);
    expect(find.textContaining('Synth Master'), findsWidgets);
    expect(find.textContaining('3 tracks discovered'), findsOneWidget);
    expect(find.text('QUEUE — 3 TRACKS'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);

    // Verify tracks are rendered
    expect(find.text('Neon Horizon'), findsWidgets);
    expect(find.text('Midnight Driver'), findsWidgets);
    expect(find.text('Electric Dream'), findsWidgets);

    // Verify selection summary and batch download button
    expect(find.text('3 OF 3 SELECTED'), findsOneWidget);
    expect(find.text('DOWNLOAD 3 TRACKS'), findsOneWidget);

    // Test DESELECT ALL
    await tester.tap(find.text('DESELECT ALL'));
    await tester.pumpAndSettle();

    expect(find.text('0 OF 3 SELECTED'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.text('DOWNLOAD 0 TRACKS'), findsOneWidget);

    // Toggle track 1 (Neon Horizon)
    await tester.tap(find.text('Neon Horizon').first);
    await tester.pumpAndSettle();

    expect(find.text('1 OF 3 SELECTED'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('DOWNLOAD 1 TRACKS'), findsOneWidget);

    // Tap SELECT ALL
    await tester.tap(find.text('SELECT ALL'));
    await tester.pumpAndSettle();

    expect(find.text('3 OF 3 SELECTED'), findsOneWidget);
    expect(find.text('DOWNLOAD 3 TRACKS'), findsOneWidget);

    // Tap DOWNLOAD 3 TRACKS
    await tester.tap(find.text('DOWNLOAD 3 TRACKS'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify completion
    expect(downloadController.batchCompletedCount, 3);
  });
}
