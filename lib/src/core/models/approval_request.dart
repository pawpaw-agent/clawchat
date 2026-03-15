/// Approval request model for exec.approval.requested event
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_request.freezed.dart';
part 'approval_request.g.dart';

/// Approval decision types
enum ApprovalDecision {
  allowOnce,
  allowAlways,
  deny,
}

/// Approval request status
enum ApprovalStatus {
  pending,
  approved,
  denied,
  expired,
}

/// Approval request - represents an exec approval request from Gateway
@freezed
class ApprovalRequest with _$ApprovalRequest {
  const factory ApprovalRequest({
    required String id,
    required String command,
    @Default([]) List<String> commandArgv,
    String? cwd,
    required String nodeId,
    String? security,
    @Default(ApprovalStatus.pending) ApprovalStatus status,
    ApprovalDecision? decision,
    DateTime? requestedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) = _ApprovalRequest;

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestFromJson(json);
}

/// Extension for ApprovalDecision
extension ApprovalDecisionExtension on ApprovalDecision {
  /// Convert to API string format
  String toApiString() {
    return switch (this) {
      ApprovalDecision.allowOnce => 'allow-once',
      ApprovalDecision.allowAlways => 'allow-always',
      ApprovalDecision.deny => 'deny',
    };
  }

  /// Display text in Chinese
  String get displayText {
    return switch (this) {
      ApprovalDecision.allowOnce => '允许一次',
      ApprovalDecision.allowAlways => '始终允许',
      ApprovalDecision.deny => '拒绝',
    };
  }

  /// Icon for the decision
  String get icon {
    return switch (this) {
      ApprovalDecision.allowOnce => '✓',
      ApprovalDecision.allowAlways => '✓✓',
      ApprovalDecision.deny => '✗',
    };
  }
}

/// Extension for ApprovalStatus
extension ApprovalStatusExtension on ApprovalStatus {
  /// Display text in Chinese
  String get displayText {
    return switch (this) {
      ApprovalStatus.pending => '待处理',
      ApprovalStatus.approved => '已允许',
      ApprovalStatus.denied => '已拒绝',
      ApprovalStatus.expired => '已过期',
    };
  }
}

/// Factory for creating ApprovalRequest from Gateway event
class ApprovalRequestFactory {
  /// Create from exec.approval.requested event payload
  static ApprovalRequest fromEvent(Map<String, dynamic> payload) {
    return ApprovalRequest(
      id: payload['id'] as String? ?? '',
      command: payload['command'] as String? ?? '',
      commandArgv: (payload['commandArgv'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cwd: payload['cwd'] as String?,
      nodeId: payload['nodeId'] as String? ?? '',
      security: payload['security'] as String?,
      requestedAt: DateTime.now(),
    );
  }
}