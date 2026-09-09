import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/models/audio_config.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/playlist_info.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/speed_limit.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/storage_service.dart';

class _MockDownloadService extends DownloadService {
  final List<String> downloadedVideoIds = [];
  bool shouldFailSecond = false;

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
    if (shouldFailSecond && video.id == 'item_2') {
      throw Exception('Network timeout on item 2');
    }
    downloadedVideoIds.add(video.id);
    final task = DownloadTask(
      id: video.id,
      url: video.webpageUrl ?? 'https://example.com',
      title: video.title,
      status: DownloadStatus.completed,
      progress: 1.0,
      destinationPath: '$destinationDirectory/${video.title}.mp4',
    );
    onProgress(task);
  }

  @override
  Future<void> cancelCurrentDownload() async {}
}

class _MockStorageService extends StorageService {
  @override
  Future<String> getDefaultDownloadsDirectory() async => '/downloads/path';
}

void main() {
  group('DownloadController Batch & Playlist Queue', () {
    test('setPlaylist initializes batch quality profiles', () {
      final controller = DownloadController();
      final playlist = PlaylistInfo(
        id: 'p1',
        title: 'Cyberpunk Soundscapes',
        items: [
          PlaylistItem(id: 'i1', url: 'https://v1', title: 'Track 1'),
          PlaylistItem(id: 'i2', url: 'https://v2', title: 'Track 2'),
        ],
      );

      controller.setPlaylist(playlist);
      expect(controller.availableQualities.length, equals(5));
      expect(controller.selectedQuality?.id, equals('1080p'));
      expect(controller.consoleLogs.any((l) => l.contains('Cyberpunk Soundscapes')), isTrue);
    });

    test('startBatchDownload downloads selected items sequentially and handles failure resiliently', () async {
      final mockDl = _MockDownloadService()..shouldFailSecond = true;
      final mockStorage = _MockStorageService();
      final controller = DownloadController(
        downloadService: mockDl,
        storageService: mockStorage,
      );

      final playlist = PlaylistInfo(
        id: 'p1',
        title: 'Album 2026',
        items: [
          PlaylistItem(id: 'item_1', url: 'https://item1', title: 'Song 1', isSelected: true),
          PlaylistItem(id: 'item_2', url: 'https://item2', title: 'Song 2', isSelected: true),
          PlaylistItem(id: 'item_3', url: 'https://item3', title: 'Song 3', isSelected: true),
          PlaylistItem(id: 'item_4', url: 'https://item4', title: 'Song 4', isSelected: false), // Deselected
        ],
      );

      controller.setPlaylist(playlist);
      await controller.startBatchDownload(playlist);

      expect(controller.batchTotalCount, equals(3));
      expect(controller.batchQueue[0].status, equals(DownloadStatus.completed));
      expect(controller.batchQueue[1].status, equals(DownloadStatus.failed));
      expect(controller.batchQueue[2].status, equals(DownloadStatus.completed));

      expect(mockDl.downloadedVideoIds, containsAll(['item_1', 'item_3']));
      expect(mockDl.downloadedVideoIds.contains('item_4'), isFalse);
      expect(controller.batchCompletedCount, equals(2));
      expect(controller.isBatchRunning, isFalse);
    });

    test('cancelBatch cancels active queue and marks remaining as cancelled', () async {
      final controller = DownloadController(
        downloadService: _MockDownloadService(),
        storageService: _MockStorageService(),
      );

      final playlist = PlaylistInfo(
        id: 'p1',
        title: 'Cancelled Album',
        items: [
          PlaylistItem(id: 'c1', url: 'https://c1', title: 'C1'),
          PlaylistItem(id: 'c2', url: 'https://c2', title: 'C2'),
        ],
      );

      controller.setPlaylist(playlist);
      // Trigger start and immediate cancel
      controller.startBatchDownload(playlist);
      await controller.cancelBatch();

      expect(controller.isBatchRunning, isFalse);
      expect(controller.consoleLogs.any((l) => l.contains('cancel requested')), isTrue);
    });
  });
}
