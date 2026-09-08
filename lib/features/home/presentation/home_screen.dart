import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../controllers/video_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/download_task.dart';
import '../../../models/quality_option.dart';
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
                    opacity: 0.55,
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
    final isDownloading = dlCtrl.isDownloading;
    final isFetching = videoCtrl.isLoading;
    final isDone = dlCtrl.currentTask?.status == DownloadStatus.completed;

    // Determine status text and dot color
    String statusText = 'IDLE';
    Color dotColor = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    if (isFetching) {
      statusText = 'FETCHING';
      dotColor = SpideyColors.spideyBlue;
    } else if (isDownloading) {
      statusText = 'DOWNLOADING';
      dotColor = SpideyColors.spideyRed;
    } else if (isDone) {
      statusText = 'COMPLETE';
      dotColor = SpideyColors.spideyGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF141B23), const Color(0xFF0F151B)]
              : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        ),
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand + Animated Reel
          Row(
            children: [
              ReelSpinner(
                isSpinning: isDownloading,
                reelColor: isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit,
                spokeColor: SpideyColors.spideyRed,
                size: 30,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.8,
                        color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
                      ),
                      children: const [
                        TextSpan(text: 'SPIDEY'),
                        TextSpan(
                          text: '_DLX',
                          style: TextStyle(color: SpideyColors.spideyRed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WEB-SLINGING VIDEO GRABBER · WIN / LINUX',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions: Theme Switcher & Status Pill
          Row(
            children: [
              // Theme Toggle Button
              InkWell(
                onTap: _toggleTheme,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: bgWell,
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDark ? '🌙 DARK' : '☀️ LIGHT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 1.0,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Text(
              'QUEUE — $totalCount TRACKS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: textDim,
              ),
            ),
          ),

          // Queue Items List
          Expanded(
            child: ListView(
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
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No tracks in queue.\nPaste a link to load.',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.6,
                        color: textDim,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: textDim,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${dlCtrl.isDownloading ? 1 : 0} pending',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
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
  }) {
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? bgRaised : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
          left: isActive
              ? const BorderSide(color: SpideyColors.spideyRed, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: textDim,
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
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.35,
                    color: textNorm,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDone
                              ? SpideyColors.spideyRedDim
                              : (isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          color: isDone ? SpideyColors.spideyRed : textDim,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '·  $meta',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
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
    );
  }

  Widget _buildMainDeck(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final currentVideo = videoCtrl.currentVideo;
    final currentTask = dlCtrl.currentTask;
    final isDownloading = dlCtrl.isDownloading;
    final progress = currentTask?.progress ?? 0.0;
    final speedText = currentTask?.formattedSpeed ?? '0.0 MB/s';
    final etaText = currentTask?.formattedEta ?? '—:—';

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

              // Preview Card
              _buildPreviewCard(context, isDark, videoCtrl, dlCtrl),
              const SizedBox(height: 18),

              // Transport & Telemetry Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: bgWell,
                  border: Border.all(color: borderColor, width: 1),
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
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                            backgroundColor: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
                            foregroundColor: SpideyColors.spideyRed,
                            side: const BorderSide(color: SpideyColors.spideyRedDim, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_downward, size: 16, color: SpideyColors.spideyRed),
                              const SizedBox(width: 8),
                              Text(
                                isDownloading ? 'DOWNLOADING' : 'DOWNLOAD',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              foregroundColor: SpideyColors.spideyRed,
                              side: const BorderSide(color: SpideyColors.spideyRedDim, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 20),

                        // 28-Bar Segmented VU Meter (Constrained to 500px for crisp proportion)
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
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgRaised,
                          border: Border.all(color: borderLit),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'STATE: ',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: textDim,
                                  ),
                                ),
                                Text(
                                  isDownloading
                                      ? 'STREAMING IN PROGRESS'
                                      : (currentVideo != null ? 'TARGET ARMED' : 'STANDBY'),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
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
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: textDim,
                                  ),
                                ),
                                Text(
                                  dlCtrl.selectedQuality?.label ?? 'AUTO (HIGHEST)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: textHi,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: dlCtrl.openFolder,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'DESTINATION ↴',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
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
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _urlController,
            onSubmitted: (_) => _onAnalyze(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
            ),
            decoration: InputDecoration(
              hintText: 'https://youtu.be/... or video link',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim,
              ),
              filled: true,
              fillColor: bgWell,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: borderLit, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: videoCtrl.isLoading ? null : _onAnalyze,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised,
              border: Border.all(color: borderLit, width: 1),
            ),
            child: videoCtrl.isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SpideyColors.spideyRed,
                    ),
                  )
                : Text(
                    'ANALYZE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark ? SpideyColors.darkText : SpideyColors.lightText,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    bool isDark,
    VideoController videoCtrl,
    DownloadController dlCtrl,
  ) {
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
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
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: thumbWidth,
              height: thumbHeight,
              color: bgRaised,
              child: Center(
                child: Icon(Icons.play_arrow, color: textDim, size: isWide ? 36 : 28),
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
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textHi,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste any supported link above and click ANALYZE.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Thumbnail preview
          Container(
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
                  bottom: 4,
                  right: 4,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    child: Text(
                      video.formattedDuration,
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
          ),
          const SizedBox(width: 16),

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
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${video.uploader ?? "Unknown Creator"} · ${video.formats.length} streams available',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: textDim,
                  ),
                ),
                const SizedBox(height: 12),

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
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            color: textDim,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: bgRaised,
                            border: Border.all(color: borderLit),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: dlCtrl.selectedQuality?.isAudioOnly == true ? 'm4a' : 'mp4',
                              dropdownColor: bgRaised,
                              isDense: true,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
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
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            color: textDim,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: bgRaised,
                            border: Border.all(color: borderLit),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<QualityOption>(
                              value: dlCtrl.selectedQuality,
                              dropdownColor: bgRaised,
                              isDense: true,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
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
                const SizedBox(height: 12),

                // Saving To line + platform tag
                InkWell(
                  onTap: dlCtrl.isDownloading ? null : dlCtrl.pickDirectory,
                  child: Row(
                    children: [
                      Text(
                        'SAVING TO  ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
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
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: textNorm,
                          ),
                        ),
                      ),
                      Text(
                        '  · target: ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: textDim,
                        ),
                      ),
                      Text(
                        io.Platform.isWindows ? 'Windows' : 'Linux',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: textHi,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
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
                fontFamily: 'monospace',
                fontSize: 11.5,
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
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;

    final historyTasks = dlCtrl.recentQueue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTORY',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: textDim,
          ),
        ),
        const SizedBox(height: 8),
        if (historyTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgWell,
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'No downloads completed this session.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: textDim,
              ),
            ),
          )
        else
          ...historyTasks.map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgWell,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${task.title}.${task.formatId ?? "mp4"}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: textNorm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.formatId ?? 'MP4',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: textDim,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: dlCtrl.openFolder,
                        child: const Text(
                          'open folder ↴',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: SpideyColors.spideyRed,
                            fontWeight: FontWeight.bold,
                          ),
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
}
