import 'package:flutter/material.dart';
import '../../../models/video_info.dart';

/// Clean and modern card presenting video metadata, thumbnail,
/// duration, and stream counts.
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
            const SizedBox(width: 18),

            // Video Details
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
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Uploader Chip
                  if (videoInfo.uploader != null && videoInfo.uploader!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              videoInfo.uploader!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Stream statistics
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPill(
                        context,
                        icon: Icons.schedule_rounded,
                        label: videoInfo.formattedDuration,
                        color: theme.colorScheme.primary,
                      ),
                      _buildPill(
                        context,
                        icon: Icons.layers_outlined,
                        label: '${videoInfo.formats.length} streams available',
                        color: theme.colorScheme.secondary,
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
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 180,
        height: 101, // 16:9 ratio
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    videoInfo.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
                Icons.movie_filter_outlined,
                size: 38,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
