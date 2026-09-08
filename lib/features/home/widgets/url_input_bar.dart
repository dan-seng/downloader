import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// URL input bar with paste actions, platform chips, and playful aesthetics.
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

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      // Auto-analyze on paste if valid URL
      if (text.startsWith('http://') || text.startsWith('https://')) {
        widget.onAnalyze(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Search Bar Container
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasText
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: hasText ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Icon(
                Icons.link_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isLoading,
                  onSubmitted: (_) => _handleAnalyze(),
                  style: const TextStyle(fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Paste video link (YouTube, Vimeo, Twitch...)',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (hasText)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear input',
                  onPressed: widget.isLoading ? null : () => _controller.clear(),
                ),
              IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                tooltip: 'Paste from clipboard',
                onPressed: widget.isLoading ? null : _handlePaste,
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: (hasText && !widget.isLoading) ? _handleAnalyze : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    widget.isLoading ? 'Analyzing...' : 'Analyze',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Supported platform pills
        Row(
          children: [
            Text(
              'Supported:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p['icon'] as IconData,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p['name'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
