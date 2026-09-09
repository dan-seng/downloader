import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/download_archive_item.dart';

void main() {
  group('DownloadArchiveItem Model', () {
    test('formats file sizes accurately', () {
      final itemBytes = DownloadArchiveItem(
        id: '1',
        title: 'Small',
        url: 'https://youtu.be/1',
        filePath: '/tmp/small.mp3',
        formatLabel: 'MP3',
        fileSizeBytes: 500,
        completedAt: DateTime.now(),
      );
      expect(itemBytes.formattedSize, '500 B');

      final itemKb = itemBytes.copyWith(fileSizeBytes: 1024 * 50);
      expect(itemKb.formattedSize, '50.0 KB');

      final itemMb = itemBytes.copyWith(fileSizeBytes: 1024 * 1024 * 120);
      expect(itemMb.formattedSize, '120.0 MB');

      final itemGb = itemBytes.copyWith(fileSizeBytes: (1024 * 1024 * 1024 * 2.5).toInt());
      expect(itemGb.formattedSize, '2.5 GB');
    });

    test('extracts file names and extensions correctly', () {
      final item = DownloadArchiveItem(
        id: '2',
        title: 'Song',
        url: 'https://youtu.be/2',
        filePath: '/home/dan-seng/Music/Album/track01.flac',
        formatLabel: 'FLAC Lossless',
        fileSizeBytes: 25000000,
        completedAt: DateTime.now(),
        isAudioOnly: true,
      );

      expect(item.fileName, 'track01.flac');
      expect(item.fileExtension, 'FLAC');
    });

    test('toJson and fromJson preserves data fields', () {
      final date = DateTime(2026, 9, 9, 12, 30);
      final item = DownloadArchiveItem(
        id: 'item-3',
        title: 'Sample Video 4K',
        url: 'https://youtube.com/watch?v=abc',
        filePath: '/tmp/sample.mp4',
        formatLabel: '2160p (4K)',
        fileSizeBytes: 450000000,
        completedAt: date,
        isAudioOnly: false,
        playlistTitle: '4K Demos',
        qualityId: '2160p',
      );

      final json = item.toJson();
      expect(json['id'], 'item-3');
      expect(json['title'], 'Sample Video 4K');
      expect(json['playlistTitle'], '4K Demos');
      expect(json['qualityId'], '2160p');

      final restored = DownloadArchiveItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.formatLabel, item.formatLabel);
      expect(restored.playlistTitle, item.playlistTitle);
      expect(restored.qualityId, item.qualityId);
    });
  });
}
