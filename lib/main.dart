import 'package:flutter/material.dart';
import 'controllers/download_controller.dart';
import 'controllers/video_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'services/download_service.dart';
import 'services/engine_service.dart';
import 'services/process_service.dart';
import 'services/storage_service.dart';
import 'services/ytdlp_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize infrastructure and services
  const processService = SystemProcessService();
  final engineService = EngineService(processService: processService);
  final ytDlpService = YtDlpService(
    processService: processService,
    engineService: engineService,
  );
  final downloadService = DownloadService(
    processService: processService,
    engineService: engineService,
  );
  const storageService = StorageService();

  // Initialize business controllers
  final videoController = VideoController(ytDlpService: ytDlpService);
  final downloadController = DownloadController(
    downloadService: downloadService,
    storageService: storageService,
    engineService: engineService,
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
          title: 'VINX',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOutCubic,
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
