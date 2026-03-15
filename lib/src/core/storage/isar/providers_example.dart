/// Example integration with Riverpod providers
/// 
/// This file demonstrates how to integrate IsarService with Riverpod
/// for state management in the ClawChat app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/session.dart';
import 'isar/isar_service.dart';
import 'isar/model_converters.dart';

/// Isar service provider
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

/// Initialize Isar database
final isarInitializedProvider = FutureProvider<bool>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  return await isarService.init();
});

/// Messages for a specific session
final messagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, sessionKey) async {
    final isarService = ref.watch(isarServiceProvider);
    final collections = await isarService.getMessagesBySession(sessionKey);
    return collections.map(messageToModel).toList();
  },
);

/// Paginated messages for a session
final messagesPaginatedProvider = FutureProvider.family<List<Message>, MessagesParams>(
  (ref, params) async {
    final isarService = ref.watch(isarServiceProvider);
    final collections = await isarService.getMessagesPaginated(
      params.sessionKey,
      limit: params.limit,
      offset: params.offset,
    );
    return collections.map(messageToModel).toList();
  },
);

/// All sessions
final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  final collections = await isarService.getAllSessions();
  return collections.map(sessionToModel).toList();
});

/// Pinned sessions
final pinnedSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  final collections = await isarService.getPinnedSessions();
  return collections.map(sessionToModel).toList();
});

/// Message count for a session
final messageCountProvider = FutureProvider.family<int, String>(
  (ref, sessionKey) async {
    final isarService = ref.watch(isarServiceProvider);
    return await isarService.getMessageCount(sessionKey);
  },
);

/// Database statistics
final dbStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  return await isarService.getStats();
});

/// Parameters for paginated messages
class MessagesParams {
  final String sessionKey;
  final int limit;
  final int offset;

  const MessagesParams({
    required this.sessionKey,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesParams &&
          runtimeType == other.runtimeType &&
          sessionKey == other.sessionKey &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(sessionKey, limit, offset);
}

/// Notifier for managing messages (with write operations)
class MessageNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final IsarService _isarService;
  final String sessionKey;

  MessageNotifier(this._isarService, this.sessionKey)
      : super(const AsyncValue.loading());

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final collections = await _isarService.getMessagesBySession(sessionKey);
      return collections.map(messageToModel).toList();
    });
  }

  Future<void> addMessage(Message message) async {
    await _isarService.saveMessage(messageToCollection(message));
    await loadMessages();
  }

  Future<void> updateMessage(String messageId, String newContent) async {
    await _isarService.updateMessage(messageId, newContent: newContent);
    await loadMessages();
  }

  Future<void> deleteMessage(String messageId) async {
    await _isarService.deleteMessage(messageId);
    await loadMessages();
  }
}

/// Provider for MessageNotifier
final messageNotifierProvider = StateNotifierProvider.family<MessageNotifier, AsyncValue<List<Message>>, String>(
  (ref, sessionKey) {
    final isarService = ref.watch(isarServiceProvider);
    return MessageNotifier(isarService, sessionKey);
  },
);

/// Notifier for managing sessions (with write operations)
class SessionNotifier extends StateNotifier<AsyncValue<List<Session>>> {
  final IsarService _isarService;

  SessionNotifier(this._isarService) : super(const AsyncValue.loading());

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final collections = await _isarService.getAllSessions();
      return collections.map(sessionToModel).toList();
    });
  }

  Future<void> addSession(Session session) async {
    await _isarService.saveSession(sessionToCollection(session));
    await loadSessions();
  }

  Future<void> updateSessionLabel(String sessionKey, String label) async {
    await _isarService.updateSession(sessionKey, label: label);
    await loadSessions();
  }

  Future<void> toggleArchive(String sessionKey, bool archived) async {
    await _isarService.updateSession(sessionKey, isArchived: archived);
    await loadSessions();
  }

  Future<void> togglePin(String sessionKey, bool pinned) async {
    await _isarService.updateSession(sessionKey, isPinned: pinned);
    await loadSessions();
  }

  Future<void> deleteSession(String sessionKey) async {
    await _isarService.deleteSession(sessionKey);
    await loadSessions();
  }
}

/// Provider for SessionNotifier
final sessionNotifierProvider = StateNotifierProvider<SessionNotifier, AsyncValue<List<Session>>>(
  (ref) {
    final isarService = ref.watch(isarServiceProvider);
    return SessionNotifier(isarService);
  },
);