import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/playlist_info.dart';

void main() {
  group('PlaylistInfo and PlaylistItem Models', () {
    test('parses yt-dlp flat playlist JSON correctly', () {
      final sampleJson = {
        'id': 'PL12345',
        'title': 'Synthwave Chill Mix',
        'uploader': 'Retro Wave',
        'webpage_url': 'https://www.youtube.com/playlist?list=PL12345',
        'entries': [
          {
            'id': 'track1',
            'title': 'Midnight City',
            'duration': 245,
            'uploader': 'Retro Wave',
            'thumbnail': 'https://example.com/thumb1.jpg',
          },
          {
            'id': 'track2',
            'title': 'Neon Horizon',
            'duration': 180,
            'uploader': 'Retro Wave',
            'thumbnails': [
              {'url': 'https://example.com/thumb2_small.jpg'},
              {'url': 'https://example.com/thumb2_large.jpg'},
            ],
          },
        ],
      };

      final playlist = PlaylistInfo.fromJson(sampleJson);

      expect(playlist.id, equals('PL12345'));
      expect(playlist.title, equals('Synthwave Chill Mix'));
      expect(playlist.uploader, equals('Retro Wave'));
      expect(playlist.totalCount, equals(2));
      expect(playlist.selectedCount, equals(2));
      expect(playlist.isAllSelected, isTrue);
      expect(playlist.hasSelection, isTrue);

      final item1 = playlist.items[0];
      expect(item1.id, equals('track1'));
      expect(item1.title, equals('Midnight City'));
      expect(item1.duration, equals(const Duration(seconds: 245)));
      expect(item1.formattedDuration, equals('04:05'));
      expect(item1.thumbnail, equals('https://example.com/thumb1.jpg'));
      expect(item1.isSelected, isTrue);

      final item2 = playlist.items[1];
      expect(item2.id, equals('track2'));
      expect(item2.thumbnail, equals('https://example.com/thumb2_large.jpg'));
      expect(item2.formattedDuration, equals('03:00'));

      // Test selection manipulation
      item1.isSelected = false;
      expect(playlist.selectedCount, equals(1));
      expect(playlist.isAllSelected, isFalse);
      expect(playlist.hasSelection, isTrue);

      item2.isSelected = false;
      expect(playlist.selectedCount, equals(0));
      expect(playlist.hasSelection, isFalse);
    });

    test('handles empty or malformed entries gracefully', () {
      final emptyJson = {
        'id': 'empty',
        'title': 'Empty Playlist',
      };

      final playlist = PlaylistInfo.fromJson(emptyJson);
      expect(playlist.totalCount, equals(0));
      expect(playlist.selectedCount, equals(0));
      expect(playlist.hasSelection, isFalse);
      expect(playlist.isAllSelected, isFalse);
    });
  });
}
