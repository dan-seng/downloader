import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// User-facing error message card with dismiss action.
class ErrorDisplayCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onDismiss;

  const ErrorDisplayCard({
    super.key,
    required this.errorMessage,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261014) : const Color(0xFFFFECEE),
        border: Border.all(color: SpideyColors.spideyRedDim, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: SpideyColors.spideyRed, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: SpideyColors.spideyRed,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: SpideyColors.spideyRed),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
