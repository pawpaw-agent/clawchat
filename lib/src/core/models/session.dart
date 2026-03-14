/// Session model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Chat session
@freezed
class Session with _$Session {
  const factory Session({
    required String key,
    String? label,
    String? agentId,
    String? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(0) int messageCount,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}