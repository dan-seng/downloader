import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/features/home/presentation/mobile_main_screen.dart';
import 'package:video_downloader/models/download_archive_item.dart';
import 'package:video_downloader/models/video_format.dart';
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
      id: 'test-vid-1',
      title: 'Awesome Mobile Test Video',
      webpageUrl: url,
      uploader: 'Flutter Dev Channel',
      duration: const Duration(minutes: 3, seconds: 45),
      formats: const [
        VideoFormat(formatId: '137', extension: 'mp4', resolution: '1080p', width: 1920, height: 1080),
        VideoFormat(formatId: '22', extension: 'mp4', resolution: '720p', width: 1280, height: 720),
        VideoFormat(formatId: '140', extension: 'm4a', resolution: 'audio only', formatNote: 'medium audio'),
      ],
    );
  }
}

class MockStorageService extends StorageService {
  @override
  Future<String> getDefaultDownloadsDirectory() async => '/fake/downloads';

  @override
  Future<Map<String, String>> getQuickDirectories() async => {'Downloads': '/fake/downloads'};
}

class MockArchiveService extends ArchiveService {
  MockArchiveService() : super(customStoragePath: '/fake/archive.json');

  @override
  Future<List<DownloadArchiveItem>> loadArchive() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoController videoCtrl;
  late DownloadController dlCtrl;
  late ValueNotifier<ThemeMode> themeNotifier;

  setUp(() {
    videoCtrl = VideoController(ytDlpService: MockYtDlpService());
    dlCtrl = DownloadController(
      downloadService: DownloadService(),
      storageService: MockStorageService(),
      archiveService: MockArchiveService(),
    );
    themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  });

  tearDown(() {
    videoCtrl.dispose();
    dlCtrl.dispose();
    themeNotifier.dispose();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: MobileMainScreen(
        videoController: videoCtrl,
        downloadController: dlCtrl,
        themeModeNotifier: themeNotifier,
      ),
    );
  }

  group('MobileMainScreen Tests', () {
    testWidgets('renders all 4 navigation destinations in NavigationBar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Downloader'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('switches between tabs smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initial tab is Downloader
      expect(find.text('Paste video link or playlist...'), findsOneWidget);

      // Switch to Downloads tab
      await tester.tap(find.text('Downloads'));
      await tester.pumpAndSettle();
      expect(find.text('No Active Downloads'), findsOneWidget);

      // Switch to Library tab
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Media Vault'), findsOneWidget);
      expect(find.text('Media Vault is Empty'), findsOneWidget);

      // Switch to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Download Directory'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('displays loaded video card and format selector on downloader tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Simulate analyzed video
      final video = await MockYtDlpService().fetchVideoInfo('https://youtube.com/watch?v=test123');
      dlCtrl.setVideo(video);
      await videoCtrl.analyzeUrl('https://youtube.com/watch?v=test123');
      await tester.pumpAndSettle();

      expect(find.text('Awesome Mobile Test Video'), findsOneWidget);
      expect(find.text('Flutter Dev Channel'), findsOneWidget);
      expect(find.text('Format: Video'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsWidgets);
    });

    testWidgets('opens format bottom sheet and switches between video and audio smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final video = await MockYtDlpService().fetchVideoInfo('https://youtube.com/watch?v=test123');
      dlCtrl.setVideo(video);
      await videoCtrl.analyzeUrl('https://youtube.com/watch?v=test123');
      await tester.pumpAndSettle();

      // Tap Change to open format bottom sheet
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('Select Quality & Format'), findsOneWidget);
      expect(find.text('Video (MP4)'), findsOneWidget);
      expect(find.text('Audio (MP3)'), findsOneWidget);

      // Switch to Audio mode
      await tester.tap(find.text('Audio (MP3)'));
      await tester.pumpAndSettle();

      expect(find.text('MP3 · 320 kbps'), findsOneWidget);
      expect(find.text('M4A · AAC'), findsOneWidget);

      // Confirm selection
      await tester.tap(find.text('Confirm Selection'));
      await tester.pumpAndSettle();

      expect(find.text('Select Quality & Format'), findsNothing);
    });
  });
}
