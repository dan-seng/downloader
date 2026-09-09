import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/models/audio_config.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/speed_limit.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/storage_service.dart';

class MockStorageService extends StorageService {
  @override
  Future<String> getDefaultDownloadsDirectory() async => '/fake/downloads';

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async =>
      '/custom/path';
}

class MockDownloadService extends DownloadService {
  bool downloadStarted = false;
  bool downloadCancelled = false;
  AudioConfig? lastAudioConfig;
  SpeedLimit? lastSpeedLimit;

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
    downloadStarted = true;
    lastAudioConfig = audioConfig;
    lastSpeedLimit = speedLimit;
    onLog?.call('[download] 50% of 10.0MiB at 5.0MiB/s ETA 00:01');
    final task = DownloadTask(
      id: video.id,
      url: 'https://example.com',
      title: video.title,
      status: DownloadStatus.downloading,
      progress: 0.5,
    );
    onProgress(task);
  }

  @override
  Future<void> cancelCurrentDownload() async {
    downloadCancelled = true;
  }
}

void main() {
  group('DownloadController', () {
    late MockDownloadService mockDownloadService;
    late MockStorageService mockStorageService;
    late DownloadController controller;

    setUp(() {
      mockDownloadService = MockDownloadService();
      mockStorageService = MockStorageService();
      controller = DownloadController(
        downloadService: mockDownloadService,
        storageService: mockStorageService,
      );
    });

    test('initializes default downloads directory', () async {
      await controller.initialize();
      expect(controller.downloadDirectory, equals('/fake/downloads'));
    });

    test('setting video populates available qualities and selects best', () {
      const video = VideoInfo(
        id: 'test',
        title: 'Title',
        formats: [
          VideoFormat(formatId: '1', height: 1080, videoCodec: 'h264'),
          VideoFormat(formatId: '2', height: 720, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);

      expect(controller.availableQualities, isNotEmpty);
      expect(controller.selectedQuality?.height, equals(1080));
    });

    test('setting 4K video selects 2160p by default', () {
      const video = VideoInfo(
        id: '4k-test',
        title: '4K Title',
        formats: [
          VideoFormat(formatId: '1', height: 2160, videoCodec: 'vp9'),
          VideoFormat(formatId: '2', height: 1080, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);

      expect(controller.selectedQuality?.height, equals(2160));
    });

    test('setting 720p video selects 720p by default', () {
      const video = VideoInfo(
        id: '720p-test',
        title: '720p Title',
        formats: [
          VideoFormat(formatId: '1', height: 720, videoCodec: 'h264'),
          VideoFormat(formatId: '2', height: 480, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);

      expect(controller.selectedQuality?.height, equals(720));
    });

    test('pickDirectory updates destination directory', () async {
      await controller.pickDirectory();
      expect(controller.downloadDirectory, equals('/custom/path'));
    });

    test('startDownload updates currentTask with progress', () async {
      const video = VideoInfo(
        id: 'vid-1',
        title: 'Test',
        formats: [
          VideoFormat(formatId: '1', height: 720, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);
      await controller.startDownload(video);

      expect(mockDownloadService.downloadStarted, isTrue);
      expect(controller.currentTask, isNotNull);
      expect(controller.currentTask?.progress, equals(0.5));
    });

    test('cancelDownload invokes service cancellation', () async {
      await controller.cancelDownload();
      expect(mockDownloadService.downloadCancelled, isTrue);
    });

    test('updates audioConfig settings and applies presets', () {
      expect(controller.audioConfig.bitrate, AudioBitrate.kbps320);

      controller.setAudioBitrate(AudioBitrate.kbps256);
      expect(controller.audioConfig.bitrate, AudioBitrate.kbps256);

      controller.setAudioFormat(AudioFormat.m4a);
      expect(controller.audioConfig.format, AudioFormat.m4a);

      controller.setEmbedThumbnail(false);
      expect(controller.audioConfig.embedThumbnail, isFalse);

      controller.setEmbedMetadata(false);
      expect(controller.audioConfig.embedMetadata, isFalse);

      controller.applyAudioPreset(AudioConfig.podcast);
      expect(controller.audioConfig.bitrate, AudioBitrate.kbps192);
      expect(controller.audioConfig.format, AudioFormat.mp3);
      expect(controller.audioConfig.embedThumbnail, isTrue);
    });

    test('startDownload forwards audioConfig to download service', () async {
      const video = VideoInfo(
        id: 'vid-audio',
        title: 'Audio Test',
        formats: [
          VideoFormat(formatId: '1', height: 720, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);
      controller.applyAudioPreset(AudioConfig.studioMusic);
      await controller.startDownload(video);

      expect(mockDownloadService.lastAudioConfig, isNotNull);
      expect(mockDownloadService.lastAudioConfig?.bitrate, AudioBitrate.kbps320);
      expect(mockDownloadService.lastAudioConfig?.format, AudioFormat.mp3);
    });

    test('updates speedLimit and scheduleDelay state', () {
      expect(controller.speedLimit, SpeedLimit.unlimited);
      expect(controller.scheduleDelay, ScheduleDelay.none);

      controller.setSpeedLimit(SpeedLimit.mbps10);
      expect(controller.speedLimit, SpeedLimit.mbps10);

      controller.setScheduleDelay(ScheduleDelay.min15);
      expect(controller.scheduleDelay, ScheduleDelay.min15);
    });

    test('startDownload forwards speedLimit to download service', () async {
      const video = VideoInfo(
        id: 'vid-speed',
        title: 'Speed Test',
        formats: [
          VideoFormat(formatId: '1', height: 720, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);
      controller.setSpeedLimit(SpeedLimit.mbps5);
      await controller.startDownload(video);

      expect(mockDownloadService.lastSpeedLimit, SpeedLimit.mbps5);
    });
  });
}
