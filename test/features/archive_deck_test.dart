import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/features/home/presentation/home_screen.dart';
import 'package:video_downloader/models/download_archive_item.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/archive_service.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockYtDlpService extends YtDlpService {
  @override
  bool isPlaylistUrl(String url) => false;

  @override
  Future<VideoInfo> fetchVideoInfo(String url) async {
    return VideoInfo(
      id: 're-vid-1',
      title: 'Re-Downloaded Video',
      webpageUrl: url,
      formats: const [],
    );
  }
}

class MockStorageService extends StorageService {
  String? openedFile;
  String? openedDirectory;

  @override
  Future<String> getDefaultDownloadsDirectory() async => '/fake/downloads';

  @override
  Future<Map<String, String>> getQuickDirectories() async => {
        'Downloads': '/fake/downloads',
      };

  @override
  Future<void> openFile(String filePath) async {
    openedFile = filePath;
  }

  @override
  Future<void> openDirectory(String directoryPath) async {
    openedDirectory = directoryPath;
  }
}

class MockArchiveService extends ArchiveService {
  final List<DownloadArchiveItem> items = [];

  MockArchiveService() : super(customStoragePath: '/fake/archive.json');

  @override
  Future<List<DownloadArchiveItem>> loadArchive() async => List.from(items);

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
  group('Archive Deck & Desktop Experience Widget Tests', () {
    late MockYtDlpService ytDlpService;
    late MockStorageService storageService;
    late MockArchiveService archiveService;
    late VideoController videoController;
    late DownloadController downloadController;

    setUp(() {
      ytDlpService = MockYtDlpService();
      storageService = MockStorageService();
      archiveService = MockArchiveService();
      videoController = VideoController(ytDlpService: ytDlpService);
      downloadController = DownloadController(
        downloadService: DownloadService(),
        storageService: storageService,
        archiveService: archiveService,
      );
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: HomeScreen(
          videoController: videoController,
          downloadController: downloadController,
        ),
      );
    }

    testWidgets('toggles between DECK and ARCHIVE views smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially on DECK view
      expect(find.byKey(const ValueKey('view_tab_deck')), findsOneWidget);
      expect(find.byKey(const ValueKey('view_tab_archive')), findsOneWidget);
      expect(find.text('ANALYZE'), findsOneWidget);

      // Switch to ARCHIVE view
      await tester.tap(find.byKey(const ValueKey('view_tab_archive')));
      await tester.pumpAndSettle();

      expect(find.text('DOWNLOAD ARCHIVE // MEDIA VAULT'), findsOneWidget);
      expect(find.text('NO ARCHIVED DOWNLOADS FOUND'), findsOneWidget);

      // Switch back to DECK view
      await tester.tap(find.byKey(const ValueKey('view_tab_deck')));
      await tester.pumpAndSettle();

      expect(find.text('ANALYZE'), findsOneWidget);
    });

    testWidgets('renders archived items, filters them, and opens files', (tester) async {
      final videoItem = DownloadArchiveItem(
        id: 'arch-vid',
        title: 'Cyberpunk Edgerunners 4K',
        url: 'https://youtube.com/watch?v=cyberpunk',
        filePath: '/fake/downloads/cyberpunk.mp4',
        formatLabel: '2160p (4K)',
        fileSizeBytes: 250000000,
        completedAt: DateTime.now(),
        isAudioOnly: false,
        fileExists: true,
      );

      final audioItem = DownloadArchiveItem(
        id: 'arch-aud',
        title: 'Synthwave FLAC Track',
        url: 'https://youtube.com/watch?v=synthwave',
        filePath: '/fake/downloads/synthwave.flac',
        formatLabel: 'FLAC Lossless',
        fileSizeBytes: 45000000,
        completedAt: DateTime.now(),
        isAudioOnly: true,
        fileExists: true,
      );

      await archiveService.saveItem(videoItem);
      await archiveService.saveItem(audioItem);
      await downloadController.loadArchive();

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Header shows item count
      expect(find.text('ARCHIVE (2)'), findsOneWidget);

      // Switch to Archive Deck
      await tester.tap(find.byKey(const ValueKey('view_tab_archive')));
      await tester.pumpAndSettle();

      expect(find.text('Cyberpunk Edgerunners 4K'), findsOneWidget);
      expect(find.text('Synthwave FLAC Track'), findsOneWidget);
      expect(find.text('2160P (4K)'), findsOneWidget);
      expect(find.text('FLAC LOSSLESS'), findsOneWidget);

      // Tap "OPEN FILE" on the video card (second card in the list)
      final openFileButtons = find.text('OPEN FILE');
      expect(openFileButtons, findsNWidgets(2));
      await tester.tap(openFileButtons.last);
      await tester.pumpAndSettle();
      expect(storageService.openedFile, '/fake/downloads/cyberpunk.mp4');

      // Filter by AUDIO
      await tester.tap(find.text('AUDIO (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Cyberpunk Edgerunners 4K'), findsNothing);
      expect(find.text('Synthwave FLAC Track'), findsOneWidget);
    });

    testWidgets('re-download button loads URL and navigates back to deck', (tester) async {
      final item = DownloadArchiveItem(
        id: 're-item',
        title: 'Re-Download Test Video',
        url: 'https://youtube.com/watch?v=redownload',
        filePath: '/fake/downloads/redownload.mp4',
        formatLabel: '1080p',
        fileSizeBytes: 1000000,
        completedAt: DateTime.now(),
      );

      await archiveService.saveItem(item);
      await downloadController.loadArchive();

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Go to Archive
      await tester.tap(find.byKey(const ValueKey('view_tab_archive')));
      await tester.pumpAndSettle();

      // Tap RE-DOWNLOAD
      await tester.tap(find.text('RE-DOWNLOAD'));
      await tester.pumpAndSettle();

      // Should have switched back to DECK view and loaded video
      expect(find.text('Re-Downloaded Video'), findsAtLeastNWidgets(1));
      expect(find.text('https://youtube.com/watch?v=redownload'), findsOneWidget);
    });

    testWidgets('toggles desktop notifications via header pill', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(downloadController.notificationsEnabled, isTrue);
      expect(find.text('NOTIF'), findsOneWidget);

      // Tap notification pill
      await tester.tap(find.byKey(const ValueKey('faceplate_notification_toggle')));
      await tester.pumpAndSettle();

      expect(downloadController.notificationsEnabled, isFalse);
      expect(find.text('MUTED'), findsOneWidget);
    });
  });
}
