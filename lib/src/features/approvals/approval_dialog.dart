/// Approval dialog for handling exec.approval.requested events
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/approval_request.dart';
import 'approval_controller.dart';

/// Approval dialog widget
class ApprovalDialog extends ConsumerWidget {
  const ApprovalDialog({
    super.key,
    required this.request,
    this.onApprove,
    this.onDeny,
  });

  final ApprovalRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('执行审批请求'),
        ],
      ),
      content: _DialogContent(request: request),
      actions: [
        TextButton(
          onPressed: () => _handleDeny(context, ref),
          child: const Text('拒绝'),
        ),
        FilledButton.icon(
          onPressed: () => _handleAllowOnce(context, ref),
          icon: const Icon(Icons.check),
          label: const Text('允许一次'),
        ),
        FilledButton.icon(
          onPressed: () => _handleAllowAlways(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          icon: const Icon(Icons.done_all),
          label: const Text('始终允许'),
        ),
      ],
    );
  }

  void _handleDeny(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    
    final success = await ref.read(approvalProvider.notifier).resolveApproval(
      id: request.id,
      decision: ApprovalDecision.deny,
    );
    
    if (success) {
      navigator.pop();
      onDeny?.call();
      _showSnackBar(context, '已拒绝执行请求', Colors.red);
    }
  }

  void _handleAllowOnce(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    
    final success = await ref.read(approvalProvider.notifier).resolveApproval(
      id: request.id,
      decision: ApprovalDecision.allowOnce,
    );
    
    if (success) {
      navigator.pop();
      onApprove?.call();
      _showSnackBar(context, '已允许执行（仅本次）', Colors.green);
    }
  }

  void _handleAllowAlways(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    
    final success = await ref.read(approvalProvider.notifier).resolveApproval(
      id: request.id,
      decision: ApprovalDecision.allowAlways,
    );
    
    if (success) {
      navigator.pop();
      onApprove?.call();
      _showSnackBar(context, '已允许执行（始终）', Colors.green);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Dialog content widget
class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.request});

  final ApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Command info
        _InfoSection(
          icon: Icons.terminal,
          label: '命令',
          value: request.command,
          isMono: true,
        ),
        
        const SizedBox(height: 12),
        
        // Arguments
        if (request.commandArgv.isNotEmpty) ...[
          _InfoSection(
            icon: Icons.list,
            label: '参数',
            value: request.commandArgv.join(' '),
            isMono: true,
          ),
          const SizedBox(height: 12),
        ],
        
        // Working directory
        if (request.cwd != null && request.cwd!.isNotEmpty) ...[
          _InfoSection(
            icon: Icons.folder,
            label: '工作目录',
            value: request.cwd!,
            isMono: true,
          ),
          const SizedBox(height: 12),
        ],
        
        // Source node
        _InfoSection(
          icon: Icons.devices,
          label: '来源节点',
          value: request.nodeId,
        ),
        
        const SizedBox(height: 12),
        
        // Security level
        if (request.security != null && request.security!.isNotEmpty) ...[
          _InfoSection(
            icon: Icons.shield,
            label: '安全级别',
            value: request.security!,
          ),
          const SizedBox(height: 12),
        ],
        
        // Request time
        if (request.requestedAt != null) ...[
          _InfoSection(
            icon: Icons.access_time,
            label: '请求时间',
            value: _formatTime(request.requestedAt!),
          ),
          const SizedBox(height: 12),
        ],
        
        // Warning message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '请确认此命令是否可以执行',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

/// Info section widget
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

/// Show approval dialog helper
Future<bool> showApprovalDialog(
  BuildContext context, {
  required ApprovalRequest request,
  VoidCallback? onApprove,
  VoidCallback? onDeny,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ApprovalDialog(
      request: request,
      onApprove: onApprove,
      onDeny: onDeny,
    ),
  );
  
  return result ?? false;
}

/// Approval dialog route for navigator
class ApprovalDialogRoute<T> extends PopupRoute<T> {
  ApprovalDialogRoute({
    required this.request,
    this.onApprove,
    this.onDeny,
    super.settings,
  });

  final ApprovalRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'ApprovalDialog';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ApprovalDialog(
      request: request,
      onApprove: onApprove,
      onDeny: onDeny,
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }
}

/// Extension for showing approval dialog
extension ApprovalDialogExtension on BuildContext {
  /// Show approval dialog
  Future<bool> showApproval({
    required ApprovalRequest request,
    VoidCallback? onApprove,
    VoidCallback? onDeny,
  }) async {
    final result = await showDialog<bool>(
      this,
      barrierDismissible: false,
      builder: (context) => ApprovalDialog(
        request: request,
        onApprove: onApprove,
        onDeny: onDeny,
      ),
    );
    
    return result ?? false;
  }
}