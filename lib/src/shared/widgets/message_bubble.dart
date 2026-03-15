/// Message bubble widget with Markdown support
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_renderer.dart';

/// Message bubble for chat
class MessageBubble extends StatelessWidget {
  /// The message content
  final String content;

  /// Whether this is a user message
  final bool isUser;

  /// Whether the message is currently streaming
  final bool isStreaming;

  /// Timestamp of the message
  final DateTime? timestamp;

  /// Whether to enable Markdown rendering
  final bool enableMarkdown;

  /// Custom text style for non-Markdown content
  final TextStyle? textStyle;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    this.timestamp,
    this.enableMarkdown = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message content
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildContent(context, theme),
            ),
            // Streaming indicator
            if (isStreaming)
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 8),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    // User messages: plain text (no Markdown)
    if (isUser) {
      return SelectableText(
        content,
        style: textStyle ?? TextStyle(
          color: theme.colorScheme.onPrimary,
        ),
      );
    }

    // AI messages: Markdown rendering
    if (enableMarkdown && content.isNotEmpty) {
      return _MarkdownContent(
        content: content,
        textColor: theme.colorScheme.onSurface,
        textStyle: textStyle,
      );
    }

    // Fallback: plain text
    return SelectableText(
      content.isEmpty && isStreaming ? '...' : content,
      style: textStyle ?? TextStyle(
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// Markdown content wrapper with proper styling
class _MarkdownContent extends StatelessWidget {
  final String content;
  final Color textColor;
  final TextStyle? textStyle;

  const _MarkdownContent({
    required this.content,
    required this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownRenderer(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: textStyle?.copyWith(color: textColor) ?? TextStyle(color: textColor),
        a: TextStyle(color: Theme.of(context).colorScheme.primary),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: textStyle?.fontSize ?? 14,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          color: textColor.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        listBullet: TextStyle(color: textColor),
        tableBody: TextStyle(color: textColor),
        tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      onTapLink: (text, href, title) {
        _handleLinkTap(context, href);
      },
    );
  }

  void _handleLinkTap(BuildContext context, String url) {
    // Show confirmation dialog before opening link
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Link'),
        content: Text('Open this link?\n\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(url);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) {
    // Use url_launcher or similar in production
    // For now, copy to clipboard
    Clipboard.setData(ClipboardData(text: url));
  }
}

/// Streaming message bubble with typewriter effect
class StreamingMessageBubble extends StatefulWidget {
  final String content;
  final bool isStreaming;
  final VoidCallback? onComplete;

  const StreamingMessageBubble({
    super.key,
    required this.content,
    this.isStreaming = false,
    this.onComplete,
  });

  @override
  State<StreamingMessageBubble> createState() => _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<StreamingMessageBubble> {
  @override
  Widget build(BuildContext context) {
    return MessageBubble(
      content: widget.content,
      isUser: false,
      isStreaming: widget.isStreaming,
      enableMarkdown: !widget.isStreaming, // Disable Markdown during streaming
    );
  }
}