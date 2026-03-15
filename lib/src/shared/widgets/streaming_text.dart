/// Streaming text widget with typewriter effect
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// Widget that displays streaming text with optional typewriter animation
class StreamingText extends StatefulWidget {
  /// The full text to display
  final String text;

  /// Duration per character for typewriter effect
  final Duration characterDuration;

  /// Text style
  final TextStyle? style;

  /// Whether currently streaming (shows cursor if true)
  final bool isStreaming;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Whether to enable typewriter effect
  final bool enableTypewriter;

  /// Cursor character to show during streaming
  final String cursorChar;

  const StreamingText({
    super.key,
    required this.text,
    this.characterDuration = const Duration(milliseconds: 30),
    this.style,
    this.isStreaming = false,
    this.onComplete,
    this.enableTypewriter = true,
    this.cursorChar = '▌',
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
    _currentIndex = widget.text.length;
    _animationComplete = !widget.isStreaming;
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle text changes
    if (widget.text != oldWidget.text) {
      _handleTextChange(oldWidget.text);
    }

    // Handle streaming state changes
    if (widget.isStreaming != oldWidget.isStreaming) {
      if (!widget.isStreaming) {
        // Streaming stopped, show full text
        _stopAnimation();
        setState(() {
          _displayedText = widget.text;
          _currentIndex = widget.text.length;
          _animationComplete = true;
        });
        widget.onComplete?.call();
      }
    }
  }

  void _handleTextChange(String oldText) {
    if (widget.text.length > oldText.length) {
      // New text appended
      if (widget.enableTypewriter && !_animationComplete) {
        _startTypewriterAnimation();
      } else {
        setState(() {
          _displayedText = widget.text;
          _currentIndex = widget.text.length;
        });
      }
    } else if (widget.text.length < oldText.length) {
      // Text was reset/shortened
      _stopAnimation();
      setState(() {
        _displayedText = widget.text;
        _currentIndex = widget.text.length;
        _animationComplete = !widget.isStreaming;
      });
    }
  }

  void _startTypewriterAnimation() {
    _timer?.cancel();

    // Skip animation if too much text to show (performance optimization)
    final pendingChars = widget.text.length - _currentIndex;
    if (pendingChars > 50) {
      setState(() {
        _displayedText = widget.text;
        _currentIndex = widget.text.length;
      });
      return;
    }

    _timer = Timer.periodic(widget.characterDuration, (timer) {
      if (_currentIndex >= widget.text.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentIndex++;
        _displayedText = widget.text.substring(0, _currentIndex);
      });
    });
  }

  void _stopAnimation() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textToShow = _getDisplayText();
    final hasCursor = widget.isStreaming && widget.cursorChar.isNotEmpty;

    if (hasCursor) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: textToShow,
              style: widget.style,
            ),
            TextSpan(
              text: widget.cursorChar,
              style: (widget.style ?? const TextStyle()).copyWith(
                color: (widget.style?.color ?? Theme.of(context).colorScheme.onSurface)
                    .withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      textToShow,
      style: widget.style,
    );
  }

  String _getDisplayText() {
    if (!widget.enableTypewriter || _animationComplete) {
      return widget.text;
    }
    return _displayedText;
  }
}

/// Animated streaming text with fade-in effect
class StreamingTextFade extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool isStreaming;
  final Duration fadeDuration;

  const StreamingTextFade({
    super.key,
    required this.text,
    this.style,
    this.isStreaming = false,
    this.fadeDuration = const Duration(milliseconds: 100),
  });

  @override
  State<StreamingTextFade> createState() => _StreamingTextFadeState();
}

class _StreamingTextFadeState extends State<StreamingTextFade> {
  // TODO: Use previous text for diff animation
  // ignore: unused_field
  String _previousText = '';

  @override
  void didUpdateWidget(StreamingTextFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _previousText = oldWidget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple fade effect using AnimatedOpacity
    return AnimatedOpacity(
      opacity: 1.0,
      duration: widget.fadeDuration,
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}