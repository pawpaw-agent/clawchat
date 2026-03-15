/// Message model
library;

/// Message in a conversation
class Message {
  final String id;
  final String sessionKey;
  final String role;
  final String content;
  final List<String> mediaUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isStreaming;
  final bool isComplete;

  const Message({
    required this.id,
    required this.sessionKey,
    required this.role,
    required this.content,
    this.mediaUrls = const [],
    this.createdAt,
    this.updatedAt,
    this.isStreaming = false,
    this.isComplete = false,
  });

  /// Create a copy with updated fields
  Message copyWith({
    String? id,
    String? sessionKey,
    String? role,
    String? content,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStreaming,
    bool? isComplete,
  }) {
    return Message(
      id: id ?? this.id,
      sessionKey: sessionKey ?? this.sessionKey,
      role: role ?? this.role,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStreaming: isStreaming ?? this.isStreaming,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionKey': sessionKey,
      'role': role,
      'content': content,
      'mediaUrls': mediaUrls,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isStreaming': isStreaming,
      'isComplete': isComplete,
    };
  }

  /// Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionKey: json['sessionKey'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isStreaming: json['isStreaming'] as bool? ?? false,
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Message role
enum MessageRole {
  user('user'),
  assistant('assistant'),
  system('system');

  final String value;
  const MessageRole(this.value);
}