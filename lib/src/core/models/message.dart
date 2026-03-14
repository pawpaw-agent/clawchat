/// Message model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Message in a conversation
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String sessionKey,
    required String role,
    required String content,
    @Default([]) List<String> mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isStreaming,
    @Default(false) bool isComplete,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// Message role
enum MessageRole {
  user('user'),
  assistant('assistant'),
  system('system');

  final String value;
  const MessageRole(this.value);
}