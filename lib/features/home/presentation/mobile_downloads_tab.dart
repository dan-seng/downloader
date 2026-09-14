import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/download_task.dart';

/// Dedicated mobile transfers screen showing active downloads, live speed, progress, and cancel actions.
class MobileDownloadsTab extends StatelessWidget {
  final DownloadController downloadController;
  final VoidCallback onNavigateToDownloader;

  const MobileDownloadsTab({
    super.key,
    required this.downloadController,
    required this.onNavigateToDownloader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final activeColor = isDark ? Colors.white : Colors.black;

    final dlCtrl = downloadController;
    final isDownloading = dlCtrl.isDownloading;
    final currentTask = dlCtrl.currentTask;
    final activeTasks = dlCtrl.activeTasks;
    final recentQueue = dlCtrl.recentQueue;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Downloads Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Active Downloads',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textHi,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDownloading
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeTasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDownloading
                            ? (isDark ? Colors.black : Colors.white)
                            : textDim,
                      ),
                    ),
                  ),
                ],
              ),
              if (isDownloading)
                TextButton.icon(
                  onPressed: () => dlCtrl.cancelDownload(),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Cancel All',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Active Download Card
          if (isDownloading && currentTask != null)
            _buildActiveTaskCard(
              context,
              isDark,
              currentTask,
              dlCtrl,
              textHi,
              textNorm,
              textDim,
              borderColor,
              bgPanel,
              bgRaised,
              activeColor,
            )
          else if (!isDownloading)
            _buildEmptyState(context, isDark, textHi, textDim, bgPanel, bgRaised, borderColor, activeColor),

          const SizedBox(height: 24),

          // Recent / Completed Section
          if (recentQueue.isNotEmpty) ...[
            Text(
              'Session Queue (${recentQueue.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textHi,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentQueue.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = recentQueue[index];
                return _buildRecentQueueTile(
                  context,
                  isDark,
                  task,
                  dlCtrl,
                  textHi,
                  textNorm,
                  textDim,
                  borderColor,
                  bgPanel,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTaskCard(
    BuildContext context,
    bool isDark,
    DownloadTask task,
    DownloadController dlCtrl,
    Color textHi,
    Color textNorm,
    Color textDim,
    Color borderColor,
    Color bgPanel,
    Color bgRaised,
    Color activeColor,
  ) {
    final progress = task.progress.clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textHi,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (dlCtrl.isBatchRunning)
                      Text(
                        'Track ${dlCtrl.batchCurrentIndex + 1} of ${dlCtrl.batchTotalCount} in Playlist',
                        style: const TextStyle(fontSize: 11.5, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                      )
                    else
                      Text(
                        task.formatId ?? 'Standard Quality',
                        style: TextStyle(fontSize: 11.5, color: textDim),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: bgRaised,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),

          const SizedBox(height: 12),

          // Speed, Percent & ETA row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: activeColor),
                  const SizedBox(width: 4),
                  Text(
                    task.formattedSpeed,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: textHi,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textHi,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: textDim),
                  const SizedBox(width: 4),
                  Text(
                    'ETA: ${task.formattedEta}',
                    style: TextStyle(fontSize: 11.5, color: textDim),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Cancel Button
          OutlinedButton.icon(
            onPressed: () => dlCtrl.cancelDownload(),
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
            label: const Text(
              'Cancel Download',
              style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQueueTile(
    BuildContext context,
    bool isDark,
    DownloadTask task,
    DownloadController dlCtrl,
    Color textHi,
    Color textNorm,
    Color textDim,
    Color borderColor,
    Color bgPanel,
  ) {
    final isCompleted = task.status == DownloadStatus.completed;
    final isFailed = task.status == DownloadStatus.failed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : (isFailed ? Icons.error_rounded : Icons.cancel_rounded),
            size: 20,
            color: isCompleted
                ? Colors.green
                : (isFailed ? Colors.redAccent : Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCompleted
                      ? 'Saved to device'
                      : (isFailed ? (task.errorMessage ?? 'Download failed') : 'Cancelled'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? Colors.green : textDim,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted && task.destinationPath != null)
            IconButton(
              icon: Icon(Icons.folder_open_rounded, size: 18, color: textHi),
              onPressed: () => dlCtrl.openArchiveFolder(task.destinationPath!),
              tooltip: 'Show in Files',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textHi,
    Color textDim,
    Color bgPanel,
    Color bgRaised,
    Color borderColor,
    Color activeColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgRaised,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.downloading_rounded, size: 30, color: textDim),
          ),
          const SizedBox(height: 14),
          Text(
            'No Active Downloads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textHi,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'When you download media, live download speeds, progress bars, and ETA meters appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textDim, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onNavigateToDownloader,
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Add Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
