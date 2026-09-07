import 'package:flutter/material.dart';
import 'controllers/video_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'services/process_service.dart';
import 'services/ytdlp_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service layer with dynamic executable resolution
  const processService = SystemProcessService();
  final ytDlpService = YtDlpService(processService: processService);
  final videoController = VideoController(ytDlpService: ytDlpService);

  runApp(VideoDownloaderApp(videoController: videoController));
}

class VideoDownloaderApp extends StatelessWidget {
  final VideoController videoController;

  const VideoDownloaderApp({
    super.key,
    required this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: videoController),
    );
  }
}
