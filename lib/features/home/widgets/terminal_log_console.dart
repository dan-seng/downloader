import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Monospace terminal displaying live subprocess engine output.
class TerminalLogConsole extends StatefulWidget {
  final List<String> logs;

  const TerminalLogConsole({
    super.key,
    required this.logs,
  });

  @override
  State<TerminalLogConsole> createState() => _TerminalLogConsoleState();
}

class _TerminalLogConsoleState extends State<TerminalLogConsole> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant TerminalLogConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;

    const consoleHeight = 130.0;

    return Container(
      decoration: BoxDecoration(
        color: bgWell,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBPROCESS OUTPUT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: textDim,
                ),
              ),
              Text(
                'yt-dlp v2026.08.12',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Log Lines
          SizedBox(
            height: consoleHeight,
            child: widget.logs.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'deck ready — waiting for a link',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: textDim,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.logs.length,
                    itemBuilder: (context, index) {
                      final line = widget.logs[index];
                      return _buildLogLine(line, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(String rawLine, bool isDark) {
    Color textColor = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    if (rawLine.contains('[download]') || rawLine.contains('ready') || rawLine.contains('resolved')) {
      textColor = SpideyColors.spideyGreen;
    } else if (rawLine.contains('WARNING') || rawLine.contains('ETA')) {
      textColor = SpideyColors.spideyBlue;
    } else if (rawLine.contains('ERROR') || rawLine.contains('failed')) {
      textColor = SpideyColors.spideyGold;
    }

    // Split timestamp if formatted like "18:30:12  message"
    String timePart = '';
    String msgPart = rawLine;
    if (rawLine.length >= 10 && rawLine.contains('  ')) {
      final splitIndex = rawLine.indexOf('  ');
      timePart = rawLine.substring(0, splitIndex);
      msgPart = rawLine.substring(splitIndex + 2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            height: 1.4,
          ),
          children: [
            if (timePart.isNotEmpty)
              TextSpan(
                text: '$timePart  ',
                style: TextStyle(
                  color: isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim,
                ),
              ),
            TextSpan(
              text: msgPart,
              style: TextStyle(
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
