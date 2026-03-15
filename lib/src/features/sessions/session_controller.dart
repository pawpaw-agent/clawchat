/// Session controller with Riverpod state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/session.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Session state
class SessionState {
  final List<Session> sessions;
  final bool isLoading;
  final bool isRefreshing;
  final AppException? error;
  final String? activeSessionKey;

  const SessionState({
    this.sessions = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.activeSessionKey,
  });

  SessionState copyWith({
    List<Session>? sessions,
    bool? isLoading,
    bool? isRefreshing,
    AppException? error,
    String? activeSessionKey,
    bool clearActiveSession = false,
    bool clearError = false,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      activeSessionKey: clearActiveSession ? null : (activeSessionKey ?? this.activeSessionKey),
    );
  }

  /// Get active session
  Session? get activeSession {
    if (activeSessionKey == null) return null;
    try {
      return sessions.firstWhere((s) => s.key == activeSessionKey);
    } catch (_) {
      return null;
    }
  }

  /// Get sorted sessions (pinned first, then by lastActiveAt)
  List<Session> get sortedSessions {
    final sorted = List<Session>.from(sessions);
    sorted.sort((a, b) {
      // Pinned first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // Then by lastActiveAt (newest first)
      final aTime = a.lastActiveAt ?? a.updatedAt ?? a.createdAt;
      final bTime = b.lastActiveAt ?? b.updatedAt ?? b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  /// Whether there's an error
  bool get hasError => error != null;

  /// Whether error is recoverable (can retry)
  bool get canRetry => error?.isRecoverable ?? false;
}

/// Session notifier with error handling
class SessionNotifier extends StateNotifier<SessionState> with ErrorHandlingMixin {
  SessionNotifier() : super(const SessionState()) {
    _loadMockData();
  }

  /// Load mock data for development
  void _loadMockData() {
    state = state.copyWith(isLoading: true);

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final now = DateTime.now();
      final mockSessions = [
        Session(
          key: 'session-1',
          label: 'Project Planning',
          agentId: 'agent-forge',
          lastMessage: 'Let me create a task breakdown for the milestone...',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(hours: 1)),
          lastActiveAt: now.subtract(const Duration(hours: 1)),
          isPinned: true,
          messageCount: 42,
        ),
        Session(
          key: 'session-2',
          label: 'Code Review',
          agentId: 'agent-forge',
          lastMessage: 'I found 3 issues that need attention...',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(hours: 3)),
          lastActiveAt: now.subtract(const Duration(hours: 3)),
          isPinned: false,
          messageCount: 18,
        ),
        Session(
          key: 'session-3',
          label: 'Bug Investigation',
          agentId: 'agent-research',
          lastMessage: 'The root cause appears to be a race condition...',
          createdAt: now.subtract(const Duration(hours: 12)),
          updatedAt: now.subtract(const Duration(hours: 6)),
          lastActiveAt: now.subtract(const Duration(hours: 6)),
          isPinned: false,
          messageCount: 27,
        ),
        Session(
          key: 'session-4',
          label: 'Documentation',
          agentId: 'agent-ko',
          lastMessage: 'API documentation has been updated...',
          createdAt: now.subtract(const Duration(hours: 8)),
          updatedAt: now.subtract(const Duration(hours: 2)),
          lastActiveAt: now.subtract(const Duration(hours: 2)),
          isArchived: true,
          messageCount: 15,
        ),
      ];

      state = state.copyWith(
        sessions: mockSessions,
        isLoading: false,
      );
    });
  }

  /// Create new session
  Future<Session> createSession({
    String? label,
    String? agentId,
  }) async {
    try {
      final now = DateTime.now();
      final newSession = Session(
        key: 'session-${now.millisecondsSinceEpoch}',
        label: label ?? 'New Chat',
        agentId: agentId ?? 'agent-forge',
        createdAt: now,
        updatedAt: now,
        lastActiveAt: now,
        messageCount: 0,
      );

      state = state.copyWith(
        sessions: [...state.sessions, newSession],
        activeSessionKey: newSession.key,
        clearError: true,
      );

      return newSession;
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.createSession',
      );
      state = state.copyWith(error: result.exception);
      rethrow;
    }
  }

  /// Delete session
  Future<void> deleteSession(String sessionKey) async {
    try {
      final sessions = state.sessions.where((s) => s.key != sessionKey).toList();
      state = state.copyWith(
        sessions: sessions,
        activeSessionKey: state.activeSessionKey == sessionKey
            ? null
            : state.activeSessionKey,
        clearError: true,
      );
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.deleteSession',
      );
      state = state.copyWith(error: result.exception);
      rethrow;
    }
  }

  /// Archive/unarchive session
  Future<void> toggleArchive(String sessionKey) async {
    try {
      final sessions = state.sessions.map((s) {
        if (s.key == sessionKey) {
          return s.copyWith(isArchived: !s.isArchived);
        }
        return s;
      }).toList();
      state = state.copyWith(sessions: sessions, clearError: true);
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.toggleArchive',
      );
      state = state.copyWith(error: result.exception);
    }
  }

  /// Pin/unpin session
  Future<void> togglePin(String sessionKey) async {
    try {
      final sessions = state.sessions.map((s) {
        if (s.key == sessionKey) {
          return s.copyWith(isPinned: !s.isPinned);
        }
        return s;
      }).toList();
      state = state.copyWith(sessions: sessions, clearError: true);
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.togglePin',
      );
      state = state.copyWith(error: result.exception);
    }
  }

  /// Update session label
  Future<void> updateLabel(String sessionKey, String label) async {
    try {
      final sessions = state.sessions.map((s) {
        if (s.key == sessionKey) {
          return s.copyWith(label: label, updatedAt: DateTime.now());
        }
        return s;
      }).toList();
      state = state.copyWith(sessions: sessions, clearError: true);
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.updateLabel',
      );
      state = state.copyWith(error: result.exception);
    }
  }

  /// Set active session
  void setActiveSession(String? sessionKey) {
    if (sessionKey == null) {
      state = state.copyWith(clearActiveSession: true);
    } else {
      state = state.copyWith(activeSessionKey: sessionKey);
    }
  }

  /// Refresh sessions
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(isRefreshing: false);
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.refresh',
      );
      state = state.copyWith(
        isRefreshing: false,
        error: result.exception,
      );
    }
  }

  /// Clear all sessions
  Future<void> clearAll() async {
    try {
      state = const SessionState();
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'SessionNotifier.clearAll',
      );
      state = state.copyWith(error: result.exception);
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Retry the last failed operation
  Future<void> retry() async {
    if (!state.canRetry) return;
    await refresh();
  }
}

/// Session state provider
final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref: ref);
});

/// Active session provider
final activeSessionProvider = Provider<Session?>((ref) {
  final state = ref.watch(sessionProvider);
  return state.activeSession;
});

/// Sorted sessions provider
final sortedSessionsProvider = Provider<List<Session>>((ref) {
  final state = ref.watch(sessionProvider);
  return state.sortedSessions;
});

/// Sessions filtered by archive status
final activeSessionsProvider = Provider<List<Session>>((ref) {
  final sessions = ref.watch(sortedSessionsProvider);
  return sessions.where((s) => !s.isArchived).toList();
});

final archivedSessionsProvider = Provider<List<Session>>((ref) {
  final sessions = ref.watch(sortedSessionsProvider);
  return sessions.where((s) => s.isArchived).toList();
});