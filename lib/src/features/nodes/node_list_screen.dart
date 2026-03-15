/// Node list screen - displays connected nodes
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/node.dart';
import 'node_controller.dart';
import 'node_tile.dart';
import 'node_detail_screen.dart';

/// Node list screen
class NodeListScreen extends ConsumerStatefulWidget {
  const NodeListScreen({super.key});

  @override
  ConsumerState<NodeListScreen> createState() => _NodeListScreenState();
}

class _NodeListScreenState extends ConsumerState<NodeListScreen> {
  @override
  void initState() {
    super.initState();
    // Load nodes on init
    Future.microtask(() {
      ref.read(nodeProvider.notifier).fetchNodes();
    });
  }

  /// Public refresh method for testing
  Future<void> refresh() async {
    await ref.read(nodeProvider.notifier).fetchNodes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nodeState = ref.watch(nodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nodes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: nodeState.isRefreshing
                ? null
                : () => ref.read(nodeProvider.notifier).fetchNodes(),
          ),
        ],
      ),
      body: _buildBody(theme, colorScheme, nodeState),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    NodeState nodeState,
  ) {
    if (nodeState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (nodeState.hasError) {
      return _buildErrorState(theme, colorScheme, nodeState);
    }

    if (nodeState.nodes.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(nodeProvider.notifier).fetchNodes(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: nodeState.nodes.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(theme, nodeState);
          }

          final node = nodeState.nodes[index - 1];
          return NodeTile(
            node: node,
            isSelected: nodeState.selectedNodeId == node.id,
            onTap: () => _navigateToDetail(node),
            onLongPress: (n) => _showNodeOptions(context, n),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, NodeState nodeState) {
    final onlineCount = nodeState.onlineNodes.length;
    final totalCount = nodeState.nodes.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.devices,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$onlineCount online / $totalCount total',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No nodes connected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pair a device to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to pairing screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pairing feature coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Pair Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    NodeState nodeState,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              nodeState.error?.userMessage ?? 'Failed to load nodes',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (nodeState.error?.suggestedAction != null) ...[
              const SizedBox(height: 8),
              Text(
                nodeState.error!.suggestedAction!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(nodeProvider.notifier).retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Node node) {
    ref.read(nodeProvider.notifier).selectNode(node.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NodeDetailScreen(nodeId: node.id),
      ),
    );
  }

  void _showNodeOptions(BuildContext context, Node node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(node);
              },
            ),
            ListTile(
              leading: Icon(
                node.status == NodeStatus.online
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              title: Text(
                node.status == NodeStatus.online ? 'Disable' : 'Enable',
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${node.displayName ?? node.id} ${node.status == NodeStatus.online ? 'disabled' : 'enabled'}',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemove(context, node);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, Node node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Node'),
        content: Text(
          'Are you sure you want to remove "${node.displayName ?? node.id}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${node.displayName ?? node.id} removed',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}