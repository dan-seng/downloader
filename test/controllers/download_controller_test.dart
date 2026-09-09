import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/models/audio_config.dart';
import 'package:video_downloader/models/download_archive_item.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/speed_limit.dart';
import 'package:video_downloader/models/time_range_clip.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/archive_service.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/storage_service.dart';

class MockStorageService extends StorageService {
  String? openedDirectory;

  @override
  Future<String> getDefaultDownloadsDirectory() async => '/fake/downloads';

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async =>
      '/custom/path';

  @override
  Future<void> openDirectory(String directoryPath) async {
    openedDirectory = directoryPath;
  }

  @override
  Future<Map<String, String>> getQuickDirectories() async => {
        'Downloads': '/fake/downloads',
        'Videos': '/fake/videos',
      };
}

class MockDownloadService extends DownloadService {
  bool downloadStarted = false;
  bool downloadCancelled = false;
  AudioConfig? lastAudioConfig;
  SpeedLimit? lastSpeedLimit;
  TimeRangeClip? lastClip;

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
    downloadStarted = true;
    lastAudioConfig = audioConfig;
    lastSpeedLimit = speedLimit;
    lastClip = clip;
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

class MockArchiveService extends ArchiveService {
  final List<DownloadArchiveItem> items = [];

  MockArchiveService() : super(customStoragePath: '/fake/archive.json');

  @override
  Future<List<DownloadArchiveItem>> loadArchive() async {
    return List.from(items);
  }

  @override
  Future<void> saveItem(DownloadArchiveItem item) async {
    items.removeWhere((it) => it.id == item.id);
    items.insert(0, item);
  }

  @override
  Future<bool> deleteItem(String id, {bool deleteFileFromDisk = false}) async {
    final before = items.length;
    items.removeWhere((it) => it.id == id);
    return items.length < before;
  }

