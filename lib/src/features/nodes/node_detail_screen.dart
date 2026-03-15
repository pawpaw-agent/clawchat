/// Node detail screen with command invocation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/node.dart';
import 'node_controller.dart';

/// Node detail screen
class NodeDetailScreen extends ConsumerStatefulWidget {
  final String nodeId;

  const NodeDetailScreen({
    super.key,
    required this.nodeId,
  });

  @override
  ConsumerState<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends ConsumerState<NodeDetailScreen> {
  String? _selectedCommand;
  final Map<String, TextEditingController> _paramControllers = {};

  @override
  void dispose() {
    for (final controller in _paramControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Select the node
    ref.read(nodeProvider.notifier).selectNode(widget.nodeId);

    final nodeState = ref.watch(nodeProvider);
    final node = nodeState.nodes.firstWhere(
      (n) => n.id == widget.nodeId,
      orElse: () => throw StateError('Node not found'),
    );
    final detail = nodeState.nodeDetails[widget.nodeId];
    final invokeState = ref.watch(nodeInvokeProvider(widget.nodeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(node.displayName ?? node.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(nodeProvider.notifier).fetchNodes();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(theme, colorScheme, node),
            const SizedBox(height: 16),

            // Node info
            _buildInfoSection(theme, colorScheme, node, detail),
            const SizedBox(height: 16),

            // Commands section
            Text(
              'Commands',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (node.commands.isEmpty)
              _buildEmptyState(theme, 'No commands available')
            else
              _buildCommandsList(theme, colorScheme, node, detail, invokeState),
            const SizedBox(height: 16),

            // Invoke result
            if (invokeState.lastResult != null)
              _buildResultCard(theme, colorScheme, invokeState.lastResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Node node,
  ) {
    final statusColor = _getStatusColor(node.status);
    final statusText = _getStatusText(node.status);

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(node.status),
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (node.lastSeen != null)
                    Text(
                      'Last seen: ${_formatTime(node.lastSeen!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (node.version != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'v${node.version}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    ThemeData theme,
    ColorScheme colorScheme,
    Node node,
    NodeDetail? detail,
  ) {
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              Icons.fingerprint,
              'ID',
              node.id,
            ),
            if (node.host != null)
              _buildInfoRow(
                theme,
                Icons.dns,
                'Host',
                node.host!,
              ),
            if (node.platform != null)
              _buildInfoRow(
                theme,
                Icons.devices,
                'Platform',
                node.platform!,
              ),
            if (detail?.uptimeSeconds != null)
              _buildInfoRow(
                theme,
                Icons.schedule,
                'Uptime',
                _formatUptime(detail!.uptimeSeconds!),
              ),
            const Divider(height: 24),
            Text(
              'Capabilities',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: node.caps.isEmpty
                  ? [
                      Text(
                        'No capabilities',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]
                  : node.caps
                      .map((cap) => Chip(
                            label: Text(cap),
                            backgroundColor:
                                colorScheme.primaryContainer.withOpacity(0.5),
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ))
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandsList(
    ThemeData theme,
    ColorScheme colorScheme,
    Node node,
    NodeDetail? detail,
    InvokeState invokeState,
  ) {
    return Column(
      children: [
        // Command dropdown
        DropdownButtonFormField<String>(
          value: _selectedCommand,
          decoration: const InputDecoration(
            labelText: 'Select Command',
            border: OutlineInputBorder(),
          ),
          items: node.commands
              .map((cmd) => DropdownMenuItem(
                    value: cmd,
                    child: Text(cmd),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCommand = value;
              _paramControllers.clear();
            });
          },
        ),
        if (_selectedCommand != null) ...[
          const SizedBox(height: 12),
          // Command info
          if (detail?.commandDetails[_selectedCommand] != null)
            _buildCommandInfo(
              theme,
              colorScheme,
              detail!.commandDetails[_selectedCommand]!,
            ),
          const SizedBox(height: 12),
          // Invoke button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: invokeState.isInvoking
                  ? null
                  : () => _invokeCommand(invokeState),
              icon: invokeState.isInvoking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                invokeState.isInvoking ? 'Invoking...' : 'Execute Command',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommandInfo(
    ThemeData theme,
    ColorScheme colorScheme,
    CommandInfo cmdInfo,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cmdInfo.description != null)
            Text(
              cmdInfo.description!,
              style: theme.textTheme.bodySmall,
            ),
          if (cmdInfo.params.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Parameters:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...cmdInfo.params.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• ${e.key}: ${e.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(
    ThemeData theme,
    ColorScheme colorScheme,
    NodeInvokeResult result,
  ) {
    final isSuccess = result.success;

    return Card(
      color: isSuccess
          ? Colors.green.withOpacity(0.1)
          : colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Command Executed' : 'Execution Failed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSuccess ? Colors.green : colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Command: ${result.command}',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 16),
            if (result.success && result.result != null) ...[
              Text(
                'Result:',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatResult(result.result),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ] else if (result.error != null) ...[
              Text(
                'Error:',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _invokeCommand(InvokeState invokeState) async {
    if (_selectedCommand == null) return;

    final result = await ref
        .read(nodeInvokeProvider(widget.nodeId).notifier)
        .invokeCommand(command: _selectedCommand!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Command executed successfully'
                : 'Command failed: ${result.error}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _formatResult(dynamic result) {
    if (result == null) return 'null';
    if (result is Map) {
      return result.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    }
    return result.toString();
  }

  Color _getStatusColor(NodeStatus? status) {
    return switch (status) {
      NodeStatus.online => Colors.green,
      NodeStatus.offline => Colors.grey,
      NodeStatus.busy => Colors.orange,
      NodeStatus.error => Colors.red,
      _ => Colors.grey,
    };
  }

  String _getStatusText(NodeStatus? status) {
    return switch (status) {
      NodeStatus.online => 'Online',
      NodeStatus.offline => 'Offline',
      NodeStatus.busy => 'Busy',
      NodeStatus.error => 'Error',
      _ => 'Unknown',
    };
  }

  IconData _getStatusIcon(NodeStatus? status) {
    return switch (status) {
      NodeStatus.online => Icons.check_circle,
      NodeStatus.offline => Icons.cloud_off,
      NodeStatus.busy => Icons.hourglass_top,
      NodeStatus.error => Icons.error_outline,
      _ => Icons.help_outline,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) return '${seconds ~/ 60} minutes';
    if (seconds < 86400) return '${seconds ~/ 3600} hours';
    return '${seconds ~/ 86400} days';
  }
}