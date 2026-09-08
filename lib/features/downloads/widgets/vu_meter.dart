import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 28-bar segmented digital VU meter showing real-time download activity.
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

  static const int barCount = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pct = (progress * 100).clamp(0, 100).floor();
    final litBars = (progress * barCount).round();

    final label = isDownloading
        ? '$pct% · $speedText'
        : (progress >= 1.0 ? '100% · COMPLETE' : '0% · 0.0 MB/s');
    final eta = isDownloading
        ? (etaText.isNotEmpty ? 'ETA $etaText' : 'ETA —:—')
        : (progress >= 1.0 ? 'ETA 0:00' : 'ETA —:—');

    final bgBar = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderBar = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
        // Top label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.5,
                color: isDark ? SpideyColors.darkText : SpideyColors.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              eta,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.5,
                color: isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 28 segmented vertical bars
        SizedBox(
          height: 22,
          child: Row(
            children: List.generate(barCount, (i) {
              final isLit = i < litBars;
              // Threshold colors
              Color barColor;
              if (i > barCount * 0.85) {
                barColor = SpideyColors.spideyGold; // Peak
              } else if (i > barCount * 0.6) {
                barColor = SpideyColors.spideyBlue; // Hot
              } else {
                barColor = SpideyColors.spideyRed; // Normal
              }

              // Dynamic fill height
              final fillPercent = isLit
                  ? (isDownloading ? 0.45 + (math.Random(i + pct).nextDouble() * 0.55) : 1.0)
                  : 0.0;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == barCount - 1 ? 0 : 3),
                  decoration: BoxDecoration(
                    color: bgBar,
                    border: Border.all(color: borderBar, width: 1),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1.0,
                    heightFactor: fillPercent,
                    child: Container(
                      color: barColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );
}
}