  @override
  Future<int> clearMissing() async {
    final before = items.length;
    items.removeWhere((it) => !it.fileExists);
    return before - items.length;
  }
}

void main() {
  group('DownloadController', () {
    late MockDownloadService mockDownloadService;
    late MockStorageService mockStorageService;
    late MockArchiveService mockArchiveService;
    late DownloadController controller;

    setUp(() {
      mockDownloadService = MockDownloadService();
      mockStorageService = MockStorageService();
      mockArchiveService = MockArchiveService();
      controller = DownloadController(
        downloadService: mockDownloadService,
        storageService: mockStorageService,
        archiveService: mockArchiveService,
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

    test('setDownloadDirectory updates directory and adds console log', () {
      controller.setDownloadDirectory('/custom/new_path');
      expect(controller.downloadDirectory, equals('/custom/new_path'));
      expect(controller.consoleLogs.last, contains('destination folder set: /custom/new_path'));
    });

    test('openDownloadDirectory calls storageService openDirectory', () async {
      controller.setDownloadDirectory('/custom/folder');
      await controller.openDownloadDirectory();
      expect(mockStorageService.openedDirectory, equals('/custom/folder'));
    });

    test('getQuickDirectories returns presets', () async {
      final dirs = await controller.getQuickDirectories();
      expect(dirs['Downloads'], equals('/fake/downloads'));
      expect(dirs['Videos'], equals('/fake/videos'));
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

    test('setVideo initializes clip bounds from video duration', () {
      const video = VideoInfo(
        id: 'vid-clip',
        title: 'Clip Video',
        duration: Duration(minutes: 5),
        formats: [],
      );

      controller.setVideo(video);
      expect(controller.clip.isEnabled, isFalse);
      expect(controller.clip.start, Duration.zero);
      expect(controller.clip.end, const Duration(minutes: 5));

      controller.setVideo(null);
      expect(controller.clip.isEnabled, isFalse);
      expect(controller.clip.end, isNull);
    });

    test('updates clip state and presets', () {
      controller.toggleClip(true);
      expect(controller.clip.isEnabled, isTrue);

      controller.setClipRange(const Duration(seconds: 15), const Duration(seconds: 45));
      expect(controller.clip.start, const Duration(seconds: 15));
      expect(controller.clip.end, const Duration(seconds: 45));

      controller.applyClipPreset(const Duration(seconds: 60));
      expect(controller.clip.isEnabled, isTrue);
      expect(controller.clip.start, Duration.zero);
      expect(controller.clip.end, const Duration(seconds: 60));

      controller.resetClip(const Duration(minutes: 10));
      expect(controller.clip.isEnabled, isFalse);
      expect(controller.clip.start, Duration.zero);
      expect(controller.clip.end, const Duration(minutes: 10));
    });

    test('startDownload forwards clip when enabled and null when disabled', () async {
      const video = VideoInfo(
        id: 'vid-forward-clip',
        title: 'Clip Forward Video',
        formats: [
          VideoFormat(formatId: '1', height: 720, videoCodec: 'h264'),
        ],
      );

      controller.setVideo(video);
      controller.setClip(const TimeRangeClip(
        isEnabled: true,
        start: Duration(seconds: 10),
        end: Duration(seconds: 30),
      ));

      await controller.startDownload(video);
      expect(mockDownloadService.lastClip, isNotNull);
      expect(mockDownloadService.lastClip!.toSectionArgument(), '*00:10-00:30');

      controller.toggleClip(false);
      await controller.startDownload(video);
      expect(mockDownloadService.lastClip, isNull);
    });

    test('updates notificationsEnabled and service state', () {
      expect(controller.notificationsEnabled, isTrue);
      controller.setNotificationsEnabled(false);
      expect(controller.notificationsEnabled, isFalse);
      expect(controller.notificationService.notificationsEnabled, isFalse);
    });

    test('filteredArchiveItems filters by category, search query, and sort order', () async {
      final item1 = DownloadArchiveItem(
        id: 'arch-1',
        title: 'Cyberpunk 2077 Theme',
        url: 'https://youtube.com/watch?v=1',
        filePath: '/tmp/cyberpunk.mp3',
        formatLabel: 'MP3',
        fileSizeBytes: 15000000,
        completedAt: DateTime(2026, 9, 8, 12, 0),
        isAudioOnly: true,
      );

      final item2 = DownloadArchiveItem(
        id: 'arch-2',
        title: 'Flutter Desktop Tutorial',
        url: 'https://youtube.com/watch?v=2',
        filePath: '/tmp/flutter.mp4',
        formatLabel: '1080p',
        fileSizeBytes: 50000000,
        completedAt: DateTime(2026, 9, 9, 12, 0),
        isAudioOnly: false,
      );

      await controller.archiveService.saveItem(item1);
      await controller.archiveService.saveItem(item2);
      await controller.loadArchive();

      expect(controller.archiveItems.length, 2);

      // Search filter
      controller.setArchiveSearchQuery('cyberpunk');
      expect(controller.filteredArchiveItems.length, 1);
      expect(controller.filteredArchiveItems.first.id, 'arch-1');

      // Clear search and filter by video
      controller.setArchiveSearchQuery('');
      controller.setArchiveFilter(ArchiveFilter.video);
      expect(controller.filteredArchiveItems.length, 1);
      expect(controller.filteredArchiveItems.first.id, 'arch-2');

      // Filter by audio
      controller.setArchiveFilter(ArchiveFilter.audio);
      expect(controller.filteredArchiveItems.length, 1);
      expect(controller.filteredArchiveItems.first.id, 'arch-1');

      // Sort by size
      controller.setArchiveFilter(ArchiveFilter.all);
      controller.setArchiveSort(ArchiveSort.largest);
      expect(controller.filteredArchiveItems.first.id, 'arch-2'); // 50MB > 15MB
    });

    test('deleteArchiveItem removes item from archive', () async {
      final item = DownloadArchiveItem(
        id: 'del-1',
        title: 'To Delete',
        url: 'https://youtube.com/watch?v=del',
        filePath: '/tmp/del.mp4',
        formatLabel: '720p',
        fileSizeBytes: 1000,
        completedAt: DateTime.now(),
      );

      await controller.archiveService.saveItem(item);
      await controller.loadArchive();
      expect(controller.archiveItems.length, 1);

      final success = await controller.deleteArchiveItem('del-1');
      expect(success, isTrue);
      expect(controller.archiveItems, isEmpty);
    });
  });
}
