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
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockBandwidthYtDlpService extends YtDlpService {
  MockBandwidthYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    return const VideoInfo(
      id: 'bandwidth-101',
      title: 'Bandwidth Testing Track',
      uploader: 'Net Ops Lab',
      duration: Duration(minutes: 5, seconds: 0),
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

class MockBandwidthDownloadService extends DownloadService {
  SpeedLimit? capturedSpeedLimit;
  QualityOption? capturedQuality;

  MockBandwidthDownloadService() : super(processService: _DummyProcessService());

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
    capturedQuality = quality;
    capturedSpeedLimit = speedLimit;
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
      'Bandwidth Limiter and Scheduling pills update state and forward speed limit to download service',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockYtDlp = MockBandwidthYtDlpService();
    final mockDownload = MockBandwidthDownloadService();
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

    // 1. Check faceplate initial states: ⚡ MAX and ⏱ NOW
    expect(find.byKey(const ValueKey('faceplate_throttle_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('faceplate_schedule_button')), findsOneWidget);
    expect(find.text('⚡ MAX'), findsOneWidget);
    expect(find.text('⏱ NOW'), findsOneWidget);

    // 2. Tap faceplate throttle button and select 10 MB/s (Standard)
    await tester.tap(find.byKey(const ValueKey('faceplate_throttle_button')));
    await tester.pumpAndSettle();

    expect(find.text('10 MB/s (Standard)'), findsOneWidget);
    await tester.tap(find.text('10 MB/s (Standard)'));
    await tester.pumpAndSettle();

    expect(downloadController.speedLimit, SpeedLimit.mbps10);
    expect(find.text('⚡ 10 MB/s'), findsOneWidget);

    // 3. Tap faceplate schedule button and select In 15 minutes
    await tester.tap(find.byKey(const ValueKey('faceplate_schedule_button')));
    await tester.pumpAndSettle();

    expect(find.text('In 15 minutes'), findsOneWidget);
    await tester.tap(find.text('In 15 minutes'));
    await tester.pumpAndSettle();

    expect(downloadController.scheduleDelay, ScheduleDelay.min15);
    expect(find.text('⏱ 15m'), findsOneWidget);

    // 4. Reset schedule delay to Start Immediately so download can run without waiting
    await tester.tap(find.byKey(const ValueKey('faceplate_schedule_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Immediately'));
    await tester.pumpAndSettle();

    expect(downloadController.scheduleDelay, ScheduleDelay.none);
    expect(find.text('⏱ NOW'), findsOneWidget);

    // 5. Analyze a video to populate deck and telemetry strip
    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/watch?v=bandwidth-101',
    );
    await tester.pump();
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Telemetry strip on wide screen should show THROTTLE and SCHEDULE
    expect(find.byKey(const ValueKey('main_telemetry_throttle')), findsOneWidget);
    expect(find.byKey(const ValueKey('main_telemetry_schedule')), findsOneWidget);

    // Change throttle via telemetry strip to 5 MB/s (Balanced)
    await tester.tap(find.byKey(const ValueKey('main_telemetry_throttle')));
    await tester.pumpAndSettle();

    expect(find.text('5 MB/s (Balanced)'), findsOneWidget);
    await tester.tap(find.text('5 MB/s (Balanced)'));
    await tester.pumpAndSettle();

    expect(downloadController.speedLimit, SpeedLimit.mbps5);

    // 6. Initiate download and verify speed limit was forwarded to DownloadService
    await tester.tap(find.text('DOWNLOAD'));
    await tester.pumpAndSettle();

    expect(mockDownload.capturedSpeedLimit, SpeedLimit.mbps5);
  });
}
