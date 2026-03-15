/// Chat screen - main conversation interface
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_controller.dart';
import 'input_bar.dart';
import 'message_list.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/error_dialog.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Main chat screen
class ChatScreen extends ConsumerStatefulWidget {
  final String? sessionKey;

  const ChatScreen({
    super.key,
    this.sessionKey,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String get _sessionKey => widget.sessionKey ?? ref.read(currentSessionKeyProvider);

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(_sessionKey));
    final connectionState = ref.watch(connectionStateProvider);

    ref.listen<ChatState>(chatProvider(_sessionKey), (previous, next) {
      // Show error dialog for non-recoverable auth errors
      if (next.hasError && next.error is AuthException && !next.canRetry) {
        final authError = next.error as AuthException;
        showAuthErrorDialog(
          context: context,
          exception: authError,
          onPair: () {
            // TODO: Navigate to pairing screen
          },
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClawChat'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          _ConnectionStatusBanner(
            connectionState: connectionState,
            onRetry: _handleConnectionRetry,
          ),

          // Error banner for chat errors
          if (chatState.hasError)
            AnimatedErrorBanner(
              result: ErrorResult(
                exception: chatState.error!,
                wasLogged: true,
                timestamp: DateTime.now(),
              ),
              onRetry: chatState.canRetry ? _handleRetry : null,
              onDismiss: () {
                ref.read(chatProvider(_sessionKey).notifier).clearError();
              },
              isCompact: true,
            ),

          // Message list
          Expanded(
            child: MessageList(
              scrollController: _scrollController,
              sessionKey: _sessionKey,
            ),
          ),

          // Typing indicator when AI is responding
          if (chatState.isLoading) const TypingIndicator(),

          // Input area
          InputBar(
            controller: _messageController,
            onSend: _sendMessage,
            enabled: !chatState.isLoading,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider(_sessionKey).notifier).sendMessage(text);
    _messageController.clear();
  }

  void _handleRetry() {
    ref.read(chatProvider(_sessionKey).notifier).retryLastMessage();
  }

  void _handleConnectionRetry() {
    // TODO: Implement connection retry
    ref.read(connectionStateProvider.notifier).state =
        ref.read(connectionStateProvider).copyWith(
          isReconnecting: true,
          clearError: true,
        );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearConfirmation(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear chat'),
          content: const Text('Are you sure you want to clear all messages?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(chatProvider(_sessionKey).notifier).clearMessages();
              },
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Connection status banner widget
class _ConnectionStatusBanner extends StatelessWidget {
  final ChatConnectionState connectionState;
  final VoidCallback? onRetry;

  const _ConnectionStatusBanner({
    required this.connectionState,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (connectionState.isConnected && !connectionState.isConnecting) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    if (connectionState.isConnecting || connectionState.isReconnecting) {
      return Material(
        color: theme.colorScheme.primaryContainer,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                connectionState.isReconnecting
                    ? '正在重连... (${connectionState.reconnectAttempts})'
                    : '正在连接...',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Disconnected or error state
    return NetworkStatusBanner(
      isConnected: false,
      onRetry: onRetry,
    );
  }
}

/// Typing indicator widget
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI is thinking...',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}