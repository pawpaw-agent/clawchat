/// Isar collection for Message persistence
library;

import 'package:isar/isar.dart';

part 'message_collection.g.dart';

/// Message collection for Isar database
@collection
class MessageCollection {
  /// Primary key (auto-increment)
  Id id = Isar.autoIncrement;

  /// Unique message ID (from Gateway)
  @Index(unique: true)
  late String messageId;

  /// Session key this message belongs to
  @Index()
  late String sessionKey;

  /// Message role: user, assistant, system
  late String role;

  /// Message content (text)
  late String content;

  /// Media URLs (JSON array string)
  String? mediaUrlsJson;

  /// Creation timestamp (milliseconds since epoch)
  @Index()
  late int createdAtMs;

  /// Update timestamp (milliseconds since epoch)
  int? updatedAtMs;

  /// Whether message is currently streaming
  bool isStreaming = false;

  /// Whether message streaming is complete
  bool isComplete = false;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': messageId,
      'sessionKey': sessionKey,
      'role': role,
      'content': content,
      'mediaUrls': mediaUrlsJson != null 
          ? _parseMediaUrls(mediaUrlsJson!) 
          : <String>[],
      'createdAt': DateTime.fromMillisecondsSinceEpoch(createdAtMs).toIso8601String(),
      'updatedAt': updatedAtMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs!).toIso8601String()
          : null,
      'isStreaming': isStreaming,
      'isComplete': isComplete,
    };
  }

  /// Parse media URLs from JSON string
  static List<String> _parseMediaUrls(String json) {
    // Simple parsing: remove brackets and quotes, split by comma
    // For production, use json_decode
    if (json.isEmpty || json == '[]') return [];
    return json
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Create from JSON map
  static MessageCollection fromJson(Map<String, dynamic> json) {
    final collection = MessageCollection()
      ..messageId = json['id'] as String
      ..sessionKey = json['sessionKey'] as String
      ..role = json['role'] as String
      ..content = json['content'] as String
      ..isStreaming = json['isStreaming'] as bool? ?? false
      ..isComplete = json['isComplete'] as bool? ?? false;

    // Handle media URLs
    final mediaUrls = json['mediaUrls'] as List<dynamic>?;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      collection.mediaUrlsJson = mediaUrls.map((e) => '"$e"').join(',');
    }

    // Handle timestamps
    if (json['createdAt'] != null) {
      collection.createdAtMs = DateTime.parse(json['createdAt'] as String).millisecondsSinceEpoch;
    } else {
      collection.createdAtMs = DateTime.now().millisecondsSinceEpoch;
    }

    if (json['updatedAt'] != null) {
      collection.updatedAtMs = DateTime.parse(json['updatedAt'] as String).millisecondsSinceEpoch;
    }

    return collection;
  }
}