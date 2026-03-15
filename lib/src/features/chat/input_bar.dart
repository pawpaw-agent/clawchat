/// Input bar widget for chat
library;

import 'package:flutter/material.dart';

/// Chat input bar
class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final String? hintText;

  const InputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    if (_hasText && widget.enabled) {
      widget.onSend();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Type a message...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton.filled(
                icon: Icon(
                  widget.enabled ? Icons.send : Icons.hourglass_empty,
                ),
                onPressed: _hasText && widget.enabled ? _handleSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: _hasText && widget.enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHigh,
                  foregroundColor: _hasText && widget.enabled
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing indicator widget
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AI is typing',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          _AnimatedDots(),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dots = '.' * ((_controller.value * 3).floor() + 1);
        return Text(
          dots.padRight(3, ' '),
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12,
          ),
        );
      },
    );
  }
}