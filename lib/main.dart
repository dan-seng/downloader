import 'package:flutter/material.dart';
import 'controllers/download_controller.dart';
import 'controllers/video_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'services/download_service.dart';
import 'services/process_service.dart';
import 'services/storage_service.dart';
import 'services/ytdlp_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize infrastructure and services
  const processService = SystemProcessService();
  final ytDlpService = YtDlpService(processService: processService);
  final downloadService = DownloadService(processService: processService);
  const storageService = StorageService();

  // Initialize business controllers
  final videoController = VideoController(ytDlpService: ytDlpService);
  final downloadController = DownloadController(
    downloadService: downloadService,
    storageService: storageService,
  );

  final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  runApp(VideoDownloaderApp(
    videoController: videoController,
    downloadController: downloadController,
    themeModeNotifier: themeModeNotifier,
  ));
}

class VideoDownloaderApp extends StatelessWidget {
  final VideoController videoController;
  final DownloadController downloadController;
  final ValueNotifier<ThemeMode>? themeModeNotifier;

  const VideoDownloaderApp({
    super.key,
    required this.videoController,
    required this.downloadController,
    this.themeModeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = themeModeNotifier ?? ValueNotifier<ThemeMode>(ThemeMode.system);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Video Downloader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: HomeScreen(
            videoController: videoController,
            downloadController: downloadController,
            themeModeNotifier: notifier,
          ),
        );
      },
    );
  }
}
