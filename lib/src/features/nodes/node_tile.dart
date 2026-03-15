/// Node tile component for list display
library;

import 'package:flutter/material.dart';
import '../../core/models/node.dart';

/// Callback for node actions
typedef NodeActionCallback = void Function(Node node);

/// Node list tile widget
class NodeTile extends StatelessWidget {
  final Node node;
  final bool isSelected;
  final VoidCallback? onTap;
  final NodeActionCallback? onLongPress;

  const NodeTile({
    super.key,
    required this.node,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => onLongPress?.call(node),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIndicator(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(theme),
                        const SizedBox(height: 2),
                        _buildSubtitle(theme),
                      ],
                    ),
                  ),
                  _buildPlatformIcon(theme),
                ],
              ),
              if (node.caps.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildCapabilitiesChip(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    final statusColor = _getStatusColor(node.status);
    final statusIcon = _getStatusIcon(node.status);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        statusIcon,
        color: statusColor,
        size: 20,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      node.displayName ?? node.id,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    final parts = <String>[];

    if (node.host != null) {
      parts.add(node.host!);
    }
    if (node.platform != null) {
      parts.add(node.platform!);
    }
    if (node.lastSeen != null) {
      parts.add('Last seen: ${_formatTime(node.lastSeen!)}');
    }

    return Text(
      parts.join(' • '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPlatformIcon(ThemeData theme) {
    final icon = _getPlatformIcon(node.platform);
    final color = theme.colorScheme.onSurfaceVariant;

    return Icon(icon, size: 18, color: color);
  }

  Widget _buildCapabilitiesChip(ThemeData theme) {
    final displayCaps = node.caps.take(3).toList();
    final hasMore = node.caps.length > 3;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...displayCaps.map((cap) => _buildChip(theme, cap)),
        if (hasMore)
          _buildChip(theme, '+${node.caps.length - 3}', isMore: true),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, String label, {bool isMore = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isMore
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isMore
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
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

  IconData _getStatusIcon(NodeStatus? status) {
    return switch (status) {
      NodeStatus.online => Icons.devices,
      NodeStatus.offline => Icons.devices_outlined,
      NodeStatus.busy => Icons.hourglass_top,
      NodeStatus.error => Icons.error_outline,
      _ => Icons.help_outline,
    };
  }

  IconData _getPlatformIcon(String? platform) {
    return switch (platform) {
      'linux' => Icons.computer,
      'darwin' => Icons.laptop_mac,
      'windows' => Icons.laptop_windows,
      'android' => Icons.phone_android,
      'ios' => Icons.phone_iphone,
      'web' => Icons.web,
      _ => Icons.device_unknown,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}