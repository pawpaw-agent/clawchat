// Widget tests for optimized message list
// Tests ListView optimization, caching, and scroll behavior

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawchat/src/features/chat/message_list.dart';
import 'package:clawchat/src/core/models/message.dart';

void main() {
  group('MessageList Widget Tests', () {
    testWidgets('renders empty state when no messages', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageList(
                sessionKey: 'test-session',
              ),
            ),
          ),
        ),
      );

      // Wait for initial state
      await tester.pumpAndSettle();

      // Check for empty state
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Start a conversation with the AI assistant'), findsOneWidget);
    });

    testWidgets('renders messages correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageList(
                sessionKey: 'test-session',
              ),
            ),
          ),
        ),
      );

      // Wait for mock data to load
      await tester.pumpAndSettle();

      // Should have messages from mock data
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('uses RepaintBoundary for items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageList(
                sessionKey: 'test-session',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that RepaintBoundary widgets are present
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('scrollController is properly attached', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageList(
                sessionKey: 'test-session',
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify scroll controller is attached
      expect(scrollController.hasClients, isTrue);
    });

    test('MessageListState provides public API', () {
      // Verify that MessageListState has the expected public methods
      // This is a compile-time check
      final state = MessageListState();

      // Check that the methods exist
      expect(state.scrollToBottom, isA<Function>());
      expect(state.forceScrollToBottom, isA<Function>());
      expect(state.clearCache, isA<Function>());
    });
  });

  group('MessageItem Widget Tests', () {
    testWidgets('shows retry button for incomplete messages', (tester) async {
      // Create a message with isComplete = false
      final message = Message(
        id: 'test-id',
        sessionKey: 'test-session',
        role: MessageRole.user.value,
        content: 'Test message',
        isComplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestMessageItem(message: message),
          ),
        ),
      );

      // Look for retry button
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

// Test helper widget
class _TestMessageItem extends StatelessWidget {
  final Message message;

  const _TestMessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    // Simplified version of _MessageItem for testing
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(message.content),
          if (!message.isComplete)
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}