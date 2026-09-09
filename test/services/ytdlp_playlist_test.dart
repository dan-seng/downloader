import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class _MockProcessService implements ProcessService {
  final Map<String, dynamic> mockJson;

  _MockProcessService(this.mockJson);

  @override
  Future<io.ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    return io.ProcessResult(
      1234,
      0,
      jsonEncode(mockJson),
      '',
    );
  }

  @override
  Future<io.Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('YtDlpService Playlist Support', () {
    test('isPlaylistUrl correctly identifies playlist indicators', () {
      final service = YtDlpService();

      expect(service.isPlaylistUrl('https://www.youtube.com/playlist?list=PL123'), isTrue);
      expect(service.isPlaylistUrl('https://www.youtube.com/watch?v=abc&list=PL123'), isTrue);
      expect(service.isPlaylistUrl('https://soundcloud.com/artist/sets/my-album'), isTrue);
      expect(service.isPlaylistUrl('https://www.youtube.com/watch?v=single_video'), isFalse);
    });

    test('fetchPlaylistInfo returns parsed PlaylistInfo', () async {
      final mockData = {
        'id': 'PL_test',
        'title': 'Test Playlist',
        'uploader': 'Test Creator',
        '_type': 'playlist',
        'entries': [
          {'id': 'v1', 'title': 'First Song', 'duration': 120},
          {'id': 'v2', 'title': 'Second Song', 'duration': 240},
        ],
      };

      final service = YtDlpService(processService: _MockProcessService(mockData));
      final playlist = await service.fetchPlaylistInfo('https://www.youtube.com/playlist?list=PL_test');

      expect(playlist.id, equals('PL_test'));
      expect(playlist.title, equals('Test Playlist'));
      expect(playlist.uploader, equals('Test Creator'));
      expect(playlist.totalCount, equals(2));
      expect(playlist.items[0].title, equals('First Song'));
      expect(playlist.items[1].title, equals('Second Song'));
    });
  });
}
