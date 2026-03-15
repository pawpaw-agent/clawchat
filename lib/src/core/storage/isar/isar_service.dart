/// Isar database service for local persistence
library;

import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import 'collections/message_collection.dart';
import 'collections/session_collection.dart';

/// Isar database service
class IsarService {
  /// Singleton instance
  static final IsarService _instance = IsarService._internal();
  
  /// Factory constructor
  factory IsarService() => _instance;
  
  /// Internal constructor
  IsarService._internal();

  /// Isar database instance
  Isar? _db;

  /// Logger instance
  final _logger = Logger();

  /// Get database instance
  Isar get db {
    if (_db == null) {
      throw StateError('Isar database not initialized. Call init() first.');
    }
    return _db!;
  }

  /// Initialize Isar database
  /// 
  /// Returns true if initialization successful
  Future<bool> init() async {
    try {
      // Get application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/clawchat';
      
      _logger.i('Initializing Isar database at: $dbPath');

      // Open database with collections
      _db = await Isar.open(
        [MessageCollectionSchema, SessionCollectionSchema],
        directory: dbPath,
        inspector: true, // Enable inspector for debug
      );

      _logger.i('Isar database initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Isar database', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
      _logger.i('Isar database closed');
    }
  }

  /// Get database path
  Future<String?> getDatabasePath() async {
    if (_db == null) return null;
    return _db!.directory;
  }

  // ==================== Message Operations ====================

  /// Save a message to database
  Future<bool> saveMessage(MessageCollection message) async {
    try {
      await db.writeTxn(() async {
        await db.messageCollections.put(message);
      });
      _logger.d('Message saved: ${message.messageId}');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to save message', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Save multiple messages to database
  Future<bool> saveMessages(List<MessageCollection> messages) async {
    try {
      await db.writeTxn(() async {
        await db.messageCollections.putAll(messages);
      });
      _logger.d('Saved ${messages.length} messages');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to save messages', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get message by ID
  Future<MessageCollection?> getMessage(String messageId) async {
    try {
      return await db.messageCollections
          .where()
          .messageIdEqualTo(messageId)
          .findFirst();
    } catch (e, stackTrace) {
      _logger.e('Failed to get message', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all messages for a session
  Future<List<MessageCollection>> getMessagesBySession(String sessionKey) async {
    try {
      return await db.messageCollections
          .where()
          .sessionKeyEqualTo(sessionKey)
          .sortByCreatedAtMs()
          .findAll();
    } catch (e, stackTrace) {
      _logger.e('Failed to get messages for session', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get messages for a session with pagination
  Future<List<MessageCollection>> getMessagesPaginated(
    String sessionKey, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await db.messageCollections
          .where()
          .sessionKeyEqualTo(sessionKey)
          .sortByCreatedAtMsDesc()
          .offset(offset)
          .limit(limit)
          .findAll();
    } catch (e, stackTrace) {
      _logger.e('Failed to get paginated messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update message content
  Future<bool> updateMessage(String messageId, String newContent) async {
    try {
      await db.writeTxn(() async {
        final message = await db.messageCollections
            .where()
            .messageIdEqualTo(messageId)
            .findFirst();
        
        if (message != null) {
          message.content = newContent;
          message.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
          await db.messageCollections.put(message);
        }
      });
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to update message', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update message streaming status
  Future<bool> updateMessageStreaming(
    String messageId, {
    required bool isStreaming,
    bool? isComplete,
  }) async {
    try {
      await db.writeTxn(() async {
        final message = await db.messageCollections
            .where()
            .messageIdEqualTo(messageId)
            .findFirst();
        
        if (message != null) {
          message.isStreaming = isStreaming;
          if (isComplete != null) message.isComplete = isComplete;
          message.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
          await db.messageCollections.put(message);
        }
      });
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to update message streaming status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete message by ID
  Future<bool> deleteMessage(String messageId) async {
    try {
      await db.writeTxn(() async {
        await db.messageCollections
            .where()
            .messageIdEqualTo(messageId)
            .deleteFirst();
      });
      _logger.d('Message deleted: $messageId');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to delete message', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete all messages for a session
  Future<int> deleteMessagesBySession(String sessionKey) async {
    try {
      int count = 0;
      await db.writeTxn(() async {
        count = await db.messageCollections
            .where()
            .sessionKeyEqualTo(sessionKey)
            .deleteAll();
      });
      _logger.d('Deleted $count messages for session: $sessionKey');
      return count;
    } catch (e, stackTrace) {
      _logger.e('Failed to delete messages for session', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get message count for a session
  Future<int> getMessageCount(String sessionKey) async {
    try {
      return await db.messageCollections
          .where()
          .sessionKeyEqualTo(sessionKey)
          .count();
    } catch (e, stackTrace) {
      _logger.e('Failed to count messages', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  // ==================== Session Operations ====================

  /// Save a session to database
  Future<bool> saveSession(SessionCollection session) async {
    try {
      await db.writeTxn(() async {
        await db.sessionCollections.put(session);
      });
      _logger.d('Session saved: ${session.sessionKey}');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to save session', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Save multiple sessions to database
  Future<bool> saveSessions(List<SessionCollection> sessions) async {
    try {
      await db.writeTxn(() async {
        await db.sessionCollections.putAll(sessions);
      });
      _logger.d('Saved ${sessions.length} sessions');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to save sessions', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get session by key
  Future<SessionCollection?> getSession(String sessionKey) async {
    try {
      return await db.sessionCollections
          .where()
          .sessionKeyEqualTo(sessionKey)
          .findFirst();
    } catch (e, stackTrace) {
      _logger.e('Failed to get session', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all sessions
  Future<List<SessionCollection>> getAllSessions({
    bool includeArchived = false,
  }) async {
    try {
      if (includeArchived) {
        return await db.sessionCollections
            .where()
            .sortByLastActiveAtMsDesc()
            .findAll();
      } else {
        return await db.sessionCollections
            .where()
            .isArchivedEqualTo(false)
            .sortByLastActiveAtMsDesc()
            .findAll();
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get sessions', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get pinned sessions
  Future<List<SessionCollection>> getPinnedSessions() async {
    try {
      return await db.sessionCollections
          .where()
          .isPinnedEqualTo(true)
          .sortByLastActiveAtMsDesc()
          .findAll();
    } catch (e, stackTrace) {
      _logger.e('Failed to get pinned sessions', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update session last message
  Future<bool> updateSessionLastMessage(
    String sessionKey,
    String lastMessage,
  ) async {
    try {
      await db.writeTxn(() async {
        final session = await db.sessionCollections
            .where()
            .sessionKeyEqualTo(sessionKey)
            .findFirst();
        
        if (session != null) {
          session.lastMessage = lastMessage;
          session.lastActiveAtMs = DateTime.now().millisecondsSinceEpoch;
          session.messageCount += 1;
          await db.sessionCollections.put(session);
        }
      });
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to update session last message', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update session properties
  Future<bool> updateSession(
    String sessionKey, {
    String? label,
    bool? isArchived,
    bool? isPinned,
  }) async {
    try {
      await db.writeTxn(() async {
        final session = await db.sessionCollections
            .where()
            .sessionKeyEqualTo(sessionKey)
            .findFirst();
        
        if (session != null) {
          if (label != null) session.label = label;
          if (isArchived != null) session.isArchived = isArchived;
          if (isPinned != null) session.isPinned = isPinned;
          session.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
          await db.sessionCollections.put(session);
        }
      });
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to update session', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete session by key
  Future<bool> deleteSession(String sessionKey) async {
    try {
      // First delete all messages in this session
      await deleteMessagesBySession(sessionKey);
      
      // Then delete the session
      await db.writeTxn(() async {
        await db.sessionCollections
            .where()
            .sessionKeyEqualTo(sessionKey)
            .deleteFirst();
      });
      _logger.d('Session deleted: $sessionKey');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to delete session', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get total session count
  Future<int> getSessionCount({bool includeArchived = false}) async {
    try {
      if (includeArchived) {
        return await db.sessionCollections.where().count();
      } else {
        return await db.sessionCollections
            .where()
            .isArchivedEqualTo(false)
            .count();
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to count sessions', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Clear all data (for logout/reset)
  Future<bool> clearAll() async {
    try {
      await db.writeTxn(() async {
        await db.clear();
      });
      _logger.i('All data cleared');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to clear all data', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ==================== Statistics ====================

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final messageCount = await db.messageCollections.where().count();
      final sessionCount = await db.sessionCollections.where().count();
      final dbPath = await getDatabasePath();
      
      return {
        'messageCount': messageCount,
        'sessionCount': sessionCount,
        'databasePath': dbPath,
      };
    } catch (e, stackTrace) {
      _logger.e('Failed to get stats', error: e, stackTrace: stackTrace);
      return {};
    }
  }
}