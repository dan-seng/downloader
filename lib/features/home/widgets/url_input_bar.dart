import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// URL input field with paste, clear, and submit actions.
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !widget.isLoading,
            onSubmitted: (_) => _handleAnalyze(),
            decoration: InputDecoration(
              hintText: 'Paste video URL here (e.g., https://youtube.com/watch?v=...)',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Clear',
                      onPressed: widget.isLoading ? null : () => _controller.clear(),
                    ),
                  IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    tooltip: 'Paste from clipboard',
                    onPressed: widget.isLoading ? null : _handlePaste,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (hasText && !widget.isLoading) ? _handleAnalyze : null,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(widget.isLoading ? 'Analyzing...' : 'Analyze'),
          ),
        ),
      ],
    );
  }
}
