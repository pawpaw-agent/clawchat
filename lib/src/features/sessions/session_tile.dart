/// Session tile component for list display
library;

import 'package:flutter/material.dart';
import '../../core/models/session.dart';

/// Callback for session actions
typedef SessionActionCallback = void Function(Session session);

/// Session list tile widget
class SessionTile extends StatelessWidget {
  final Session session;
  final bool isActive;
  final VoidCallback? onTap;
  final SessionActionCallback? onDelete;
  final SessionActionCallback? onArchive;
  final SessionActionCallback? onPin;

  const SessionTile({
    super.key,
    required this.session,
    this.isActive = false,
    this.onTap,
    this.onDelete,
    this.onArchive,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(session.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colorScheme.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Session'),
            content: Text(
              'Are you sure you want to delete "${session.label ?? 'Untitled'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete?.call(session);
      },
      child: ListTile(
        leading: _buildAvatar(theme),
        title: _buildTitle(theme),
        subtitle: _buildSubtitle(theme),
        trailing: _buildTrailing(theme),
        tileColor: isActive ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final agentColor = _getAgentColor(session.agentId);

    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: agentColor.withValues(alpha: 0.2),
          child: Icon(
            session.isArchived ? Icons.archive : Icons.chat_bubble,
            color: agentColor,
          ),
        ),
        if (session.isPinned)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.push_pin,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            session.label ?? 'Untitled',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (session.lastActiveAt != null)
          Text(
            _formatTime(session.lastActiveAt!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (session.lastMessage != null)
          Text(
            session.lastMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (session.agentId != null) ...[
              Icon(
                Icons.smart_toy,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatAgentId(session.agentId!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            if (session.messageCount > 0)
              Text(
                '${session.messageCount} msgs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailing(ThemeData theme) {
    if (session.isArchived) {
      return Icon(
        Icons.archive,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return const SizedBox.shrink();
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                session.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(session.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                onPin?.call(session);
              },
            ),
            ListTile(
              leading: Icon(
                session.isArchived ? Icons.unarchive : Icons.archive,
              ),
              title: Text(session.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                onArchive?.call(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: session.label);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Session name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Note: Rename logic will be handled by parent via callback
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete "${session.label ?? 'Untitled'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(session);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getAgentColor(String? agentId) {
    if (agentId == null) return Colors.grey;
    
    // Generate consistent color based on agentId
    final hash = agentId.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatAgentId(String agentId) {
    // Extract agent name from ID (e.g., "agent-forge" -> "Forge")
    final parts = agentId.split('-');
    if (parts.length > 1) {
      return parts.last[0].toUpperCase() + parts.last.substring(1);
    }
    return agentId;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}