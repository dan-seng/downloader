import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../controllers/video_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/audio_config.dart';
import '../../../models/download_task.dart';
import '../../../models/playlist_info.dart';
import '../../../models/quality_option.dart';
import '../../../models/speed_limit.dart';
import '../../downloads/widgets/vu_meter.dart';
import '../widgets/reel_spinner.dart';
import '../widgets/terminal_log_console.dart';
import '../widgets/web_corner_painter.dart';

/// SPIDEY_DLX — Web-Slinging Desktop Video Grabber Deck.
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
  late final TextEditingController _urlController;
  bool _isSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    widget.downloadController.initialize();
    widget.videoController.addListener(_onVideoControllerChanged);
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_onVideoControllerChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _onVideoControllerChanged() {
    if (widget.videoController.isPlaylist) {
      widget.downloadController.setPlaylist(widget.videoController.currentPlaylist);
    } else {
      widget.downloadController.setVideo(widget.videoController.currentVideo);
    }
  }

  void _toggleTheme() {
    final notifier = widget.themeModeNotifier;
    if (notifier == null) return;

    if (notifier.value == ThemeMode.dark) {
      notifier.value = ThemeMode.light;
    } else if (notifier.value == ThemeMode.light) {
      notifier.value = ThemeMode.dark;
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      notifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    }
  }

  void _onAnalyze() {
    final text = _urlController.text.trim();
    if (text.isNotEmpty) {
      widget.downloadController.addLog('\$ spidey-fetch $text');
      widget.videoController.analyzeUrl(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgDeep = isDark ? SpideyColors.darkBgDeep : SpideyColors.lightBgDeep;
    final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;

    return Scaffold(
      backgroundColor: bgDeep,
      body: SizedBox.expand(
        child: Container(
          color: bgPanel,
          child: Stack(
            children: [
              // Deck Layout Column
              ListenableBuilder(
                listenable: Listenable.merge([
                  widget.videoController,
                  widget.downloadController,
                ]),
                builder: (context, _) {
                  final videoCtrl = widget.videoController;
                  final dlCtrl = widget.downloadController;
                  final screenWidth = MediaQuery.of(context).size.width;
                  final sidebarWidth = screenWidth >= 1440
                      ? 300.0
                      : (screenWidth >= 1100 ? 270.0 : 250.0);

                  return Column(
                    children: [
                      // Header Faceplate
                      _buildFaceplate(context, isDark, videoCtrl, dlCtrl),

                      // Main Body Grid (Queue Column + Main Column)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left: Queue Sidebar (responsive width)
                            if (_isSidebarVisible) ...[
                              SizedBox(
                                width: sidebarWidth,
                                child: _buildQueueSidebar(context, isDark, videoCtrl, dlCtrl),
                              ),
                              // Vertical Divider
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: borderColor,
                              ),
                            ],

                            // Right: Main Deck Column
                            Expanded(
                              child: _buildMainDeck(context, isDark, videoCtrl, dlCtrl),
                            ),
                          ],
                        ),
                      ),

                      // Bottom: Subprocess Terminal Console
                      TerminalLogConsole(logs: dlCtrl.consoleLogs),
                    ],
                  );
                },
              ),

              // Spiderweb corner motif (rendered on top of the faceplate, like the HTML z-index:1)
              Positioned(
                top: -6,
                left: -6,
                width: 150,
                height: 150,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.12,
                    child: CustomPaint(
                      painter: WebCornerPainter(
                        strokeColor: isDark
                            ? SpideyColors.darkTextDim
                            : SpideyColors.lightTextDim,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceplate(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final isDownloading = dlCtrl.isDownloading;
    final isBatch = dlCtrl.isBatchRunning;
    final isFetching = videoCtrl.isLoading;
    final isDone = dlCtrl.currentTask?.status == DownloadStatus.completed;

    // Determine status text and dot color
    String statusText = 'IDLE';
    Color dotColor = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    if (isFetching) {
      statusText = 'FETCHING';
      dotColor = SpideyColors.spideyBlue;
    } else if (isBatch) {
      statusText = 'BATCH (${dlCtrl.batchCurrentIndex + 1}/${dlCtrl.batchQueue.length})';
      dotColor = SpideyColors.spideyRed;
    } else if (isDownloading) {
      statusText = 'DOWNLOADING';
      dotColor = SpideyColors.spideyRed;
    } else if (isDone) {
      statusText = 'COMPLETE';
      dotColor = SpideyColors.spideyGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand + Toggle Sidebar + Subtitle
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSidebarVisible ? Icons.menu_open : Icons.menu,
                  size: 20,
                  color: textDim,
                ),
                tooltip: _isSidebarVisible ? 'Hide Queue' : 'Show Queue',
                onPressed: _toggleSidebar,
              ),
              const SizedBox(width: 6),
              ReelSpinner(
                isSpinning: isDownloading,
                reelColor: isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit,
                spokeColor: SpideyColors.spideyRed,
                size: 26,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.2,
                        color: textHi,
                      ),
                      children: const [
                        TextSpan(text: 'SPIDEY'),
                        TextSpan(
                          text: '_DLX',
                          style: TextStyle(
                            color: SpideyColors.spideyRed,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'WEB-SLINGING VIDEO GRABBER · WIN / LINUX',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions: Throttle, Schedule, Theme Switcher & Status Pill
          Row(
            children: [
              // Bandwidth Limiter / Throttle Pill
              PopupMenuButton<SpeedLimit>(
                key: const ValueKey('faceplate_throttle_button'),
                tooltip: 'Bandwidth Limiter (Throttle)',
                initialValue: dlCtrl.speedLimit,
                onSelected: dlCtrl.setSpeedLimit,
                color: bgRaised,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (context) => SpeedLimit.values.map((limit) {
                  final isSelected = dlCtrl.speedLimit == limit;
                  return PopupMenuItem<SpeedLimit>(
                    value: limit,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            limit.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? SpideyColors.spideyRed : textHi,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 14, color: SpideyColors.spideyRed),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: bgWell,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dlCtrl.speedLimit.isThrottled
                          ? SpideyColors.spideyRed
                          : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⚡ ${dlCtrl.speedLimit.shortLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dlCtrl.speedLimit.isThrottled
                              ? SpideyColors.spideyRed
                              : (isDark ? SpideyColors.darkText : SpideyColors.lightText),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: textDim,
                      ),
                    ],
                  ),
                ),
              ),

              // Off-Peak Scheduling Pill
              PopupMenuButton<ScheduleDelay>(
                key: const ValueKey('faceplate_schedule_button'),
                tooltip: 'Off-Peak Delayed Queue',
                initialValue: dlCtrl.scheduleDelay,
                onSelected: dlCtrl.setScheduleDelay,
                color: bgRaised,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (context) => ScheduleDelay.values.map((delay) {
                  final isSelected = dlCtrl.scheduleDelay == delay;
                  return PopupMenuItem<ScheduleDelay>(
                    value: delay,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            delay.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? SpideyColors.spideyBlue : textHi,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 14, color: SpideyColors.spideyBlue),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: bgWell,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dlCtrl.scheduleDelay.isDelayed
                          ? SpideyColors.spideyBlue
                          : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⏱ ${dlCtrl.scheduleDelay.shortLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dlCtrl.scheduleDelay.isDelayed
                              ? SpideyColors.spideyBlue
                              : (isDark ? SpideyColors.darkText : SpideyColors.lightText),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: textDim,
                      ),
                    ],
                  ),
                ),
              ),

              // Theme Toggle Button
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _toggleTheme,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: bgWell,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDark ? '🌙 DARK' : '☀️ LIGHT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? SpideyColors.darkText : SpideyColors.lightText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgWell,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: [
                          if (statusText != 'IDLE')
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? SpideyColors.darkText : SpideyColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSidebar(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    if (videoCtrl.isPlaylist && videoCtrl.currentPlaylist != null) {
      final playlist = videoCtrl.currentPlaylist!;
      final totalCount = playlist.totalCount;

      return Container(
        color: bgWell,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Column Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'QUEUE — $totalCount TRACKS',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: textDim,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit,
                      ),
                    ),
                    child: Text(
                      '${playlist.selectedCount}/$totalCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textNorm,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Queue Items List
            Expanded(
              child: ListView.builder(
                itemCount: playlist.items.length,
                itemBuilder: (context, idx) {
                  final item = playlist.items[idx];
                  DownloadTask? task;
                  if (dlCtrl.batchQueue.isNotEmpty) {
                    try {
                      task = dlCtrl.batchQueue.firstWhere((t) => t.id == item.id);
                    } catch (_) {
                      task = null;
                    }
                  }

                  final isCurrentActive = dlCtrl.isBatchRunning && dlCtrl.batchCurrentIndex == idx;
                  final isItemDone = task?.status == DownloadStatus.completed;
                  final isItemFailed = task?.status == DownloadStatus.failed;

                  String tag;
                  if (isCurrentActive) {
                    tag = 'ACTIVE';
                  } else if (isItemDone) {
                    tag = 'DONE';
                  } else if (isItemFailed) {
                    tag = 'FAIL';
                  } else if (task?.status == DownloadStatus.queued) {
                    tag = 'QUEUED';
                  } else {
                    tag = item.formattedDuration;
                  }

                  return InkWell(
                    onTap: dlCtrl.isBatchRunning
                        ? null
                        : () => videoCtrl.togglePlaylistItem(idx),
                    child: _buildQueueItem(
                      index: (idx + 1).toString().padLeft(2, '0'),
                      title: item.title,
                      tag: tag,
                      meta: item.uploader ?? playlist.uploader ?? 'Track ${idx + 1}',
                      isActive: isCurrentActive,
                      isDone: isItemDone,
                      isDark: isDark,
                      isDimmed: !item.isSelected,
                    ),
                  );
                },
              ),
            ),

            // Bottom Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      dlCtrl.isBatchRunning
                          ? 'batch running'
                          : '${playlist.selectedCount} ready',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: textDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dlCtrl.isBatchRunning
                        ? '${dlCtrl.batchQueue.where((t) => t.status == DownloadStatus.queued).length} queued'
                        : '${playlist.totalCount - playlist.selectedCount} skipped',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textNorm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentVideo = videoCtrl.currentVideo;
    final recentQueue = dlCtrl.recentQueue;
    final totalCount = (currentVideo != null ? 1 : 0) + recentQueue.length;

    return Container(
      color: bgWell,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Text(
              'QUEUE — $totalCount TRACKS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: textDim,
              ),
            ),
          ),

          // Queue Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                if (currentVideo != null) ...[
                  _buildQueueItem(
                    index: '01',
                    title: currentVideo.title,
                    tag: dlCtrl.selectedQuality?.id ?? 'best',
                    meta: currentVideo.formattedDuration,
                    isActive: true,
                    isDone: dlCtrl.currentTask?.status == DownloadStatus.completed,
                    isDark: isDark,
                  ),
                ],
                ...recentQueue.asMap().entries.map((entry) {
                  final idx = entry.key + (currentVideo != null ? 2 : 1);
                  final task = entry.value;
                  return _buildQueueItem(
                    index: idx.toString().padLeft(2, '0'),
                    title: task.title,
                    tag: 'done',
                    meta: task.formatId ?? 'MP4',
                    isActive: false,
                    isDone: true,
                    isDark: isDark,
                  );
                }),
                if (currentVideo == null && recentQueue.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No tracks in queue.\nPaste a link to load.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: textDim,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '+ paste a link',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: textDim,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${dlCtrl.isDownloading ? 1 : 0} pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textNorm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem({
    required String index,
    required String title,
    required String tag,
    required String meta,
    required bool isActive,
    required bool isDone,
    required bool isDark,
    bool isDimmed = false,
  }) {
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgRaised = isDark ? const Color(0xFF1E2633) : const Color(0xFFEDF2F7);
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    return Opacity(
      opacity: isDimmed ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? bgRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: SpideyColors.spideyRed.withValues(alpha: 0.3), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                index,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? SpideyColors.spideyRed : textDim,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: textNorm,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDone
                              ? SpideyColors.spideyGreen.withValues(alpha: 0.12)
                              : (isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDone
                                ? SpideyColors.spideyGreen.withValues(alpha: 0.4)
                                : borderColor,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isDone ? SpideyColors.spideyGreen : textDim,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '·  $meta',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textDim,
                          ),
                        ),
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

  Widget _buildMainDeck(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    if (videoCtrl.isPlaylist && videoCtrl.currentPlaylist != null) {
      return _buildPlaylistBatchDeck(context, isDark, videoCtrl, dlCtrl);
    }

    final currentVideo = videoCtrl.currentVideo;
    final currentTask = dlCtrl.currentTask;
    final isDownloading = dlCtrl.isDownloading;
    final progress = currentTask?.progress ?? 0.0;
    final speedText = currentTask?.formattedSpeed ?? '0.0 MB/s';
    final etaText = currentTask?.formattedEta ?? '—:—';

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1100;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // URL Row
              _buildUrlRow(context, isDark, videoCtrl),
              const SizedBox(height: 16),

              // Error Display
              if (videoCtrl.errorMessage != null || dlCtrl.errorMessage != null) ...[
                _buildErrorCard(
                  context,
                  videoCtrl.errorMessage ?? dlCtrl.errorMessage!,
                  isDark,
                  () {
                    videoCtrl.clearError();
                    dlCtrl.dismissTask();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Preview Card
              _buildPreviewCard(context, isDark, videoCtrl, dlCtrl),
              const SizedBox(height: 18),

              // Transport & Telemetry Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Big Download Button
                        ElevatedButton(
                          onPressed: (currentVideo != null && !isDownloading)
                              ? () => dlCtrl.startDownload(currentVideo)
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            backgroundColor: SpideyColors.spideyRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
                            disabledForegroundColor: SpideyColors.spideyRed.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDownloading ? Icons.sync : Icons.arrow_downward,
                                size: 16,
                                color: (currentVideo != null && !isDownloading)
                                    ? Colors.white
                                    : SpideyColors.spideyRed.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDownloading ? 'DOWNLOADING' : 'DOWNLOAD',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDownloading) ...[
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: dlCtrl.cancelDownload,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              foregroundColor: SpideyColors.spideyRed,
                              side: BorderSide(color: SpideyColors.spideyRed.withValues(alpha: 0.5), width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 20),

                        // Modern VuMeter
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: VuMeter(
                              progress: progress,
                              speedText: speedText,
                              etaText: etaText,
                              isDownloading: isDownloading,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional Telemetry strip on wide screens
                    if (isWide) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderLit),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'STATE: ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDim,
                                  ),
                                ),
                                Text(
                                  isDownloading
                                      ? 'STREAMING IN PROGRESS'
                                      : (currentVideo != null ? 'TARGET ARMED' : 'STANDBY'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDownloading
                                        ? SpideyColors.spideyRed
                                        : (currentVideo != null ? SpideyColors.spideyBlue : textNorm),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ACTIVE PROFILE: ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDim,
                                  ),
                                ),
                                Text(
                                  dlCtrl.selectedQuality?.label ?? 'AUTO (HIGHEST)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textHi,
                                  ),
                                ),
                              ],
                            ),
                            _buildTelemetryThrottleSelector(
                              context: context,
                              isDark: isDark,
                              dlCtrl: dlCtrl,
                              key: const ValueKey('main_telemetry_throttle'),
                            ),
                            _buildTelemetryScheduleSelector(
                              context: context,
                              isDark: isDark,
                              dlCtrl: dlCtrl,
                              key: const ValueKey('main_telemetry_schedule'),
                            ),
                            InkWell(
                              onTap: dlCtrl.openFolder,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'DESTINATION ↴',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: SpideyColors.spideyRed,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.open_in_new, size: 12, color: SpideyColors.spideyRed),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // History Section
              _buildHistorySection(context, isDark, dlCtrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlRow(BuildContext context, bool isDark, VideoController videoCtrl) {
    final bgWell = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return Container(
      decoration: BoxDecoration(
        color: bgWell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.link, size: 20, color: textDim),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _urlController,
              onSubmitted: (_) => _onAnalyze(),
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 13.5,
                color: textHi,
              ),
              decoration: InputDecoration(
                hintText: 'https://youtu.be/... or video link',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: textDim,
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_urlController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, size: 16, color: textDim),
              onPressed: () {
                _urlController.clear();
                setState(() {});
              },
            ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: videoCtrl.isLoading ? null : _onAnalyze,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              backgroundColor: SpideyColors.spideyRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: videoCtrl.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.search, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'ANALYZE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final bgWell = isDark ? const Color(0xFF161B22) : Colors.white;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1100;
    final thumbWidth = isWide ? 220.0 : 150.0;
    final thumbHeight = isWide ? 124.0 : 85.0;

    final video = videoCtrl.currentVideo;

    if (video == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgWell,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: thumbWidth,
              height: thumbHeight,
              decoration: BoxDecoration(
                color: bgRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Icon(Icons.play_circle_outline, color: textDim, size: isWide ? 38 : 30),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No media target loaded',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textHi,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste any supported link above and click ANALYZE.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgWell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Thumbnail preview with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: thumbWidth,
              height: thumbHeight,
              decoration: BoxDecoration(
                color: bgRaised,
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (video.thumbnail != null && video.thumbnail!.isNotEmpty)
                    Image.network(
                      video.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.play_arrow, color: textDim, size: 28),
                      ),
                    )
                  else
                    Center(
                      child: Icon(Icons.play_arrow, color: textDim, size: 28),
                    ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Title & Dropdown Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${video.uploader ?? "Unknown Creator"} · ${video.formats.length} streams available',
                  style: TextStyle(
                    fontSize: 12,
                    color: textDim,
                  ),
                ),
                const SizedBox(height: 14),

                // Controls row: Format & Quality Selectors
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    // FORMAT Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FORMAT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: textDim,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: bgRaised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderLit),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: dlCtrl.selectedQuality?.isAudioOnly == true ? 'm4a' : 'mp4',
                              dropdownColor: bgRaised,
                              isDense: true,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textHi,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'mp4',
                                  child: Text('MP4 — Video + Audio'),
                                ),
                                DropdownMenuItem(
                                  value: 'm4a',
                                  child: Text('M4A/MP3 — Audio Only'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == 'm4a') {
                                  final audio = dlCtrl.availableQualities.firstWhere(
                                    (q) => q.isAudioOnly,
                                    orElse: () => dlCtrl.availableQualities.first,
                                  );
                                  dlCtrl.selectQuality(audio);
                                } else {
                                  final videoOption = dlCtrl.availableQualities.firstWhere(
                                    (q) => !q.isAudioOnly,
                                    orElse: () => dlCtrl.availableQualities.first,
                                  );
                                  dlCtrl.selectQuality(videoOption);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // QUALITY Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUALITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: textDim,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: bgRaised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderLit),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<QualityOption>(
                              value: dlCtrl.selectedQuality,
                              dropdownColor: bgRaised,
                              isDense: true,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textHi,
                              ),
                              items: dlCtrl.availableQualities.map((option) {
                                final sizeTag = option.formattedSize.isNotEmpty
                                    ? ' (${option.formattedSize})'
                                    : '';
                                return DropdownMenuItem(
                                  value: option,
                                  child: Text('${option.label}$sizeTag'),
                                );
                              }).toList(),
                              onChanged: (QualityOption? opt) {
                                if (opt != null) {
                                  dlCtrl.selectQuality(opt);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Advanced Audio Engine Deck (when audio format selected)
                if (dlCtrl.selectedQuality?.isAudioOnly == true) ...[
                  const SizedBox(height: 14),
                  _buildAdvancedAudioDeck(context, isDark, dlCtrl),
                ],
                const SizedBox(height: 14),

                // Saving To line + platform tag
                InkWell(
                  onTap: dlCtrl.isDownloading ? null : dlCtrl.pickDirectory,
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, size: 15, color: textDim),
                      const SizedBox(width: 5),
                      Text(
                        'SAVING TO  ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textDim,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          dlCtrl.downloadDirectory.isNotEmpty
                              ? dlCtrl.downloadDirectory
                              : '~/Downloads',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textNorm,
                          ),
                        ),
                      ),
                      Text(
                        '  · target: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: textDim,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: bgRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderLit),
                        ),
                        child: Text(
                          io.Platform.isWindows ? 'Windows' : 'Linux',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: textHi,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    String message,
    bool isDark,
    VoidCallback onDismiss,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SpideyColors.spideyRedDim, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: SpideyColors.spideyRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: SpideyColors.spideyRed,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: SpideyColors.spideyRed),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    bool isDark,
    DownloadController dlCtrl,
  ) {
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgWell = isDark ? const Color(0xFF161B22) : Colors.white;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    final historyTasks = dlCtrl.recentQueue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: textDim,
          ),
        ),
        const SizedBox(height: 10),
        if (historyTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgWell,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'No downloads completed this session.',
              style: TextStyle(
                fontSize: 12,
                color: textDim,
              ),
            ),
          )
        else
          ...historyTasks.map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgWell,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${task.title}.${task.formatId ?? "mp4"}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textNorm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderLit),
                        ),
                        child: Text(
                          task.formatId ?? 'MP4',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textDim,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: dlCtrl.openFolder,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'open folder ↴',
                              style: TextStyle(
                                fontSize: 11,
                                color: SpideyColors.spideyRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPlaylistBatchDeck(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final PlaylistInfo playlist = videoCtrl.currentPlaylist!;
    final isBatchRunning = dlCtrl.isBatchRunning;
    final progress = dlCtrl.overallBatchProgress;
    final speedText = dlCtrl.currentTask?.formattedSpeed ?? '0.0 MB/s';
    final etaText = isBatchRunning
        ? 'TRACK ${dlCtrl.batchCurrentIndex + 1}/${dlCtrl.batchQueue.length}'
        : 'READY';

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1100;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // URL Row
              _buildUrlRow(context, isDark, videoCtrl),
              const SizedBox(height: 16),

              // Error Display
              if (videoCtrl.errorMessage != null || dlCtrl.errorMessage != null) ...[
                _buildErrorCard(
                  context,
                  videoCtrl.errorMessage ?? dlCtrl.errorMessage!,
                  isDark,
                  () {
                    videoCtrl.clearError();
                    dlCtrl.dismissTask();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Playlist Overview & Format Selector Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SpideyColors.spideyRedDim),
                          ),
                          child: const Icon(
                            Icons.playlist_play,
                            color: SpideyColors.spideyRed,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  color: textHi,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${playlist.uploader ?? "Unknown Creator"} · ${playlist.totalCount} tracks discovered',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 16),

                    // Controls Row: Format, Quality, Save Location
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        // FORMAT Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BATCH FORMAT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textDim,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                              decoration: BoxDecoration(
                                color: bgRaised,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderLit),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: dlCtrl.selectedQuality?.isAudioOnly == true ? 'm4a' : 'mp4',
                                  dropdownColor: bgRaised,
                                  isDense: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textHi,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'mp4',
                                      child: Text('MP4 — Video + Audio'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'm4a',
                                      child: Text('MP3 — Audio Only'),
                                    ),
                                  ],
                                  onChanged: isBatchRunning
                                      ? null
                                      : (val) {
                                          if (val == 'm4a') {
                                            final audio = dlCtrl.availableQualities.firstWhere(
                                              (q) => q.isAudioOnly,
                                              orElse: () => dlCtrl.availableQualities.first,
                                            );
                                            dlCtrl.selectQuality(audio);
                                          } else {
                                            final videoOption = dlCtrl.availableQualities.firstWhere(
                                              (q) => !q.isAudioOnly,
                                              orElse: () => dlCtrl.availableQualities.first,
                                            );
                                            dlCtrl.selectQuality(videoOption);
                                          }
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),

                        // QUALITY Profile Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUALITY PROFILE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textDim,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                              decoration: BoxDecoration(
                                color: bgRaised,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderLit),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<QualityOption>(
                                  value: dlCtrl.selectedQuality,
                                  dropdownColor: bgRaised,
                                  isDense: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textHi,
                                  ),
                                  items: dlCtrl.availableQualities.map((option) {
                                    return DropdownMenuItem(
                                      value: option,
                                      child: Text(option.label),
                                    );
                                  }).toList(),
                                  onChanged: isBatchRunning
                                      ? null
                                      : (QualityOption? opt) {
                                          if (opt != null) {
                                            dlCtrl.selectQuality(opt);
                                          }
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Advanced Audio Engine Deck for Batch (when audio format selected)
                    if (dlCtrl.selectedQuality?.isAudioOnly == true) ...[
                      const SizedBox(height: 14),
                      _buildAdvancedAudioDeck(context, isDark, dlCtrl),
                    ],
                    const SizedBox(height: 14),

                    // Destination Path
                    InkWell(
                      onTap: isBatchRunning ? null : dlCtrl.pickDirectory,
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 15, color: textDim),
                          const SizedBox(width: 5),
                          Text(
                            'SAVING TO  ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textDim,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              dlCtrl.downloadDirectory.isNotEmpty
                                  ? dlCtrl.downloadDirectory
                                  : '~/Downloads',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textNorm,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '· [CHANGE FOLDER]',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SpideyColors.spideyBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selection Toolbar & Tracklist Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
                        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                      ),
                      child: Row(
                        children: [
                          // Quick select buttons
                          InkWell(
                            onTap: isBatchRunning
                                ? null
                                : () => videoCtrl.selectAllPlaylistItems(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: bgWell,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderLit),
                              ),
                              child: Text(
                                'SELECT ALL',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: textNorm,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: isBatchRunning
                                ? null
                                : () => videoCtrl.selectAllPlaylistItems(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: bgWell,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderLit),
                              ),
                              child: Text(
                                'DESELECT ALL',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: textNorm,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${playlist.selectedCount} OF ${playlist.totalCount} SELECTED',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: SpideyColors.spideyRed,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Tracklist
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 380),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: playlist.items.length,
                        separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                        itemBuilder: (context, i) {
                          final PlaylistItem item = playlist.items[i];
                          DownloadTask? task;
                          if (dlCtrl.batchQueue.isNotEmpty) {
                            try {
                              task = dlCtrl.batchQueue.firstWhere((t) => t.id == item.id);
                            } catch (_) {
                              task = null;
                            }
                          }
                          final isDownloadingThis = isBatchRunning && dlCtrl.batchCurrentIndex == i;
                          final isItemDone = task?.status == DownloadStatus.completed;
                          final isItemFailed = task?.status == DownloadStatus.failed;

                          return InkWell(
                            onTap: isBatchRunning
                                ? null
                                : () => videoCtrl.togglePlaylistItem(i),
                            child: Container(
                              color: isDownloadingThis
                                  ? (isDark ? const Color(0xFF241419) : const Color(0xFFFFECEE))
                                  : (item.isSelected ? Colors.transparent : (isDark ? Colors.black26 : Colors.black12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  // Checkbox
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: item.isSelected,
                                      activeColor: SpideyColors.spideyRed,
                                      checkColor: Colors.white,
                                      onChanged: isBatchRunning
                                          ? null
                                          : (_) => videoCtrl.togglePlaylistItem(i),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Index
                                  Text(
                                    (i + 1).toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textDim,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: item.isSelected ? textHi : textDim,
                                        fontWeight: item.isSelected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Status Badge or Duration
                                  if (isDownloadingThis)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: SpideyColors.spideyRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DOWNLOADING',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (isItemDone)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: SpideyColors.spideyGreen.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: SpideyColors.spideyGreen.withValues(alpha: 0.4)),
                                      ),
                                      child: const Text(
                                        'DONE',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: SpideyColors.spideyGreen,
                                        ),
                                      ),
                                    )
                                  else if (isItemFailed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: SpideyColors.spideyGold.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: SpideyColors.spideyGold.withValues(alpha: 0.4)),
                                      ),
                                      child: const Text(
                                        'FAILED',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: SpideyColors.spideyGold,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      item.formattedDuration,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textDim,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Transport & VU Meter Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Big Batch Download / Cancel Button
                        ElevatedButton(
                          onPressed: (playlist.hasSelection && !isBatchRunning)
                              ? () => dlCtrl.startBatchDownload(playlist)
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            backgroundColor: SpideyColors.spideyRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
                            disabledForegroundColor: SpideyColors.spideyRed.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isBatchRunning ? Icons.sync : Icons.arrow_downward,
                                size: 16,
                                color: (playlist.hasSelection && !isBatchRunning)
                                    ? Colors.white
                                    : SpideyColors.spideyRed.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isBatchRunning
                                    ? 'DOWNLOADING (${dlCtrl.batchCurrentIndex + 1}/${dlCtrl.batchQueue.length})'
                                    : 'DOWNLOAD ${playlist.selectedCount} TRACKS',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isBatchRunning) ...[
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: dlCtrl.cancelBatch,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              foregroundColor: SpideyColors.spideyRed,
                              side: BorderSide(color: SpideyColors.spideyRed.withValues(alpha: 0.5), width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'CANCEL BATCH',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 20),

                        // VU Meter displaying overall batch progress or current track progress
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: VuMeter(
                              progress: isBatchRunning ? progress : 0.0,
                              speedText: speedText,
                              etaText: etaText,
                              isDownloading: isBatchRunning,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional Telemetry Strip on wide screens
                    if (isWide) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderLit),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'BATCH STATE: ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDim,
                                  ),
                                ),
                                Text(
                                  isBatchRunning
                                      ? 'STREAMING (${dlCtrl.batchCurrentIndex + 1}/${dlCtrl.batchQueue.length})'
                                      : (playlist.hasSelection ? 'BATCH ARMED' : 'NO TRACKS SELECTED'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBatchRunning
                                        ? SpideyColors.spideyRed
                                        : (playlist.hasSelection ? SpideyColors.spideyBlue : textNorm),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PROGRESS: ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDim,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}% COMPLETED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textHi,
                                  ),
                                ),
                              ],
                            ),
                            _buildTelemetryThrottleSelector(
                              context: context,
                              isDark: isDark,
                              dlCtrl: dlCtrl,
                              key: const ValueKey('batch_telemetry_throttle'),
                            ),
                            _buildTelemetryScheduleSelector(
                              context: context,
                              isDark: isDark,
                              dlCtrl: dlCtrl,
                              key: const ValueKey('batch_telemetry_schedule'),
                            ),
                            InkWell(
                              onTap: dlCtrl.openFolder,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'DESTINATION ↴',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: SpideyColors.spideyRed,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.open_in_new, size: 12, color: SpideyColors.spideyRed),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // History Section
              _buildHistorySection(context, isDark, dlCtrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedAudioDeck(
    BuildContext context,
    bool isDark,
    DownloadController dlCtrl,
  ) {
    final bgRaised = isDark ? const Color(0xFF131D2A) : const Color(0xFFF0F6FF);
    final bgWell = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    final isDownloading = dlCtrl.isDownloading;
    final audioConfig = dlCtrl.audioConfig;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SpideyColors.spideyBlue.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq, size: 16, color: SpideyColors.spideyBlue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ADVANCED AUDIO ENGINE · ID3v2 & HIGH-FIDELITY',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgWell,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderLit),
                ),
                child: Text(
                  '${audioConfig.format.id.toUpperCase()} · ${audioConfig.bitrate.id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SpideyColors.spideyBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdowns & Switches Strip
          Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Bitrate Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BITRATE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: textDim,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: bgWell,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderLit),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AudioBitrate>(
                        value: audioConfig.bitrate,
                        dropdownColor: bgWell,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
                        ),
                        items: AudioBitrate.values.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(b.label),
                          );
                        }).toList(),
                        onChanged: isDownloading
                            ? null
                            : (val) {
                                if (val != null) dlCtrl.setAudioBitrate(val);
                              },
                      ),
                    ),
                  ),
                ],
              ),

              // Container Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTAINER',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: textDim,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: bgWell,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderLit),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AudioFormat>(
                        value: audioConfig.format,
                        dropdownColor: bgWell,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
                        ),
                        items: AudioFormat.values.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text(f.label),
                          );
                        }).toList(),
                        onChanged: isDownloading
                            ? null
                            : (val) {
                                if (val != null) dlCtrl.setAudioFormat(val);
                              },
                      ),
                    ),
                  ),
                ],
              ),

              // Checkbox: Embed Cover Art
              InkWell(
                onTap: isDownloading
                    ? null
                    : () => dlCtrl.setEmbedThumbnail(!audioConfig.embedThumbnail),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: audioConfig.embedThumbnail,
                        activeColor: SpideyColors.spideyBlue,
                        checkColor: Colors.white,
                        onChanged: isDownloading
                            ? null
                            : (val) => dlCtrl.setEmbedThumbnail(val ?? true),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EMBED ARTWORK',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textNorm,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkbox: ID3 Metadata Tags
              InkWell(
                onTap: isDownloading
                    ? null
                    : () => dlCtrl.setEmbedMetadata(!audioConfig.embedMetadata),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: audioConfig.embedMetadata,
                        activeColor: SpideyColors.spideyBlue,
                        checkColor: Colors.white,
                        onChanged: isDownloading
                            ? null
                            : (val) => dlCtrl.setEmbedMetadata(val ?? true),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ID3 TAGS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textNorm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Buttons Strip
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'PRESETS: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textDim,
                  letterSpacing: 0.5,
                ),
              ),
              _buildAudioPresetChip(
                label: 'STUDIO (320k)',
                isActive: audioConfig == AudioConfig.studioMusic,
                isDark: isDark,
                onTap: isDownloading
                    ? null
                    : () => dlCtrl.applyAudioPreset(AudioConfig.studioMusic),
              ),
              _buildAudioPresetChip(
                label: 'PODCAST (192k)',
                isActive: audioConfig == AudioConfig.podcast,
                isDark: isDark,
                onTap: isDownloading
                    ? null
                    : () => dlCtrl.applyAudioPreset(AudioConfig.podcast),
              ),
              _buildAudioPresetChip(
                label: 'VBR EFFICIENT',
                isActive: audioConfig == AudioConfig.vbrEfficient,
                isDark: isDark,
                onTap: isDownloading
                    ? null
                    : () => dlCtrl.applyAudioPreset(AudioConfig.vbrEfficient),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryThrottleSelector({
    required BuildContext context,
    required bool isDark,
    required DownloadController dlCtrl,
    Key? key,
  }) {
    final bgRaised =
        isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final textDim =
        isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return PopupMenuButton<SpeedLimit>(
      key: key ?? const ValueKey('telemetry_throttle_menu'),
      tooltip: 'Subprocess Speed Limiter',
      initialValue: dlCtrl.speedLimit,
      onSelected: dlCtrl.setSpeedLimit,
      color: bgRaised,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => SpeedLimit.values.map((limit) {
        final isSelected = dlCtrl.speedLimit == limit;
        return PopupMenuItem<SpeedLimit>(
          value: limit,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  limit.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? SpideyColors.spideyRed : textHi,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check,
                    size: 14, color: SpideyColors.spideyRed),
            ],
          ),
        );
      }).toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'THROTTLE: ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textDim,
            ),
          ),
          Text(
            '${dlCtrl.speedLimit.shortLabel} ▾',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: dlCtrl.speedLimit.isThrottled
                  ? SpideyColors.spideyRed
                  : textHi,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryScheduleSelector({
    required BuildContext context,
    required bool isDark,
    required DownloadController dlCtrl,
    Key? key,
  }) {
    final bgRaised =
        isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final textDim =
        isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return PopupMenuButton<ScheduleDelay>(
      key: key ?? const ValueKey('telemetry_schedule_menu'),
      tooltip: 'Off-Peak Delayed Queue',
      initialValue: dlCtrl.scheduleDelay,
      onSelected: dlCtrl.setScheduleDelay,
      color: bgRaised,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => ScheduleDelay.values.map((delay) {
        final isSelected = dlCtrl.scheduleDelay == delay;
        return PopupMenuItem<ScheduleDelay>(
          value: delay,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  delay.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? SpideyColors.spideyBlue : textHi,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check,
                    size: 14, color: SpideyColors.spideyBlue),
            ],
          ),
        );
      }).toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SCHEDULE: ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textDim,
            ),
          ),
          Text(
            '${dlCtrl.scheduleDelay.shortLabel} ▾',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: dlCtrl.scheduleDelay.isDelayed
                  ? SpideyColors.spideyBlue
                  : textHi,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPresetChip({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF14243B) : const Color(0xFFE0EDFF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? SpideyColors.spideyBlue
                : (isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive
                ? SpideyColors.spideyBlue
                : (isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim),
          ),
        ),
      ),
    );
  }
}
