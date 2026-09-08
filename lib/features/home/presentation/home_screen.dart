import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../controllers/video_controller.dart';
import '../../downloads/widgets/download_location_bar.dart';
import '../../downloads/widgets/download_progress_card.dart';
import '../../downloads/widgets/quality_selector.dart';
import '../widgets/error_display_card.dart';
import '../widgets/url_input_bar.dart';
import '../widgets/video_preview_card.dart';

/// Modern, simplistic, and playful desktop screen for analyzing and downloading media.
class HomeScreen extends StatefulWidget {
  final VideoController videoController;
  final DownloadController downloadController;
  final ValueNotifier<ThemeMode>? themeModeNotifier;

  const HomeScreen({
    super.key,
    required this.videoController,
    required this.downloadController,
    this.themeModeNotifier,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.downloadController.initialize();
    widget.videoController.addListener(_onVideoControllerChanged);
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_onVideoControllerChanged);
    super.dispose();
  }

  void _onVideoControllerChanged() {
    final video = widget.videoController.currentVideo;
    widget.downloadController.setVideo(video);
  }

  void _toggleTheme() {
    final notifier = widget.themeModeNotifier;
    if (notifier == null) return;

    if (notifier.value == ThemeMode.dark) {
      notifier.value = ThemeMode.light;
    } else if (notifier.value == ThemeMode.light) {
      notifier.value = ThemeMode.dark;
    } else {
      // If system, toggle based on current brightness
      final isDark = Theme.of(context).brightness == Brightness.dark;
      notifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Sleek Desktop Sidebar Rail
          _buildSidebarRail(context, isDark),

          // Vertical divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),

          // Main View Content
          Expanded(
            child: _selectedNavIndex == 0
                ? _buildDownloaderView(context)
                : _buildComingSoonView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarRail(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: 80,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 20),

          // App Logo / Brand Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Nav Item: Downloader
          _buildNavButton(
            context,
            icon: Icons.download_rounded,
            label: 'Get',
            isSelected: _selectedNavIndex == 0,
            onTap: () => setState(() => _selectedNavIndex = 0),
          ),
          const SizedBox(height: 12),

          // Nav Item: History / Library
          _buildNavButton(
            context,
            icon: Icons.history_rounded,
            label: 'History',
            isSelected: _selectedNavIndex == 1,
            badge: 'Soon',
            onTap: () => setState(() => _selectedNavIndex = 1),
          ),

          const Spacer(),

          // Theme Switcher Button
          IconButton(
            onPressed: _toggleTheme,
            tooltip: isDark ? 'Switch to Light mode' : 'Switch to Dark mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloaderView(BuildContext context) {
    final theme = Theme.of(context);
    final videoCtrl = widget.videoController;
    final dlCtrl = widget.downloadController;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title and Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Video Downloader',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'v1.0',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grab your favorite videos and audio tracks at top speed.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (videoCtrl.hasVideo)
                    TextButton.icon(
                      onPressed: dlCtrl.isDownloading
                          ? null
                          : () {
                              videoCtrl.clear();
                              dlCtrl.dismissTask();
                            },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('New Download'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Input Bar
              ListenableBuilder(
                listenable: Listenable.merge([videoCtrl, dlCtrl]),
                builder: (context, _) {
                  return UrlInputBar(
                    isLoading: videoCtrl.isLoading,
                    onAnalyze: (url) => videoCtrl.analyzeUrl(url),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Dynamic Main Body
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([videoCtrl, dlCtrl]),
                  builder: (context, _) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (videoCtrl.errorMessage != null) ...[
                            ErrorDisplayCard(
                              errorMessage: videoCtrl.errorMessage!,
                              onDismiss: videoCtrl.clearError,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (dlCtrl.errorMessage != null) ...[
                            ErrorDisplayCard(
                              errorMessage: dlCtrl.errorMessage!,
                              onDismiss: () => dlCtrl.dismissTask(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (videoCtrl.isLoading) ...[
                            _buildLoadingCard(context),
                          ] else if (videoCtrl.currentVideo != null) ...[
                            // Video Metadata Card
                            VideoPreviewCard(videoInfo: videoCtrl.currentVideo!),
                            const SizedBox(height: 16),

                            // Quality and Download Options Card
                            _buildDownloadActionCard(context, videoCtrl, dlCtrl),
                            const SizedBox(height: 16),

                            // Real-Time Progress Card
                            if (dlCtrl.currentTask != null) ...[
                              DownloadProgressCard(
                                task: dlCtrl.currentTask!,
                                onCancel: dlCtrl.cancelDownload,
                                onOpenFile: dlCtrl.openFile,
                                onOpenFolder: dlCtrl.openFolder,
                                onDismiss: dlCtrl.dismissTask,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ] else ...[
                            _buildFunEmptyState(context),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadActionCard(
    BuildContext context,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final isDownloading = dlCtrl.isDownloading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quality Selector
            QualitySelector(
              options: dlCtrl.availableQualities,
              selectedOption: dlCtrl.selectedQuality,
              onSelected: dlCtrl.selectQuality,
              isEnabled: !isDownloading,
            ),
            const SizedBox(height: 18),

            // Download Location
            DownloadLocationBar(
              directoryPath: dlCtrl.downloadDirectory,
              onBrowse: dlCtrl.pickDirectory,
              isEnabled: !isDownloading,
            ),
            const SizedBox(height: 20),

            // Big Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isDownloading
                    ? null
                    : () => dlCtrl.startDownload(videoCtrl.currentVideo!),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 22),
                label: Text(
                  isDownloading ? 'Downloading...' : 'Start Download',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 22),
            Text(
              'Analyzing video...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inspecting stream resolutions and audio formats with yt-dlp',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56.0, horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 44,
                color: primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ready when you are!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Copy any video URL to your clipboard and paste it above to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 56,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Download History',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Persistent library & completed downloads history coming in Phase 6!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
