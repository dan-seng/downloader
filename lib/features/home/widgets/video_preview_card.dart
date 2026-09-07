import 'package:flutter/material.dart';
import '../../../models/video_info.dart';

/// Card presenting analyzed video metadata including thumbnail, title,
/// duration, and available format count.
class VideoPreviewCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoPreviewCard({
    super.key,
    required this.videoInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Duration Overlay
            _buildThumbnail(context),
            const SizedBox(width: 20),

            // Metadata Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    videoInfo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Uploader
                  if (videoInfo.uploader != null && videoInfo.uploader!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            videoInfo.uploader!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Badges: Duration and Formats
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        context,
                        icon: Icons.timer_outlined,
                        label: videoInfo.formattedDuration,
                      ),
                      _buildBadge(
                        context,
                        icon: Icons.video_collection_outlined,
                        label: '${videoInfo.formats.length} formats available',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 180,
        height: 101, // 16:9 aspect ratio
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoInfo.thumbnail != null && videoInfo.thumbnail!.isNotEmpty)
              Image.network(
                videoInfo.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildThumbnailPlaceholder(context),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildThumbnailPlaceholder(context, isLoading: true);
                },
              )
            else
              _buildThumbnailPlaceholder(context),

            // Duration badge at bottom right
            if (videoInfo.duration != null)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    videoInfo.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(BuildContext context, {bool isLoading = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.video_library,
                size: 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
