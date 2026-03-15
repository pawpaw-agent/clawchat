/// Model converters between freezed models and Isar collections
library;

import '../models/message.dart' as models;
import '../models/session.dart' as models;
import 'collections/message_collection.dart';
import 'collections/session_collection.dart';

/// Convert Message model to MessageCollection
MessageCollection messageToCollection(models.Message message) {
  final collection = MessageCollection()
    ..messageId = message.id
    ..sessionKey = message.sessionKey
    ..role = message.role
    ..content = message.content
    ..isStreaming = message.isStreaming
    ..isComplete = message.isComplete;

  // Handle media URLs
  if (message.mediaUrls.isNotEmpty) {
    collection.mediaUrlsJson = message.mediaUrls.map((e) => '"$e"').join(',');
  }

  // Handle timestamps
  if (message.createdAt != null) {
    collection.createdAtMs = message.createdAt!.millisecondsSinceEpoch;
  } else {
    collection.createdAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  if (message.updatedAt != null) {
    collection.updatedAtMs = message.updatedAt!.millisecondsSinceEpoch;
  }

  return collection;
}

/// Convert MessageCollection to Message model
models.Message messageToModel(MessageCollection collection) {
  List<String> mediaUrls = [];
  if (collection.mediaUrlsJson != null && collection.mediaUrlsJson!.isNotEmpty) {
    // Parse JSON array string
    try {
      final decoded = collection.mediaUrlsJson!
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      mediaUrls = decoded;
    } catch (e) {
      // Ignore parsing errors
    }
  }

  return models.Message(
    id: collection.messageId,
    sessionKey: collection.sessionKey,
    role: collection.role,
    content: collection.content,
    mediaUrls: mediaUrls,
    createdAt: DateTime.fromMillisecondsSinceEpoch(collection.createdAtMs),
    updatedAt: collection.updatedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(collection.updatedAtMs!)
        : null,
    isStreaming: collection.isStreaming,
    isComplete: collection.isComplete,
  );
}

/// Convert Session model to SessionCollection
SessionCollection sessionToCollection(models.Session session) {
  final collection = SessionCollection()
    ..sessionKey = session.key
    ..label = session.label
    ..agentId = session.agentId
    ..lastMessage = session.lastMessage
    ..isArchived = session.isArchived
    ..isPinned = session.isPinned
    ..messageCount = session.messageCount;

  // Handle timestamps
  if (session.createdAt != null) {
    collection.createdAtMs = session.createdAt!.millisecondsSinceEpoch;
  } else {
    collection.createdAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  if (session.updatedAt != null) {
    collection.updatedAtMs = session.updatedAt!.millisecondsSinceEpoch;
  }

  if (session.lastActiveAt != null) {
    collection.lastActiveAtMs = session.lastActiveAt!.millisecondsSinceEpoch;
  }

  return collection;
}

/// Convert SessionCollection to Session model
models.Session sessionToModel(SessionCollection collection) {
  return models.Session(
    key: collection.sessionKey,
    label: collection.label,
    agentId: collection.agentId,
    lastMessage: collection.lastMessage,
    createdAt: DateTime.fromMillisecondsSinceEpoch(collection.createdAtMs),
    updatedAt: collection.updatedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(collection.updatedAtMs!)
        : null,
    lastActiveAt: collection.lastActiveAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(collection.lastActiveAtMs!)
        : null,
    isArchived: collection.isArchived,
    isPinned: collection.isPinned,
    messageCount: collection.messageCount,
  );
}