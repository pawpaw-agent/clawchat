/// Streaming text widget
library;

import 'package:flutter/material.dart';

/// Widget that displays streaming text with optional animation
class StreamingText extends StatefulWidget {
  final String text;
  final Duration animationDuration;
  final TextStyle? style;
  final bool isStreaming;
  final VoidCallback? onComplete;

  const StreamingText({
    super.key,
    required this.text,
    this.animationDuration = const Duration(milliseconds: 50),
    this.style,
    this.isStreaming = false,
    this.onComplete,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  String _displayedText = '';

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      // New text arrived
      if (widget.text.length > _displayedText.length) {
        // Text is being appended
        _displayedText = widget.text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}