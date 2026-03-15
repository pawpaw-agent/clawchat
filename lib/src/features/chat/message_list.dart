/// Optimized message list widget with DiffUtil and performance enhancements
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/message.dart';
import '../../core/utils/list_optimizer.dart';
import '../../shared/widgets/message_bubble.dart';
import '../../shared/widgets/streaming_text.dart';
import 'chat_controller.dart' show ChatState, chatProvider;

export 'chat_controller.dart' show ChatState;

/// Optimized message list display with DiffUtil and item caching
class MessageList extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final String sessionKey;
  final ListOptimizationConfig? config;

  const MessageList({
    super.key,
    this.scrollController,
    required this.sessionKey,
    this.config,
  });

  @override
  ConsumerState<MessageList> createState() => MessageListState();
}

/// Public state class for testing access
class MessageListState extends ConsumerState<MessageList> {
  // DiffUtil for message comparison
  late final DiffUtil<Message> _diffUtil;

  // Cache for list item widgets
  final ListItemCache<String, Widget> _itemCache = ListItemCache(maxSize: 50);

  // Previous messages for diff calculation
  List<Message> _previousMessages = [];

  // Performance monitoring
  final ScrollPerformanceMonitor _performanceMonitor = ScrollPerformanceMonitor();
  ListPerformanceMetrics? _metrics;

  // Scroll detection
  bool _autoScrollEnabled = true;

  // Frame time tracking for FPS measurement
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();

    _diffUtil = DiffUtil<Message>(
      idExtractor: (msg) => msg.id,
      contentComparator: (a, b) => _messagesEqual(a, b),
    );

    // Configure image cache
    final config = widget.config ?? ListOptimizationConfig.chatList;
    ImageCacheConfig.configureForMemoryLimit(config.imageCacheMB);

    // Setup scroll listener for user scroll detection
    widget.scrollController?.addListener(_onScrollChanged);

    // Start performance tracking in debug mode
    if (config.enablePerformanceMonitoring) {
      _performanceMonitor.enable();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScrollChanged);
    _itemCache.clear();
    super.dispose();
  }

  void _onScrollChanged() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;

    // Detect user scroll (scrolling up)
    if (controller.position.userScrollDirection != ScrollDirection.idle) {
      _isUserScrolling = true;

      // Disable auto-scroll if user scrolls up
      if (controller.position.userScrollDirection == ScrollDirection.reverse) {
        _autoScrollEnabled = false;
      }
    }

    // Re-enable auto-scroll when user scrolls to bottom
    if (controller.position.pixels >= controller.position.maxScrollExtent - 50) {
      _autoScrollEnabled = true;
    }
  }

  /// Check if two messages have equal content
  bool _messagesEqual(Message a, Message b) {
    return a.id == b.id &&
        a.content == b.content &&
        a.isStreaming == b.isStreaming &&
        a.isComplete == b.isComplete &&
        a.mediaUrls.length == b.mediaUrls.length &&
        _listEquals(a.mediaUrls, b.mediaUrls);
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Calculate diff between old and new message lists
  DiffResult<Message>? _calculateDiff(List<Message> oldMessages, List<Message> newMessages) {
    if (oldMessages.isEmpty || newMessages.isEmpty) return null;
    return _diffUtil.calculateDiff(oldList: oldMessages, newList: newMessages);
  }

  /// Scroll to bottom with smooth animation
  void scrollToBottom({bool animate = true}) {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;

    // Only scroll if auto-scroll is enabled
    if (!_autoScrollEnabled) return;

    if (animate) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      controller.jumpTo(controller.position.maxScrollExtent);
    }
  }

  /// Force scroll to bottom (ignores user scroll state)
  void forceScrollToBottom({bool animate = true}) {
    _autoScrollEnabled = true;
    scrollToBottom(animate: animate);
  }

  /// Clear the item cache
  void clearCache() {
    _itemCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.sessionKey));
    final messages = chatState.messages;

    // Track frame times for FPS measurement
    _trackFrameTime();

    // Initialize performance metrics
    _metrics ??= ListPerformanceMetrics(
      listId: 'message_list_${widget.sessionKey}',
      startTime: DateTime.now(),
      itemCount: messages.length,
      visibleItemCount: _estimateVisibleItems(context),
    );

    // Listen for message changes
    ref.listen<ChatState>(chatProvider(widget.sessionKey), (previous, next) {
      _handleMessageChange(previous?.messages ?? [], next.messages);
    });

    if (messages.isEmpty) {
      return const _EmptyState();
    }

    // Calculate diff for incremental updates
    final diff = _calculateDiff(_previousMessages, messages);
    _previousMessages = List.from(messages);

    // Update metrics
    _metrics = ListPerformanceMetrics(
      listId: _metrics!.listId,
      startTime: _metrics!.startTime,
      itemCount: messages.length,
      visibleItemCount: _metrics!.visibleItemCount,
    );

    return _OptimizedListView(
      messages: messages,
      diffResult: diff,
      scrollController: widget.scrollController,
      itemCache: _itemCache,
      onRetry: _retryMessage,
      config: widget.config ?? ListOptimizationConfig.chatList,
    );
  }

  void _trackFrameTime() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!);
      _performanceMonitor.recordFrame(
        'message_list_${widget.sessionKey}',
        frameTime,
      );
      _frameCount++;
    }
    _lastFrameTime = now;
  }

  int _estimateVisibleItems(BuildContext context) {
    // Estimate based on screen height and average message height
    final screenHeight = MediaQuery.of(context).size.height;
    const avgMessageHeight = 80.0;
    return (screenHeight / avgMessageHeight).round();
  }

  void _handleMessageChange(List<Message> oldMessages, List<Message> newMessages) {
    // Auto-scroll when new message arrives
    if (newMessages.length > oldMessages.length) {
      // New message added
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_autoScrollEnabled) {
          scrollToBottom();
        }
      });
    }

    // Update streaming message cache
    if (newMessages.isNotEmpty) {
      final lastMessage = newMessages.last;
      if (lastMessage.isStreaming) {
        // Invalidate cache for streaming message
        _itemCache.remove(lastMessage.id);
      }
    }

    _lastMessageCount = newMessages.length;
  }

  void _retryMessage(Message message) {
    ref.read(chatProvider(widget.sessionKey).notifier).sendMessage(message.content);
  }
}

