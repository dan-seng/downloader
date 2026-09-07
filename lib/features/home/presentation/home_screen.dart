import 'package:flutter/material.dart';
import '../../../controllers/video_controller.dart';
import '../widgets/error_display_card.dart';
import '../widgets/url_input_bar.dart';
import '../widgets/video_preview_card.dart';

/// The main screen allowing users to paste a URL, analyze it via yt-dlp,
/// and preview metadata.
class HomeScreen extends StatelessWidget {
  final VideoController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.download_for_offline,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Video Downloader',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () => controller.clear(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Header
                Text(
                  'Analyze Media',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paste a video or stream URL to inspect available qualities and formats.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // URL Input Bar
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    return UrlInputBar(
                      isLoading: controller.isLoading,
                      onAnalyze: (url) => controller.analyzeUrl(url),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Main Content Area (Error, Loading, Video Preview, or Placeholder)
                Expanded(
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (controller.errorMessage != null) ...[
                              ErrorDisplayCard(
                                errorMessage: controller.errorMessage!,
                                onDismiss: controller.clearError,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (controller.isLoading) ...[
                              _buildLoadingState(context),
                            ] else if (controller.currentVideo != null) ...[
                              VideoPreviewCard(videoInfo: controller.currentVideo!),
                            ] else ...[
                              _buildEmptyState(context),
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
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Analyzing video with yt-dlp...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching metadata, stream formats, and audio options',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No video analyzed yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a video link above and click Analyze to preview details.',
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
}
