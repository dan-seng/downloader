import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../core/theme/app_theme.dart';

/// Modal dialog providing inspection and 1-click update/installation
/// for the underlying yt-dlp and FFmpeg binary engines.
class EngineManagerDialog extends StatelessWidget {
  final DownloadController downloadController;
  final bool isDark;

  const EngineManagerDialog({
    super.key,
    required this.downloadController,
    required this.isDark,
  });

  /// Displays the engine manager dialog modally.
  static Future<void> show(
    BuildContext context, {
    required DownloadController downloadController,
    required bool isDark,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !downloadController.isEngineUpdating,
      builder: (context) => ListenableBuilder(
        listenable: downloadController,
        builder: (context, _) => EngineManagerDialog(
          downloadController: downloadController,
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;

    final info = downloadController.engineInfo;
    final isUpdating = downloadController.isEngineUpdating;
    final updateProgress = downloadController.engineUpdateProgress;
    final updateMessage = downloadController.engineUpdateMessage;

    final isYtdlpReady = info?.isYtdlpReady ?? false;
    final ytdlpVersion = info?.ytdlpVersion ?? 'Unknown';
    final ytdlpPath = info?.ytdlpPath ?? 'No binary located';

    final isFfmpegReady = info?.ffmpegAvailable ?? false;
    final ffmpegVersion = info?.ffmpegVersion ?? 'Not found in system PATH';

    return Dialog(
      backgroundColor: bgRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgWell,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 20,
                          color: textHi,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENGINE SUBSYSTEM',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: textHi,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'HYBRID RESOLUTION & LIFECYCLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: textDim,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: textDim),
                    onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // yt-dlp Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgWell,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isYtdlpReady
                                    ? (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
                                    : (isDark ? const Color(0xFFCC4444) : const Color(0xFFAA2222)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'yt-dlp Stream Engine',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textHi,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            isYtdlpReady ? ytdlpVersion : 'MISSING',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: isYtdlpReady ? textHi : (isDark ? Colors.redAccent : Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Source: ${info?.sourceLabel ?? "Scanning..."}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textHi,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ytdlpPath,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: textDim,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (isUpdating) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: updateProgress > 0 ? updateProgress : null,
                          backgroundColor: borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : Colors.black,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        updateMessage.isNotEmpty ? updateMessage : 'Updating...',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: textDim,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          key: const ValueKey('engine_dialog_action_button'),
                          onPressed: isUpdating
                              ? null
                              : () async {
                                  await downloadController.updateEngine();
                                },
                          icon: isUpdating
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isYtdlpReady ? Icons.refresh : Icons.download,
                                  size: 14,
                                ),
                          label: Text(
                            isUpdating
                                ? 'UPDATING...'
                                : (isYtdlpReady ? 'UPDATE TO LATEST RELEASE' : 'DOWNLOAD & INSTALL yt-dlp'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () async {
                                  await downloadController.checkEngine();
                                },
                          icon: const Icon(Icons.search, size: 14),
                          label: const Text(
                            'RE-SCAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textHi,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // FFmpeg Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgWell,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFfmpegReady
                                  ? (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
                                  : (isDark ? const Color(0xFF888888) : const Color(0xFF999999)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FFmpeg Transcoder',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: textHi,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isFfmpegReady ? ffmpegVersion : 'Optional for basic MP4, required for FLAC/WAV',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: isFfmpegReady ? 'monospace' : null,
                                    color: textDim,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        isFfmpegReady ? 'DETECTED' : 'NOT FOUND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFfmpegReady ? textHi : textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Explanatory note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 15, color: textDim),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Why updates matter: Video platforms frequently alter stream algorithms. When extractions fail, clicking "UPDATE" installs the latest yt-dlp binary into your local user vault (~/.spidey_dlx/bin) without requiring app reinstallation.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
