/// Event models for UI state
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

/// Base event for state management
sealed class AppEvent {
  const AppEvent();
}

/// Connection state changed
class ConnectionStateChanged extends AppEvent {
  final bool isConnected;
  final bool isAuthenticated;
  final String? error;

  const ConnectionStateChanged({
    required this.isConnected,
    required this.isAuthenticated,
    this.error,
  });
}

/// New message received
class MessageReceived extends AppEvent {
  final String sessionKey;
  final String messageId;
  final String content;
  final bool isStreaming;

  const MessageReceived({
    required this.sessionKey,
    required this.messageId,
    required this.content,
    this.isStreaming = false,
  });
}

/// Message updated (streaming)
class MessageUpdated extends AppEvent {
  final String sessionKey;
  final String messageId;
  final String content;
  final bool isComplete;

  const MessageUpdated({
    required this.sessionKey,
    required this.messageId,
    required this.content,
    this.isComplete = false,
  });
}

/// Session list updated
class SessionsUpdated extends AppEvent {
  final List<String> sessionKeys;

  const SessionsUpdated(this.sessionKeys);
}

/// Agent run event (streaming)
@freezed
class AgentRunEvent with _$AgentRunEvent {
  const factory AgentRunEvent({
    required String runId,
    required int seq,
    required String stream,
    required DateTime ts,
    required Map<String, dynamic> data,
  }) = _AgentRunEvent;

  factory AgentRunEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentRunEventFromJson(json);
}