/// Optimized list view with RepaintBoundary and caching
class _OptimizedListView extends StatelessWidget {
  final List<Message> messages;
  final DiffResult<Message>? diffResult;
  final ScrollController? scrollController;
  final ListItemCache<String, Widget> itemCache;
  final void Function(Message) onRetry;
  final ListOptimizationConfig config;

  const _OptimizedListView({
    required this.messages,
    this.diffResult,
    this.scrollController,
    required this.itemCache,
    required this.onRetry,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      // Optimization: Fixed item extent for better scroll performance
      // Note: Remove if items have highly variable heights
      // itemExtent: null, // Keep null for variable height items
      // Optimization: Cache extent for pre-loading
      cacheExtent: config.cacheExtent,
      // Optimization: Add semantic indexing for accessibility
      addSemanticIndexes: true,
      // Optimization: Avoid rebuilds when scrolling
      addAutomaticKeepAlives: config.useKeepAlive,
      // Optimization: Enable repaint boundary for each item
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final message = messages[index];

        // Use RepaintBoundary for each item to isolate repaints
        return RepaintBoundary(
          key: ValueKey('msg_${message.id}'),
          child: _MessageItem(
            message: message,
            onRetry: message.isComplete == false ? () => onRetry(message) : null,
          ),
        );
      },
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual message item with const optimization
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
            _TimestampWidget(
              timestamp: message.createdAt!,
              isUser: _isUser,
            ),
          // Retry button for failed messages
          if (onRetry != null)
            _RetryButton(
              onRetry: onRetry!,
              isUser: _isUser,
            ),
        ],
      ),
    );
  }
}

/// Separated timestamp widget for const optimization
class _TimestampWidget extends StatelessWidget {
  final DateTime timestamp;
  final bool isUser;

  const _TimestampWidget({
    required this.timestamp,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 0 : 16,
        right: isUser ? 16 : 0,
        top: 2,
      ),
      child: Text(
        _formatTime(timestamp),
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Separated retry button for const optimization
class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isUser;

  const _RetryButton({
    required this.onRetry,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 0 : 16,
        right: isUser ? 16 : 0,
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
    );
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