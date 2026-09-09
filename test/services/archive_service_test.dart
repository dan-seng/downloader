import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/download_archive_item.dart';
import 'package:video_downloader/services/archive_service.dart';

void main() {
  late io.Directory tempDir;
  late String storageFile;
  late ArchiveService service;

  setUp(() async {
    tempDir = await io.Directory.systemTemp.createTemp('spidey_archive_test_');
    storageFile = '${tempDir.path}/test_archive.json';
    service = ArchiveService(customStoragePath: storageFile);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ArchiveService', () {
    test('loads empty list when archive file does not exist', () async {
      final items = await service.loadArchive();
      expect(items, isEmpty);
    });

    test('saves items and loads them back sorted newest first', () async {
      final olderItem = DownloadArchiveItem(
        id: '1',
        title: 'Older Video',
        url: 'https://youtube.com/1',
        filePath: '/tmp/vid1.mp4',
        formatLabel: '1080p',
        fileSizeBytes: 1000,
        completedAt: DateTime(2026, 9, 8, 10, 0),
      );

      final newerItem = DownloadArchiveItem(
        id: '2',
        title: 'Newer Video',
        url: 'https://youtube.com/2',
        filePath: '/tmp/vid2.mp4',
        formatLabel: '720p',
        fileSizeBytes: 2000,
        completedAt: DateTime(2026, 9, 9, 10, 0),
      );

      await service.saveItem(olderItem);
      await service.saveItem(newerItem);

      final items = await service.loadArchive();
      expect(items.length, 2);
      expect(items[0].id, '2'); // Newer first
      expect(items[1].id, '1');
    });

    test('updates item if same ID is saved again', () async {
      final item = DownloadArchiveItem(
        id: '1',
        title: 'Initial Title',
        url: 'https://youtube.com/1',
        filePath: '/tmp/vid1.mp4',
        formatLabel: '1080p',
        fileSizeBytes: 1000,
        completedAt: DateTime.now(),
      );

      await service.saveItem(item);
      final updated = item.copyWith(title: 'Updated Title');
      await service.saveItem(updated);

      final items = await service.loadArchive();
      expect(items.length, 1);
      expect(items.first.title, 'Updated Title');
    });

    test('deleteItem removes item from archive and deletes disk file when requested', () async {
      final diskFile = io.File('${tempDir.path}/downloaded.mp4');
      diskFile.writeAsStringSync('dummy video content');
      expect(diskFile.existsSync(), isTrue);

      final item = DownloadArchiveItem(
        id: 'file-1',
        title: 'Downloaded File',
        url: 'https://youtube.com/watch?v=file1',
        filePath: diskFile.path,
        formatLabel: '1080p',
        fileSizeBytes: diskFile.lengthSync(),
        completedAt: DateTime.now(),
      );

      await service.saveItem(item);
      expect((await service.loadArchive()).length, 1);

      final deleted = await service.deleteItem('file-1', deleteFileFromDisk: true);
      expect(deleted, isTrue);

      expect((await service.loadArchive()), isEmpty);
      expect(diskFile.existsSync(), isFalse); // Deleted from disk
    });

    test('clearMissing purges items whose files no longer exist on disk', () async {
      final realFile = io.File('${tempDir.path}/exists.mp4');
      realFile.writeAsStringSync('exists');

      final existingItem = DownloadArchiveItem(
        id: 'exists',
        title: 'Existing Video',
        url: 'https://youtube.com/exists',
        filePath: realFile.path,
        formatLabel: '1080p',
        fileSizeBytes: 6,
        completedAt: DateTime.now(),
      );

      final missingItem = DownloadArchiveItem(
        id: 'missing',
        title: 'Missing Video',
        url: 'https://youtube.com/missing',
        filePath: '${tempDir.path}/does_not_exist.mp4',
        formatLabel: '1080p',
        fileSizeBytes: 999,
        completedAt: DateTime.now(),
      );

      await service.saveItem(existingItem);
      await service.saveItem(missingItem);
      expect((await service.loadArchive()).length, 2);

      final removedCount = await service.clearMissing();
      expect(removedCount, 1);

      final remaining = await service.loadArchive();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'exists');
    });
  });
}
