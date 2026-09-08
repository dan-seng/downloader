import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// SPIDEY deck URL input bar with paste action and analyze button.
class UrlInputBar extends StatefulWidget {
  final ValueChanged<String> onAnalyze;
  final bool isLoading;

  const UrlInputBar({
    super.key,
    required this.onAnalyze,
    this.isLoading = false,
  });

  @override
  State<UrlInputBar> createState() => _UrlInputBarState();
}

class _UrlInputBarState extends State<UrlInputBar> {
  late final TextEditingController _controller;

  static const _supportedPlatforms = [
    {'name': 'YouTube', 'icon': Icons.play_arrow_rounded},
    {'name': 'Vimeo', 'icon': Icons.video_collection_outlined},
    {'name': 'TikTok', 'icon': Icons.music_video_outlined},
    {'name': 'Twitch', 'icon': Icons.live_tv_outlined},
    {'name': 'SoundCloud', 'icon': Icons.graphic_eq_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAnalyze() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onAnalyze(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgWell = isDark ? SpideyColors.darkBgWell : SpideyColors.lightBgWell;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final hasText = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // URL Input Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !widget.isLoading,
                onSubmitted: (_) => _handleAnalyze(),
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
                    color: textDim,
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
              onTap: widget.isLoading ? null : _handleAnalyze,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  color: bgRaised,
                  border: Border.all(color: borderLit, width: 1),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SpideyColors.spideyRed,
                        ),
                      )
                    : const Text(
                        'ANALYZE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: SpideyColors.spideyRed,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Supported platform pills
        Row(
          children: [
            Text(
              'SUPPORTED:',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: textDim,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _supportedPlatforms.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgRaised,
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p['icon'] as IconData,
                            size: 13,
                            color: SpideyColors.spideyRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p['name'] as String,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: textNorm,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: textDim),
                tooltip: 'Clear input',
                onPressed: widget.isLoading ? null : () => _controller.clear(),
              ),
          ],
        ),
      ],
    );
  }
}
