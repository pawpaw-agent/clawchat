/// Agent model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent.freezed.dart';
part 'agent.g.dart';

/// Agent information
@freezed
class Agent with _$Agent {
  const factory Agent({
    required String id,
    String? name,
    String? avatar,
    String? emoji,
    String? description,
    @Default([]) List<String> capabilities,
    String? model,
  }) = _Agent;

  factory Agent.fromJson(Map<String, dynamic> json) =>
      _$AgentFromJson(json);
}

/// Agent identity response
@freezed
class AgentIdentity with _$AgentIdentity {
  const factory AgentIdentity({
    required String agentId,
    String? name,
    String? avatar,
    String? emoji,
  }) = _AgentIdentity;

  factory AgentIdentity.fromJson(Map<String, dynamic> json) =>
      _$AgentIdentityFromJson(json);
}