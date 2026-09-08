import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Desktop row displaying the destination folder and a browse directory action.
class DownloadLocationBar extends StatelessWidget {
  final String directoryPath;
  final VoidCallback onBrowse;
  final bool isEnabled;

  const DownloadLocationBar({
    super.key,
    required this.directoryPath,
    required this.onBrowse,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgWell,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 18,
            color: SpideyColors.spideyRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SAVE LOCATION',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    color: textDim,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  directoryPath.isNotEmpty ? directoryPath : 'Default Downloads',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textHi,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: isEnabled ? onBrowse : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgRaised,
                border: Border.all(color: borderLit),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 14, color: SpideyColors.spideyRed),
                  SizedBox(width: 6),
                  Text(
                    'BROWSE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: SpideyColors.spideyRed,
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
