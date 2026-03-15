/// Approval history screen - shows pending and resolved approvals
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/approval_request.dart';
import 'approval_controller.dart';
import 'approval_dialog.dart';

/// Approval list screen
class ApprovalListScreen extends ConsumerWidget {
  const ApprovalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalProvider);
    final pendingCount = ref.watch(pendingApprovalsCountProvider);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('审批管理'),
          bottom: TabBar(
            tabs: [
              Tab(
                text: '待处理',
                icon: Badge(
                  label: Text('$pendingCount'),
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.pending_actions),
                ),
              ),
              const Tab(
                text: '历史',
                icon: Icon(Icons.history),
              ),
            ],
          ),
          actions: [
            if (state.hasPending)
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: '清空待处理',
                onPressed: () => _showClearConfirmDialog(context, ref, isPending: true),
              ),
            if (state.historyCount > 0)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: '清空历史',
                onPressed: () => _showClearConfirmDialog(context, ref, isPending: false),
              ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '添加测试请求',
              onPressed: () => _addMockRequest(ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _PendingApprovalsTab(state: state),
            _HistoryTab(state: state),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref, {required bool isPending}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPending ? '清空待处理' : '清空历史'),
        content: Text(
          isPending 
            ? '确定要清空所有待处理的审批请求吗？\n这些请求将不会被处理。'
            : '确定要清空所有审批历史吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (isPending) {
                ref.read(approvalProvider.notifier).clearAllPending();
              } else {
                ref.read(approvalProvider.notifier).clearHistory();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _addMockRequest(WidgetRef ref) {
    ref.read(approvalProvider.notifier).addMockApprovalRequest();
  }
}

/// Pending approvals tab
class _PendingApprovalsTab extends StatelessWidget {
  const _PendingApprovalsTab({required this.state});

  final ApprovalState state;

  @override
  Widget build(BuildContext context) {
    if (state.pendingApprovals.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        title: '没有待处理的审批',
        subtitle: '新的审批请求将显示在这里',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.pendingApprovals.length,
      itemBuilder: (context, index) {
        final approval = state.pendingApprovals[index];
        return _ApprovalCard(
          approval: approval,
          isPending: true,
          showActions: true,
        );
      },
    );
  }
}

/// History tab
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state});

  final ApprovalState state;

  @override
  Widget build(BuildContext context) {
    if (state.approvalHistory.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: '没有审批历史',
        subtitle: '已处理的审批将显示在这里',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.approvalHistory.length,
      itemBuilder: (context, index) {
        final approval = state.approvalHistory[index];
        return _ApprovalCard(
          approval: approval,
          isPending: false,
          showActions: false,
        );
      },
    );
  }
}

/// Approval card widget
class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({
    required this.approval,
    required this.isPending,
    required this.showActions,
  });

  final ApprovalRequest approval;
  final bool isPending;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                _StatusBadge(status: approval.status),
                const Spacer(),
                if (approval.requestedAt != null)
                  Text(
                    _formatDateTime(approval.requestedAt!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Command info
            _InfoRow(
              icon: Icons.terminal,
              label: '命令',
              value: approval.command,
              isMono: true,
            ),
            
            if (approval.commandArgv.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.list,
                label: '参数',
                value: approval.commandArgv.join(' '),
                isMono: true,
                maxLines: 2,
              ),
            ],
            
            if (approval.cwd != null && approval.cwd!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.folder,
                label: '目录',
                value: approval.cwd!,
                isMono: true,
              ),
            ],
            
            const SizedBox(height: 8),
            
            _InfoRow(
              icon: Icons.devices,
              label: '节点',
              value: approval.nodeId,
            ),
            
            if (approval.security != null && approval.security!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.shield,
                label: '安全',
                value: approval.security!,
              ),
            ],
            
            // Resolution info for historical approvals
            if (!isPending && approval.decision != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    approval.decision == ApprovalDecision.deny 
                        ? Icons.block 
                        : Icons.check_circle,
                    size: 16,
                    color: approval.decision == ApprovalDecision.deny 
                        ? Colors.red 
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    approval.decision!.displayText,
                    style: TextStyle(
                      color: approval.decision == ApprovalDecision.deny 
                          ? Colors.red 
                          : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (approval.resolvedAt != null) ...[
                    const Spacer(),
                    Text(
                      _formatDateTime(approval.resolvedAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
            
            // Action buttons for pending approvals
            if (showActions && isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleDeny(ref),
                    icon: const Icon(Icons.block),
                    label: const Text('拒绝'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _handleAllowOnce(ref),
                    icon: const Icon(Icons.check),
                    label: const Text('允许一次'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _handleAllowAlways(ref),
                    icon: const Icon(Icons.done_all),
                    label: const Text('始终允许'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDeny(WidgetRef ref) {
    ref.read(approvalProvider.notifier).resolveApproval(
      id: approval.id,
      decision: ApprovalDecision.deny,
    );
  }

  void _handleAllowOnce(WidgetRef ref) {
    ref.read(approvalProvider.notifier).resolveApproval(
      id: approval.id,
      decision: ApprovalDecision.allowOnce,
    );
  }

  void _handleAllowAlways(WidgetRef ref) {
    ref.read(approvalProvider.notifier).resolveApproval(
      id: approval.id,
      decision: ApprovalDecision.allowAlways,
    );
  }

  String _formatDateTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: _getForegroundColor(context)),
          const SizedBox(width: 4),
          Text(
            status.displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getForegroundColor(context),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    return switch (status) {
      ApprovalStatus.pending => Icons.pending,
      ApprovalStatus.approved => Icons.check_circle,
      ApprovalStatus.denied => Icons.cancel,
      ApprovalStatus.expired => Icons.schedule,
    };
  }

  Color _getBackgroundColor(BuildContext context) {
    return switch (status) {
      ApprovalStatus.pending => Colors.orange.withOpacity(0.1),
      ApprovalStatus.approved => Colors.green.withOpacity(0.1),
      ApprovalStatus.denied => Colors.red.withOpacity(0.1),
      ApprovalStatus.expired => Colors.grey.withOpacity(0.1),
    };
  }

  Color _getForegroundColor(BuildContext context) {
    return switch (status) {
      ApprovalStatus.pending => Colors.orange[700]!,
      ApprovalStatus.approved => Colors.green[700]!,
      ApprovalStatus.denied => Colors.red[700]!,
      ApprovalStatus.expired => Colors.grey[700]!,
    };
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMono;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                maxLines: maxLines,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: isMono ? 'monospace' : null,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}