import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/download_task.dart';

/// Fun and modern download progress card with gradient indicators,
/// lively metric tags, and instant desktop file opening actions.
class DownloadProgressCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenFolder;
  final VoidCallback onDismiss;

  const DownloadProgressCard({
    super.key,
    required this.task,
    required this.onCancel,
    required this.onOpenFile,
    required this.onOpenFolder,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (task.status) {
      case DownloadStatus.downloading:
      case DownloadStatus.queued:
        return _buildDownloadingView(context, theme);
      case DownloadStatus.completed:
        return _buildCompletedView(context, theme);
      case DownloadStatus.failed:
        return _buildFailedView(context, theme);
      case DownloadStatus.cancelled:
        return _buildCancelledView(context, theme);
    }
  }

  Widget _buildDownloadingView(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    final percentVal = (task.progress * 100).clamp(0.0, 100.0);
    final percentStr = '${percentVal.toStringAsFixed(1)}%';

    String speedStr = '';
    if (task.speed != null && task.speed! > 0) {
      speedStr = '${Formatters.formatBytes(task.speed!.toInt())}/s';
    }

    String etaStr = '';
    if (task.eta != null && task.eta! > Duration.zero) {
      etaStr = Formatters.formatDuration(task.eta);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SpideyColors.spideyRed.withValues(alpha: 0.12),
                  border: Border.all(color: SpideyColors.spideyRedDim),
                ),
                child: Icon(
                  Icons.arrow_downward,
                  color: SpideyColors.spideyRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloading: ${task.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pulling high-speed video stream...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: textDim,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 16, color: SpideyColors.spideyRed),
                label: const Text('CANCEL', style: TextStyle(color: SpideyColors.spideyRed, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: task.progress > 0 ? task.progress : null,
              backgroundColor: isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised,
              valueColor: const AlwaysStoppedAnimation(SpideyColors.spideyRed),
            ),
          ),
          const SizedBox(height: 14),

          // Metrics row: Percentage, Speed, ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SpideyColors.spideyRed.withValues(alpha: 0.12),
                  border: Border.all(color: SpideyColors.spideyRedDim),
                ),
                child: Text(
                  percentStr,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SpideyColors.spideyRed,
                  ),
                ),
              ),
              Row(
                children: [
                  if (speedStr.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: SpideyColors.spideyBlue.withValues(alpha: 0.12),
                        border: Border.all(color: SpideyColors.spideyBlue),
                      ),
                      child: Text(
                        speedStr,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: SpideyColors.spideyBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (etaStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised,
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        'ETA: $etaStr',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textNorm,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: SpideyColors.spideyGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SpideyColors.spideyGreen.withValues(alpha: 0.12),
                  border: Border.all(color: SpideyColors.spideyGreen),
                ),
                child: const Icon(Icons.check_circle_rounded, color: SpideyColors.spideyGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DOWNLOAD COMPLETE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SpideyColors.spideyGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: textDim,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: textNorm),
                tooltip: 'Dismiss',
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onOpenFile,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('OPEN VIDEO', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SpideyColors.spideyGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onOpenFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('SHOW IN FOLDER', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: SpideyColors.spideyRedDim, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: SpideyColors.spideyRed, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DOWNLOAD FAILED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SpideyColors.spideyRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.errorMessage ?? 'Something went wrong while downloading.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: textNorm,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: SpideyColors.spideyRed),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledView(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline_rounded, size: 20, color: SpideyColors.spideyGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Download was cancelled.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: textNorm,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: textDim),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
