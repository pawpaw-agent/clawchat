/// Session list screen
/// Displays list of chat sessions with create/delete/archive functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/session.dart';
import '../chat/chat_screen.dart';
import 'session_controller.dart';
import 'session_tile.dart';

/// Session list screen
class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final activeSessions = ref.watch(activeSessionsProvider);
    final archivedSessions = ref.watch(archivedSessionsProvider);

    return Scaffold(
      appBar: _buildAppBar(context, archivedSessions),
      body: _buildBody(
        context,
        sessionState,
        activeSessions,
        archivedSessions,
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, List<Session> archivedSessions) {
    return AppBar(
      title: const Text('ClawChat'),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearch(context);
          },
        ),
        // Archive toggle
        if (archivedSessions.isNotEmpty)
          IconButton(
            icon: Icon(
              _showArchived ? Icons.inbox : Icons.archive_outlined,
            ),
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
          ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            _navigateToSettings(context);
          },
        ),
      ],
      bottom: _buildConnectionStatusBar(context),
    );
  }

  PreferredSizeWidget _buildConnectionStatusBar(BuildContext context) {
    // TODO: Get actual connection state from provider
    // Currently hardcoded to show "Disconnected" state
    return PreferredSize(
      preferredSize: const Size.fromHeight(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: Colors.orange.withValues(alpha: 0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending,
              size: 14,
              color: Colors.orange,
            ),
            SizedBox(width: 8),
            Text(
              'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionState sessionState,
    List<Session> activeSessions,
    List<Session> archivedSessions,
  ) {
    if (sessionState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (sessionState.error != null) {
      return _buildError(context, sessionState.error!);
    }

    final sessions = _showArchived ? archivedSessions : activeSessions;

    if (sessions.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(sessionProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: sessions.length + (_showArchived ? 0 : _pinnedCount(activeSessions)),
        itemBuilder: (context, index) {
          // Show pinned section header
          if (!_showArchived && index == 0 && _pinnedCount(activeSessions) > 0) {
            return _buildSectionHeader('Pinned');
          }

          final sessionIndex = _showArchived
              ? index
              : index - (_pinnedCount(activeSessions) > 0 ? 1 : 0);

          if (sessionIndex < 0 || sessionIndex >= sessions.length) {
            return const SizedBox.shrink();
          }

          final session = sessions[sessionIndex];

          // Show "Recent" section header after pinned sessions
          if (!_showArchived &&
              index == _pinnedCount(activeSessions) + 1 &&
              _pinnedCount(activeSessions) > 0 &&
              sessions.any((s) => !s.isPinned)) {
            return _buildSectionHeader('Recent');
          }

          return SessionTile(
            session: session,
            isActive: sessionState.activeSessionKey == session.key,
            onTap: () => _openSession(session),
            onDelete: (s) => _deleteSession(s),
            onArchive: (s) => _toggleArchive(s),
            onPin: (s) => _togglePin(s),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showArchived ? 'No archived sessions' : 'No sessions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _showArchived
                ? 'Archive sessions to hide them from your list'
                : 'Start a new conversation to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.read(sessionProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _createNewSession,
      icon: const Icon(Icons.add),
      label: const Text('New Chat'),
    );
  }

  int _pinnedCount(List<Session> sessions) {
    return sessions.where((s) => s.isPinned).length;
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: SessionSearchDelegate(ref),
    );
  }

  void _createNewSession() async {
    final session = await ref.read(sessionProvider.notifier).createSession();
    if (mounted) {
      _openSession(session);
    }
  }

  void _openSession(Session session) {
    ref.read(sessionProvider.notifier).setActiveSession(session.key);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
        // Pass session key when ChatScreen supports it
        // settings: RouteSettings(arguments: session.key),
      ),
    );
  }

  void _deleteSession(Session session) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await ref.read(sessionProvider.notifier).deleteSession(session.key);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${session.label ?? 'Untitled'}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo
          },
        ),
      ),
    );
  }

  void _toggleArchive(Session session) {
    ref.read(sessionProvider.notifier).toggleArchive(session.key);
  }

  void _togglePin(Session session) {
    ref.read(sessionProvider.notifier).togglePin(session.key);
  }

  void _navigateToSettings(BuildContext context) {
    // TODO: Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon')),
    );
  }
}

/// Session search delegate
class SessionSearchDelegate extends SearchDelegate<Session?> {
  final WidgetRef ref;

  SessionSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final sessions = ref.watch(sortedSessionsProvider);
    final results = sessions.where((s) {
      final label = s.label?.toLowerCase() ?? '';
      final lastMessage = s.lastMessage?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return label.contains(searchQuery) || lastMessage.contains(searchQuery);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final session = results[index];
        return SessionTile(
          session: session,
          onTap: () {
            close(context, session);
          },
        );
      },
    );
  }
}