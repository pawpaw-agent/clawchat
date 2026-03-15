/// Chat controller with Riverpod state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/message.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Message state for a chat session
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isRetrying;
  final AppException? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRetrying = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isRetrying,
    AppException? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRetrying: isRetrying ?? this.isRetrying,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Whether there's an error
  bool get hasError => error != null;

  /// Whether error is recoverable (can retry)
  bool get canRetry => error?.isRecoverable ?? false;
}

/// Chat controller notifier with error handling
class ChatNotifier extends StateNotifier<ChatState> with ErrorHandlingMixin {
  final Uuid _uuid;
  final String sessionKey;

  ChatNotifier({
    Uuid? uuid,
    required this.sessionKey,
  })  : _uuid = uuid ?? const Uuid(),
        super(const ChatState()) {
    _loadMockData();
  }

  /// Load mock data for development
  void _loadMockData() {
    final now = DateTime.now();
    final messages = [
      Message(
        id: _uuid.v4(),
        sessionKey: sessionKey,
        role: MessageRole.assistant.value,
        content: 'Hello! I\'m your AI assistant. How can I help you today?',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isComplete: true,
      ),
      Message(
        id: _uuid.v4(),
        sessionKey: sessionKey,
        role: MessageRole.user.value,
        content: 'Hi! Can you help me understand how this chat works?',
        createdAt: now.subtract(const Duration(minutes: 4)),
        isComplete: true,
      ),
      Message(
        id: _uuid.v4(),
        sessionKey: sessionKey,
        role: MessageRole.assistant.value,
        content: '''Of course! This is ClawChat, a mobile client for OpenClaw Gateway.

Here's what you can do:
- **Send messages** to AI agents
- **View streaming responses** in real-time
- **Manage multiple sessions**

Feel free to ask any questions!''',
        createdAt: now.subtract(const Duration(minutes: 3)),
        isComplete: true,
      ),
    ];
    state = ChatState(messages: messages);
  }

  /// Send a user message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Create user message
    final userMessage = Message(
      id: _uuid.v4(),
      sessionKey: sessionKey,
      role: MessageRole.user.value,
      content: content.trim(),
      createdAt: DateTime.now(),
      isComplete: true,
    );

    // Add user message immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    // Simulate AI response with streaming
    await _simulateAIResponse(content);
  }

  /// Retry the last failed operation
  Future<void> retryLastMessage() async {
    if (!state.canRetry) return;

    // Get last user message
    final lastUserMessage = state.messages.lastWhere(
      (m) => m.role == MessageRole.user.value,
      orElse: () => throw StateError('No user message to retry'),
    );

    state = state.copyWith(
      isLoading: true,
      isRetrying: true,
      clearError: true,
    );

    // Retry the AI response
    await _simulateAIResponse(lastUserMessage.content);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Simulate AI response (mock for UI development)
  Future<void> _simulateAIResponse(String userContent) async {
    final responseId = _uuid.v4();

    // Create streaming message
    final streamingMessage = Message(
      id: responseId,
      sessionKey: sessionKey,
      role: MessageRole.assistant.value,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
      isComplete: false,
    );

    state = state.copyWith(
      messages: [...state.messages, streamingMessage],
    );

    try {
      // Simulate streaming text
      final responses = _getMockResponse(userContent);
      String fullContent = '';

      for (final chunk in responses) {
        await Future.delayed(const Duration(milliseconds: 50));
        fullContent += chunk;

        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == responseId) {
              return m.copyWith(content: fullContent);
            }
            return m;
          }).toList(),
        );
      }

      // Mark as complete
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == responseId) {
            return m.copyWith(
              isStreaming: false,
              isComplete: true,
            );
          }
          return m;
        }).toList(),
        isLoading: false,
        isRetrying: false,
      );
    } catch (e, stackTrace) {
      // Handle error using unified error handling
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'ChatNotifier._simulateAIResponse',
      );

      // Remove the streaming message
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != responseId).toList(),
        isLoading: false,
        isRetrying: false,
        error: result.exception,
      );
    }
  }

  /// Get mock AI response based on user input
  List<String> _getMockResponse(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello! Great to hear from you. How can I assist you today?'
          .split('')
          .map((c) => c == ' ' ? ' ' : c)
          .toList();
    }

    if (lower.contains('help')) {
      return '''I'm here to help! Here are some things I can do:
- Answer questions
- Help with coding
- Provide explanations
- Chat with you

What would you like to know?'''
          .split('')
          .toList();
    }

    if (lower.contains('code') || lower.contains('flutter')) {
      return '''Flutter is a great choice for cross-platform development!

Here's a quick example:
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello, Flutter!');
  }
}
```

Want to learn more?'''
          .split('')
          .toList();
    }

    // Default response
    return 'I received your message: "$input". This is a mock response for UI development. In the real implementation, this would be connected to OpenClaw Gateway via WebSocket.'
        .split('')
        .toList();
  }

  /// Clear all messages
  void clearMessages() {
    state = const ChatState();
  }

  /// Delete a specific message
  void deleteMessage(String messageId) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }
}

/// Provider for chat controller
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, sessionKey) => ChatNotifier(sessionKey: sessionKey),
);

/// Provider for current session key (mock)
final currentSessionKeyProvider = Provider<String>((ref) {
  return 'session-default';
});

/// Connection state for the chat
class ChatConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final bool isReconnecting;
  final int reconnectAttempts;
  final AppException? lastError;

  const ChatConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isReconnecting = false,
    this.reconnectAttempts = 0,
    this.lastError,
  });

  ChatConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isReconnecting,
    int? reconnectAttempts,
    AppException? lastError,
    bool clearError = false,
  }) {
    return ChatConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  bool get hasError => lastError != null;
  bool get canRetry => lastError?.isRecoverable ?? false;
}

/// Connection state provider
final connectionStateProvider = StateProvider<ChatConnectionState>((ref) {
  return const ChatConnectionState();
});