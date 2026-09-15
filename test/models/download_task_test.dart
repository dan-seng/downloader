import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/download_task.dart';

void main() {
  group('DownloadTask', () {
    test('default properties and status helpers', () {
      final task = DownloadTask(
        id: 'vid-123',
        url: 'https://youtube.com/watch?v=vid-123',
        title: 'Sample Video',
      );

      expect(task.id, equals('vid-123'));
      expect(task.title, equals('Sample Video'));
      expect(task.status, equals(DownloadStatus.queued));
      expect(task.isCompleted, isFalse);
      expect(task.isFailed, isFalse);
      expect(task.isCancelled, isFalse);
      expect(task.isDownloading, isFalse);
      expect(task.formattedSizeProgress, isEmpty);
      expect(task.formattedSpeed, equals('0.0 MB/s'));
      expect(task.formattedEta, equals('—:—'));
    });

    test('formattedSpeed formats KB/s and MB/s correctly', () {
      final task = DownloadTask(
        id: '1',
        url: 'url',
        title: 'title',
        speed: 512 * 1024, // 512 KB/s
      );
      expect(task.formattedSpeed, equals('512.0 KB/s'));

      task.speed = 2.5 * 1024 * 1024; // 2.5 MB/s
      expect(task.formattedSpeed, equals('2.5 MB/s'));
    });

    test('formattedSizeProgress formats transferred vs total bytes', () {
      final task = DownloadTask(
        id: '1',
        url: 'url',
        title: 'title',
        transferredBytes: 10 * 1024 * 1024,
        totalBytes: 50 * 1024 * 1024,
      );
      expect(task.formattedSizeProgress, equals('10.0 MB / 50.0 MB'));

      // When totalBytes is null or 0
      task.totalBytes = null;
      expect(task.formattedSizeProgress, equals('10.0 MB downloaded'));

      // When transferredBytes is 0 but totalBytes is known
      task.transferredBytes = 0;
      task.totalBytes = 25 * 1024 * 1024;
      expect(task.formattedSizeProgress, equals('0 B / 25.0 MB'));
    });

    test('status changes update boolean helpers', () {
      final task = DownloadTask(id: '1', url: 'u', title: 't');

      task.status = DownloadStatus.downloading;
      expect(task.isDownloading, isTrue);

      task.status = DownloadStatus.completed;
      expect(task.isCompleted, isTrue);

      task.status = DownloadStatus.failed;
      expect(task.isFailed, isTrue);

      task.status = DownloadStatus.cancelled;
      expect(task.isCancelled, isTrue);
    });
  });
}
