/// Approval controller with Riverpod state management
/// Handles exec.approval.requested events and manages approval workflow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/approval_request.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Approval state
class ApprovalState {
  /// Pending approval requests (not yet resolved)
  final List<ApprovalRequest> pendingApprovals;
  
  /// Approval history (resolved requests)
  final List<ApprovalRequest> approvalHistory;
  
  /// Currently displayed approval request (for dialog)
  final ApprovalRequest? currentApproval;
  
  /// Whether controller is loading
  final bool isLoading;
  
  /// Error if any
  final AppException? error;

  const ApprovalState({
    this.pendingApprovals = const [],
    this.approvalHistory = const [],
    this.currentApproval,
    this.isLoading = false,
    this.error,
  });

  /// Copy with new values
  ApprovalState copyWith({
    List<ApprovalRequest>? pendingApprovals,
    List<ApprovalRequest>? approvalHistory,
    ApprovalRequest? currentApproval,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    bool clearCurrentApproval = false,
  }) {
    return ApprovalState(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      approvalHistory: approvalHistory ?? this.approvalHistory,
      currentApproval: clearCurrentApproval ? null : (currentApproval ?? this.currentApproval),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get pending count
  int get pendingCount => pendingApprovals.length;
  
  /// Get total history count
  int get historyCount => approvalHistory.length;
  
  /// Has pending approvals
  bool get hasPending => pendingApprovals.isNotEmpty;
  
  /// Has current approval to show
  bool get hasCurrentApproval => currentApproval != null;
  
  /// Whether there's an error
  bool get hasError => error != null;
  
  /// Whether error is recoverable (can retry)
  bool get canRetry => error?.isRecoverable ?? false;
}

/// Approval notifier with error handling
class ApprovalNotifier extends StateNotifier<ApprovalState> with ErrorHandlingMixin {
  final Uuid _uuid;

  ApprovalNotifier({Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const ApprovalState()) {
    // Load mock data for development
    _loadMockData();
  }

  /// Load mock data for development
  void _loadMockData() {
    // Start with empty state - no mock approvals needed
    // Real approvals will come from Gateway events
  }

  /// Handle incoming approval request from Gateway
  /// This is called when exec.approval.requested event is received
  void handleApprovalRequest(ApprovalRequest request) {
    // Add to pending list
    final newPending = [...state.pendingApprovals, request];
    
    // If no current approval is shown, set this one as current
    if (state.currentApproval == null) {
      state = state.copyWith(
        pendingApprovals: newPending,
        currentApproval: request,
      );
    } else {
      state = state.copyWith(pendingApprovals: newPending);
    }
  }

  /// Handle incoming approval request from raw event payload
  void handleApprovalEvent(Map<String, dynamic> payload) {
    final request = ApprovalRequestFactory.fromEvent(payload);
    handleApprovalRequest(request);
  }

  /// Resolve an approval request
  /// Returns true if successful
  Future<bool> resolveApproval({
    required String id,
    required ApprovalDecision decision,
  }) async {
    try {
      // Find the approval in pending list
      final approvalIndex = state.pendingApprovals.indexWhere((a) => a.id == id);
      if (approvalIndex == -1) {
        state = state.copyWith(
          error: GenericAppException(
            message: '找不到审批请求',
            code: 'APPROVAL_NOT_FOUND',
          ),
        );
        return false;
      }

      final approval = state.pendingApprovals[approvalIndex];
      
      // Update approval with decision
      final resolvedApproval = ApprovalRequest(
        id: approval.id,
        command: approval.command,
        commandArgv: approval.commandArgv,
        cwd: approval.cwd,
        nodeId: approval.nodeId,
        security: approval.security,
        status: decision == ApprovalDecision.deny 
            ? ApprovalStatus.denied 
            : ApprovalStatus.approved,
        decision: decision,
        requestedAt: approval.requestedAt,
        resolvedAt: DateTime.now(),
        resolvedBy: 'operator', // TODO: Get actual operator ID
      );

      // Remove from pending and add to history
      final newPending = [...state.pendingApprovals]..removeAt(approvalIndex);
      final newHistory = [resolvedApproval, ...state.approvalHistory];
      
      // Update state
      // If this was the current approval, clear it
      final shouldClearCurrent = state.currentApproval?.id == id;
      
      state = state.copyWith(
        pendingApprovals: newPending,
        approvalHistory: newHistory,
        clearCurrentApproval: shouldClearCurrent,
        clearError: true,
      );

      // TODO: Send resolution to Gateway via WebSocket
      // gateway.send('exec.approval.resolve', {
      //   'id': id,
      //   'decision': decision.toApiString(),
      // });

      // Simulate sending to Gateway (mock)
      await Future.delayed(const Duration(milliseconds: 100));
      
      return true;
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'ApprovalNotifier.resolveApproval',
      );
      state = state.copyWith(error: result.exception);
      return false;
    }
  }

  /// Show next pending approval
  void showNextApproval() {
    if (state.pendingApprovals.isEmpty) {
      state = state.copyWith(clearCurrentApproval: true);
      return;
    }
    
    state = state.copyWith(currentApproval: state.pendingApprovals.first);
  }

  /// Clear current approval (dismiss dialog)
  void dismissCurrentApproval() {
    state = state.copyWith(clearCurrentApproval: true);
  }

  /// Show a specific approval request (from history or pending)
  void showApproval(String id) {
    // Try pending first
    final pending = state.pendingApprovals.where((a) => a.id == id).firstOrNull;
    if (pending != null) {
      state = state.copyWith(currentApproval: pending);
      return;
    }
    
    // Try history
    final historical = state.approvalHistory.where((a) => a.id == id).firstOrNull;
    if (historical != null) {
      state = state.copyWith(currentApproval: historical);
    }
  }

  /// Clear all pending approvals (used when disconnecting)
  void clearAllPending() {
    state = state.copyWith(
      pendingApprovals: [],
      clearCurrentApproval: true,
    );
  }

  /// Clear approval history
  void clearHistory() {
    state = state.copyWith(approvalHistory: []);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Add mock approval request (for testing/demo)
  void addMockApprovalRequest({
    String? command,
    List<String>? args,
    String? nodeId,
    String? cwd,
    String? security,
  }) {
    final mockRequest = ApprovalRequest(
      id: _uuid.v4(),
      command: command ?? 'system.run',
      commandArgv: args ?? ['ls', '-la', '/home'],
      cwd: cwd ?? '/home/user',
      nodeId: nodeId ?? 'node-rasp',
      security: security ?? 'allowlist',
      requestedAt: DateTime.now(),
    );
    
    handleApprovalRequest(mockRequest);
  }

  /// Expire old pending approvals
  void expireOldApprovals({Duration timeout = const Duration(minutes: 5)}) {
    final now = DateTime.now();
    final expiredIds = <String>[];
    
    final validPending = state.pendingApprovals.where((approval) {
      if (approval.requestedAt == null) return true;
      
      final age = now.difference(approval.requestedAt!);
      if (age > timeout) {
        expiredIds.add(approval.id);
        return false;
      }
      return true;
    }).toList();
    
    if (expiredIds.isEmpty) return;
    
    // Add expired approvals to history
    final expiredApprovals = state.pendingApprovals
        .where((a) => expiredIds.contains(a.id))
        .map((a) => ApprovalRequest(
          id: a.id,
          command: a.command,
          commandArgv: a.commandArgv,
          cwd: a.cwd,
          nodeId: a.nodeId,
          security: a.security,
          status: ApprovalStatus.expired,
          decision: a.decision,
          requestedAt: a.requestedAt,
          resolvedAt: now,
          resolvedBy: null,
        ))
        .toList();
    
    final newHistory = [...expiredApprovals, ...state.approvalHistory];
    
    // Check if current approval was expired
    final shouldClearCurrent = 
        state.currentApproval != null && expiredIds.contains(state.currentApproval!.id);
    
    state = state.copyWith(
      pendingApprovals: validPending,
      approvalHistory: newHistory,
      clearCurrentApproval: shouldClearCurrent,
    );
  }
}

/// Approval state provider
final approvalProvider =
    StateNotifierProvider<ApprovalNotifier, ApprovalState>((ref) {
  return ApprovalNotifier();
});

/// Pending approvals count provider
final pendingApprovalsCountProvider = Provider<int>((ref) {
  final state = ref.watch(approvalProvider);
  return state.pendingCount;
});

/// Has pending approvals provider
final hasPendingApprovalsProvider = Provider<bool>((ref) {
  final state = ref.watch(approvalProvider);
  return state.hasPending;
});

/// Current approval provider
final currentApprovalProvider = Provider<ApprovalRequest?>((ref) {
  final state = ref.watch(approvalProvider);
  return state.currentApproval;
});

/// Approval history provider
final approvalHistoryProvider = Provider<List<ApprovalRequest>>((ref) {
  final state = ref.watch(approvalProvider);
  return state.approvalHistory;
});