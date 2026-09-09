import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Modern sleek progress indicator showing download progress, speed, and ETA with live animations.
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

    final trackColor = isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5);
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
                      color: isDownloading || progress >= 1.0
                          ? (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E5E5))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                        color: isDownloading || progress >= 1.0
                            ? (isDark ? Colors.white : Colors.black)
                            : textNorm,
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

          // Smooth modern continuous progress bar with zero-idle-overhead tween interpolation
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
