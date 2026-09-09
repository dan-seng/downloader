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

class MockAudioYtDlpService extends YtDlpService {
  MockAudioYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    return const VideoInfo(
      id: 'podcast-101',
      title: 'Episode 101: Deep Space Exploration',
      uploader: 'Space Podcast Lab',
      duration: Duration(minutes: 42, seconds: 15),
      formats: [
        VideoFormat(
          formatId: '137',
          extension: 'mp4',
          height: 1080,
          videoCodec: 'h264',
          audioCodec: 'none',
        ),
        VideoFormat(
          formatId: '140',
          extension: 'm4a',
          videoCodec: 'none',
          audioCodec: 'aac',
          fileSize: 35 * 1024 * 1024,
        ),
      ],
    );
  }
}

class MockAudioDownloadService extends DownloadService {
  AudioConfig? capturedAudioConfig;
  QualityOption? capturedQuality;

  MockAudioDownloadService() : super(processService: _DummyProcessService());

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
    capturedAudioConfig = audioConfig;
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
  @override
  Future<String> getDefaultDownloadsDirectory() async => '/home/user/Music';
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
  testWidgets('Advanced Audio Mode reveals deck, switches presets, and downloads tagged audio',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockYtDlp = MockAudioYtDlpService();
    final mockDownload = MockAudioDownloadService();
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

    // Analyze podcast URL
    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/watch?v=podcast-101',
    );
    await tester.pump();
    await tester.tap(find.text('ANALYZE'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify video card is loaded
    expect(find.text('Episode 101: Deep Space Exploration'), findsWidgets);

    // Advanced Audio Engine should not be visible when MP4 is selected
    expect(find.text('ADVANCED AUDIO ENGINE · ID3v2 & HIGH-FIDELITY'), findsNothing);

    // Switch Format to Audio Only (M4A/MP3 — Audio Only)
    await tester.tap(find.text('MP4 — Video + Audio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('M4A/MP3 — Audio Only').last);
    await tester.pumpAndSettle();

    // Verify Advanced Audio Deck is now rendered!
    expect(find.text('ADVANCED AUDIO ENGINE · ID3v2 & HIGH-FIDELITY'), findsOneWidget);
    expect(find.text('EMBED ARTWORK'), findsOneWidget);
    expect(find.text('ID3 TAGS'), findsOneWidget);
    expect(find.text('PODCAST (192k)'), findsOneWidget);
    expect(find.text('STUDIO (320k)'), findsOneWidget);
    expect(find.text('VBR EFFICIENT'), findsOneWidget);

    // Tap the PODCAST preset
    await tester.tap(find.text('PODCAST (192k)'));
    await tester.pumpAndSettle();

    expect(downloadController.audioConfig.bitrate, AudioBitrate.kbps192);
    expect(downloadController.audioConfig.format, AudioFormat.mp3);
    expect(downloadController.audioConfig.embedThumbnail, isTrue);
    expect(downloadController.audioConfig.embedMetadata, isTrue);

    // Toggle EMBED ARTWORK off
    await tester.tap(find.text('EMBED ARTWORK'));
    await tester.pumpAndSettle();
    expect(downloadController.audioConfig.embedThumbnail, isFalse);

    // Toggle EMBED ARTWORK back on
    await tester.tap(find.text('EMBED ARTWORK'));
    await tester.pumpAndSettle();
    expect(downloadController.audioConfig.embedThumbnail, isTrue);

    // Tap STUDIO (320k) preset
    await tester.tap(find.text('STUDIO (320k)'));
    await tester.pumpAndSettle();
    expect(downloadController.audioConfig.bitrate, AudioBitrate.kbps320);

    // Tap DOWNLOAD button
    await tester.tap(find.text('DOWNLOAD'));
    await tester.pumpAndSettle();

    // Verify DownloadService received audio config with high-fidelity 320k MP3 + metadata
    expect(mockDownload.capturedQuality?.isAudioOnly, isTrue);
    expect(mockDownload.capturedAudioConfig?.bitrate, AudioBitrate.kbps320);
    expect(mockDownload.capturedAudioConfig?.format, AudioFormat.mp3);
    expect(mockDownload.capturedAudioConfig?.embedThumbnail, isTrue);
    expect(mockDownload.capturedAudioConfig?.embedMetadata, isTrue);
  });
}
