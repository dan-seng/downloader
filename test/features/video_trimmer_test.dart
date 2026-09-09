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
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockTrimmerYtDlpService extends YtDlpService {
  MockTrimmerYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    return const VideoInfo(
      id: 'trimmer-101',
      title: 'Podcast Episode 42: Long Form Interview',
      uploader: 'Studio Labs',
      duration: Duration(minutes: 10, seconds: 0),
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

class MockTrimmerDownloadService extends DownloadService {
  TimeRangeClip? capturedClip;
  QualityOption? capturedQuality;

  MockTrimmerDownloadService() : super(processService: _DummyProcessService());

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
    capturedQuality = quality;
    capturedClip = clip;
    final task = DownloadTask(
      id: video.id,
      url: video.webpageUrl ?? 'https://example.com',
      title: video.title,
      status: DownloadStatus.completed,
      progress: 1.0,
    );
    onProgress(task);
  }
}

class MockStorageService extends StorageService {
  const MockStorageService();

  @override
  Future<String> getDefaultDownloadsDirectory() async => '/mock/downloads';

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async =>
      '/mock/downloads';
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
  testWidgets(
      'Video Trimmer Deck toggles clip mode, switches presets, and forwards --download-sections',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockYtDlp = MockTrimmerYtDlpService();
    final mockDownload = MockTrimmerDownloadService();
    const mockStorage = MockStorageService();

    final videoController = VideoController(ytDlpService: mockYtDlp);
    final downloadController = DownloadController(
      downloadService: mockDownload,
      storageService: mockStorage,
    );

    await tester.pumpWidget(VideoDownloaderApp(
      videoController: videoController,
      downloadController: downloadController,
    ));
    await tester.pumpAndSettle();

    // 1. Analyze video URL
    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/watch?v=trimmer-101',
    );
    await tester.pump();
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 2. Verify Video Trimmer Deck is displayed
    expect(find.text('VIDEO TRIMMER & CLIP SLICER · TIME RANGE'), findsOneWidget);
    expect(find.byKey(const ValueKey('clip_toggle_button')), findsOneWidget);
    expect(find.text('FULL VIDEO'), findsOneWidget);

    // Initial telemetry check
    expect(find.byKey(const ValueKey('main_telemetry_trim')), findsOneWidget);
    expect(find.text('FULL MEDIA'), findsOneWidget);

    // Range slider should not be visible when clip mode is off
    expect(find.byKey(const ValueKey('clip_range_slider')), findsNothing);

    // 3. Toggle Clip Mode ON
    await tester.tap(find.byKey(const ValueKey('clip_toggle_button')));
    await tester.pumpAndSettle();

    expect(downloadController.clip.isEnabled, isTrue);
    expect(find.text('CLIP ACTIVE'), findsOneWidget);
    expect(find.byKey(const ValueKey('clip_range_slider')), findsOneWidget);

    // 4. Tap "FIRST 60s" preset chip
    expect(find.byKey(const ValueKey('clip_preset_60s')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clip_preset_60s')));
    await tester.pumpAndSettle();

    expect(downloadController.clip.start, Duration.zero);
    expect(downloadController.clip.end, const Duration(seconds: 60));
    expect(find.text('CLIP: 01:00'), findsOneWidget);

    // 5. Tap "FIRST 30s" preset chip
    expect(find.byKey(const ValueKey('clip_preset_30s')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clip_preset_30s')));
    await tester.pumpAndSettle();

    expect(downloadController.clip.start, Duration.zero);
    expect(downloadController.clip.end, const Duration(seconds: 30));
    expect(find.text('CLIP: 00:30'), findsOneWidget);

    // 6. Tap DOWNLOAD button and verify section arguments were forwarded
    await tester.tap(find.text('DOWNLOAD'));
    await tester.pumpAndSettle();

    expect(mockDownload.capturedClip, isNotNull);
    expect(mockDownload.capturedClip!.isEnabled, isTrue);
    expect(mockDownload.capturedClip!.start, Duration.zero);
    expect(mockDownload.capturedClip!.end, const Duration(seconds: 30));
    expect(mockDownload.capturedClip!.toSectionArgument(), '*00:00-00:30');
  });
}
