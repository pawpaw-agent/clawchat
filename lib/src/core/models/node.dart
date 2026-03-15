/// Node model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'node.freezed.dart';
part 'node.g.dart';

/// Node status enum
enum NodeStatus {
  online,
  offline,
  busy,
  error,
}

/// Node model - represents a connected device/endpoint
@freezed
class Node with _$Node {
  const factory Node({
    required String id,
    String? displayName,
    String? platform,
    String? host,
    @Default([]) List<String> caps,
    @Default([]) List<String> commands,
    NodeStatus? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? version,
    Map<String, dynamic>? metadata,
  }) = _Node;

  factory Node.fromJson(Map<String, dynamic> json) =>
      _$NodeFromJson(json);
}

/// Node detail - extended information about a node
@freezed
class NodeDetail with _$NodeDetail {
  const factory NodeDetail({
    required String id,
    String? displayName,
    String? platform,
    String? host,
    @Default([]) List<String> caps,
    @Default([]) List<String> commands,
    NodeStatus? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? version,
    Map<String, dynamic>? metadata,
    // Extended details
    @Default({}) Map<String, CommandInfo> commandDetails,
    @Default({}) Map<String, dynamic> capabilities,
    String? publicKey,
    int? uptimeSeconds,
  }) = _NodeDetail;

  factory NodeDetail.fromJson(Map<String, dynamic> json) =>
      _$NodeDetailFromJson(json);
}

/// Command information
@freezed
class CommandInfo with _$CommandInfo {
  const factory CommandInfo({
    required String name,
    String? description,
    @Default({}) Map<String, dynamic> params,
    String? resultType,
  }) = _CommandInfo;

  factory CommandInfo.fromJson(Map<String, dynamic> json) =>
      _$CommandInfoFromJson(json);
}

/// Node invoke result
@freezed
class NodeInvokeResult with _$NodeInvokeResult {
  const factory NodeInvokeResult({
    required String id,
    required String nodeId,
    required String command,
    required bool success,
    dynamic result,
    String? error,
    DateTime? completedAt,
  }) = _NodeInvokeResult;

  factory NodeInvokeResult.fromJson(Map<String, dynamic> json) =>
      _$NodeInvokeResultFromJson(json);
}