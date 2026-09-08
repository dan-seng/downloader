import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
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

  @override
  Future<void> startDownload({
    required VideoInfo video,
    required QualityOption quality,
    required String destinationDirectory,
    required DownloadProgressCallback onProgress,
  }) async {
    downloadStarted = true;
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
  });
}
