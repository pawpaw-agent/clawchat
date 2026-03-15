/// Message list widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/message.dart';
import '../../shared/widgets/message_bubble.dart';
import '../../shared/widgets/streaming_text.dart';
import 'chat_controller.dart';

/// Message list display
class MessageList extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final String sessionKey;

  const MessageList({
    super.key,
    this.scrollController,
    required this.sessionKey,
  });

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  @override
  void initState() {
    super.initState();
    // Scroll to bottom when messages update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (widget.scrollController != null &&
        widget.scrollController!.hasClients) {
      widget.scrollController!.animateTo(
        widget.scrollController!.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.sessionKey));
    final messages = chatState.messages;

    // Listen for message changes to auto-scroll
    ref.listen<ChatState>(chatProvider(widget.sessionKey), (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    if (messages.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageItem(
          message: message,
          onRetry: message.isComplete == false ? () => _retryMessage(message) : null,
        );
      },
    );
  }

  void _retryMessage(Message message) {
    // TODO: Implement retry for failed messages
    ref.read(chatProvider(widget.sessionKey).notifier).sendMessage(message.content);
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with the AI assistant',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual message item
class _MessageItem extends StatelessWidget {
  final Message message;
  final VoidCallback? onRetry;

  const _MessageItem({
    required this.message,
    this.onRetry,
  });

  bool get _isUser => message.role == MessageRole.user.value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble with Markdown support
          if (message.isStreaming && !_isUser)
            _StreamingMessageBubble(
              content: message.content,
              isStreaming: message.isStreaming,
            )
          else
            MessageBubble(
              content: message.content.isEmpty && message.isStreaming
                  ? '...'
                  : message.content,
              isUser: _isUser,
              isStreaming: message.isStreaming,
              enableMarkdown: !_isUser, // Enable Markdown for AI messages
            ),
          // Timestamp
          if (message.createdAt != null)
            Padding(
              padding: EdgeInsets.only(
                left: _isUser ? 0 : 16,
                right: _isUser ? 16 : 0,
                top: 2,
              ),
              child: Text(
                _formatTime(message.createdAt!),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                ),
              ),
            ),
          // Retry button for failed messages
          if (onRetry != null)
            Padding(
              padding: EdgeInsets.only(
                left: _isUser ? 0 : 16,
                right: _isUser ? 16 : 0,
                top: 4,
              ),
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Streaming message bubble with typewriter effect
class _StreamingMessageBubble extends StatefulWidget {
  final String content;
  final bool isStreaming;

  const _StreamingMessageBubble({
    required this.content,
    required this.isStreaming,
  });

  @override
  State<_StreamingMessageBubble> createState() => _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<_StreamingMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streaming text with typewriter effect
              StreamingText(
                text: widget.content.isEmpty ? '...' : widget.content,
                isStreaming: widget.isStreaming,
                enableTypewriter: true,
                characterDuration: const Duration(milliseconds: 20),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              // Streaming indicator
              if (widget.isStreaming)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}