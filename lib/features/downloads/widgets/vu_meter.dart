import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Modern sleek progress indicator showing download progress, speed, and ETA.
class VuMeter extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String speedText;
  final String etaText;
  final bool isDownloading;

  const VuMeter({
    super.key,
    required this.progress,
    required this.speedText,
    required this.etaText,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pct = (progress * 100).clamp(0, 100).floor();

    final label = isDownloading
        ? '$pct% · $speedText'
        : (progress >= 1.0 ? '100% · COMPLETE' : '0% · 0.0 MB/s');
    final eta = isDownloading
        ? (etaText.isNotEmpty ? 'ETA $etaText' : 'ETA —:—')
        : (progress >= 1.0 ? 'ETA 0:00' : 'ETA —:—');

    final trackColor = isDark ? const Color(0xFF1E2631) : const Color(0xFFE2E8F0);
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDownloading
                          ? SpideyColors.spideyRedGlow
                          : (progress >= 1.0 ? const Color(0x3322C55E) : Colors.transparent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                        color: isDownloading
                            ? SpideyColors.spideyRed
                            : (progress >= 1.0 ? SpideyColors.spideyGreen : textNorm),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                eta,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.2,
                  color: textDim,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Smooth modern continuous progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDownloading
                              ? [SpideyColors.spideyRed, const Color(0xFFFF5258)]
                              : (progress >= 1.0
                                  ? [SpideyColors.spideyGreen, const Color(0xFF4ADE80)]
                                  : [SpideyColors.spideyRed, SpideyColors.spideyRed]),
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isDownloading
                            ? [
                                BoxShadow(
                                  color: SpideyColors.spideyRed.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
