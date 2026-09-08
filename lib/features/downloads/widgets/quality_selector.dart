import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/quality_option.dart';

/// Segmented digital quality cards for format selection.
class QualitySelector extends StatelessWidget {
  final List<QualityOption> options;
  final QualityOption? selectedOption;
  final ValueChanged<QualityOption> onSelected;
  final bool isEnabled;

  const QualitySelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT QUALITY & FORMAT',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: textDim,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = option == selectedOption;
            return _buildQualityCard(context, option, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQualityCard(
    BuildContext context,
    QualityOption option,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return InkWell(
      onTap: isEnabled ? () => onSelected(option) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? SpideyColors.spideyRed.withValues(alpha: 0.12)
              : bgRaised,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? SpideyColors.spideyRed : borderLit,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.isAudioOnly
                  ? Icons.headphones_outlined
                  : Icons.play_circle_outline,
              size: 18,
              color: isSelected ? SpideyColors.spideyRed : textDim,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getShortLabel(option),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? SpideyColors.spideyRed : textHi,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? SpideyColors.spideyRed : bgRaised,
                        border: Border.all(color: isSelected ? SpideyColors.spideyRed : borderLit),
                      ),
                      child: Text(
                        option.extension.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : textDim,
                        ),
                      ),
                    ),
                  ],
                ),
                if (option.formattedSize.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.formattedSize,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? SpideyColors.spideyRed : textDim,
                    ),
                  ),
                ],
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: SpideyColors.spideyRed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getShortLabel(QualityOption option) {
    if (option.isAudioOnly) return 'Audio';
    if (option.id == 'best') return 'Best Quality';
    if (option.height != null) return '${option.height}p';
    return option.label;
  }
}
