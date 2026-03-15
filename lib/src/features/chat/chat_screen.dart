/// Chat screen - main conversation interface
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_controller.dart';
import 'input_bar.dart';
import 'message_list.dart';

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
          // Connection status indicator
          const _ConnectionStatus(),

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

/// Connection status indicator
class _ConnectionStatus extends ConsumerWidget {
  const _ConnectionStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get real connection state from provider
    // For now, show a placeholder (disconnected state)
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.pending,
            size: 16,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Disconnected',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // TODO: Trigger reconnect
            },
            child: Text(
              'Tap to connect',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onErrorContainer,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}