/// Isar collection for Session persistence
library;

import 'package:isar/isar.dart';

part 'session_collection.g.dart';

/// Session collection for Isar database
@collection
class SessionCollection {
  /// Primary key (auto-increment)
  Id id = Isar.autoIncrement;

  /// Unique session key (from Gateway)
  @Index(unique: true)
  late String sessionKey;

  /// Session label (user-defined name)
  String? label;

  /// Agent ID associated with this session
  String? agentId;

  /// Last message preview
  String? lastMessage;

  /// Creation timestamp (milliseconds since epoch)
  @Index()
  late int createdAtMs;

  /// Update timestamp (milliseconds since epoch)
  int? updatedAtMs;

  /// Last active timestamp (milliseconds since epoch)
  @Index()
  int? lastActiveAtMs;

  /// Whether session is archived
  @Index()
  bool isArchived = false;

  /// Whether session is pinned
  @Index()
  bool isPinned = false;

  /// Message count in this session
  int messageCount = 0;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'key': sessionKey,
      'label': label,
      'agentId': agentId,
      'lastMessage': lastMessage,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(createdAtMs).toIso8601String(),
      'updatedAt': updatedAtMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs!).toIso8601String()
          : null,
      'lastActiveAt': lastActiveAtMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastActiveAtMs!).toIso8601String()
          : null,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'messageCount': messageCount,
    };
  }

  /// Create from JSON map
  static SessionCollection fromJson(Map<String, dynamic> json) {
    final collection = SessionCollection()
      ..sessionKey = json['key'] as String
      ..label = json['label'] as String?
      ..agentId = json['agentId'] as String?
      ..lastMessage = json['lastMessage'] as String?
      ..isArchived = json['isArchived'] as bool? ?? false
      ..isPinned = json['isPinned'] as bool? ?? false
      ..messageCount = json['messageCount'] as int? ?? 0;

    // Handle timestamps
    if (json['createdAt'] != null) {
      collection.createdAtMs = DateTime.parse(json['createdAt'] as String).millisecondsSinceEpoch;
    } else {
      collection.createdAtMs = DateTime.now().millisecondsSinceEpoch;
    }

    if (json['updatedAt'] != null) {
      collection.updatedAtMs = DateTime.parse(json['updatedAt'] as String).millisecondsSinceEpoch;
    }

    if (json['lastActiveAt'] != null) {
      collection.lastActiveAtMs = DateTime.parse(json['lastActiveAt'] as String).millisecondsSinceEpoch;
    }

    return collection;
  }
}