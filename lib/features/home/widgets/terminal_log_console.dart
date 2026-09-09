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
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant TerminalLogConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

    final latestLog = widget.logs.isNotEmpty ? widget.logs.last : 'Ready';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: bgWell,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsible Header Bar
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 14,
                        color: textDim,
                      ),
                      const SizedBox(width: 8),
                      if (widget.logs.isNotEmpty) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'SUBPROCESS OUTPUT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: textDim,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_isExpanded)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Text(
                            latestLog,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: textDim.withValues(alpha: 0.8),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'spidey_engine · ${widget.logs.length} logs',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: textDim,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 16,
                        color: textDim,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Log Lines with AnimatedSize smooth drawer expansion
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            child: _isExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, thickness: 1),
                      Container(
                        height: 130,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                itemCount: widget.logs.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == widget.logs.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                                      child: _TerminalPromptCursor(
                                        color: isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi,
                                      ),
                                    );
                                  }
                                  final line = widget.logs[index];
                                  return _buildLogLine(line, isDark);
                                },
                              ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(String rawLine, bool isDark) {
    final Color textColor = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

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

/// Monospace terminal prompt cursor.
class _TerminalPromptCursor extends StatelessWidget {
  final Color color;
  const _TerminalPromptCursor({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '▋',
      style: TextStyle(
        fontSize: 10,
        color: color.withValues(alpha: 0.6),
        fontFamily: 'monospace',
      ),
    );
  }
}
