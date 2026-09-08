import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/video_info.dart';

/// SPIDEY deck card presenting video metadata, thumbnail, duration, stream counts.
class VideoPreviewCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoPreviewCard({
    super.key,
    required this.videoInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(context, bgRaised, borderColor, textDim, isDark),
          const SizedBox(width: 18),

          // Video Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  videoInfo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 4),
                if (videoInfo.uploader != null && videoInfo.uploader!.isNotEmpty)
                  Text(
                    videoInfo.uploader!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: textDim,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPill(
                      context,
                      icon: Icons.schedule_rounded,
                      label: videoInfo.formattedDuration,
                    ),
                    _buildPill(
                      context,
                      icon: Icons.layers_outlined,
                      label: '${videoInfo.formats.length} streams available',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    Color bgRaised,
    Color borderColor,
    Color textDim,
    bool isDark,
  ) {
    return SizedBox(
      width: 180,
      height: 101, // 16:9 ratio
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgRaised,
              border: Border.all(color: borderColor),
            ),
            child: videoInfo.thumbnail != null && videoInfo.thumbnail!.isNotEmpty
                ? Image.network(
                    videoInfo.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(Icons.play_arrow, color: textDim, size: 28),
                    ),
                  )
                : Center(
                    child: Icon(Icons.play_arrow, color: textDim, size: 28),
                  ),
          ),

          // Duration badge bottom right
          if (videoInfo.duration != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                color: Colors.black.withValues(alpha: 0.8),
                child: Text(
                  videoInfo.formattedDuration,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: borderLit),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SpideyColors.spideyRed),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textNorm,
            ),
          ),
        ],
      ),
    );
  }
}
