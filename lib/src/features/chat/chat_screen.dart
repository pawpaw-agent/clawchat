/// Chat screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClawChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status indicator
          const _ConnectionStatus(),
          
          // Message list
          Expanded(
            child: _MessageList(
              scrollController: _scrollController,
            ),
          ),
          
          // Input area
          _InputArea(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // TODO: Implement message sending
    setState(() {
      _messageController.clear();
    });
  }
}

class _ConnectionStatus extends ConsumerWidget {
  const _ConnectionStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get connection state from provider
    const isConnected = false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isConnected
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.pending,
            size: 16,
            color: isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;

  const _MessageList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    // TODO: Get messages from provider
    final messages = <dynamic>[];

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Connect to Gateway and start chatting',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // TODO: Build message item
        return const SizedBox.shrink();
      },
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}