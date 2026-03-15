/// Session list screen with pagination support
/// Displays list of chat sessions with create/delete/archive functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/session.dart';
import '../../core/utils/list_optimizer.dart';
import '../chat/chat_screen.dart';
import 'session_controller.dart';
import 'session_tile.dart';

/// Session list screen with pagination
class SessionListScreen extends ConsumerStatefulWidget {
  final int pageSize;
  final ListOptimizationConfig? optimizationConfig;

  const SessionListScreen({
    super.key,
    this.pageSize = 20,
    this.optimizationConfig,
  });

  @override
  ConsumerState<SessionListScreen> createState() => SessionListScreenState();
}

/// Public state class for testing access
class SessionListScreenState extends ConsumerState<SessionListScreen> {
  bool _showArchived = false;

  // Pagination controllers for active and archived sessions
  late final PaginationController<Session> _activePaginationController;
  late final PaginationController<Session> _archivedPaginationController;

  // Scroll controllers for detecting scroll to bottom
  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _archivedScrollController = ScrollController();

  // Current pagination state
  PaginationState<Session> _activePaginationState = const PaginationState();
  PaginationState<Session> _archivedPaginationState = const PaginationState();

  @override
  void initState() {
    super.initState();

    // Initialize pagination controllers
    _activePaginationController = PaginationController<Session>(
      pageSize: widget.pageSize,
      fetchPage: (page, size) => _fetchSessionsPage(page, size, false),
    );

    _archivedPaginationController = PaginationController<Session>(
      pageSize: widget.pageSize,
      fetchPage: (page, size) => _fetchSessionsPage(page, size, true),
    );

    // Add listeners for pagination state updates
    _activePaginationController.addListener((state) {
      if (mounted) {
        setState(() {
          _activePaginationState = state;
        });
      }
    });

    _archivedPaginationController.addListener((state) {
      if (mounted) {
        setState(() {
          _archivedPaginationState = state;
        });
      }
    });

    // Setup scroll listeners for infinite scroll
    _activeScrollController.addListener(() => _onScroll(_activeScrollController, false));
    _archivedScrollController.addListener(() => _onScroll(_archivedScrollController, true));

    // Configure image cache
    final config = widget.optimizationConfig ?? ListOptimizationConfig.chatList;
    ImageCacheConfig.configureForMemoryLimit(config.imageCacheMB);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _activeScrollController.dispose();
    _archivedScrollController.dispose();
    _activePaginationController.dispose();
    _archivedPaginationController.dispose();
    super.dispose();
  }

  /// Fetch a page of sessions
  Future<List<Session>> _fetchSessionsPage(int page, int size, bool archived) async {
    final allSessions = ref.read(sessionProvider).sessions;
    final filtered = allSessions.where((s) => s.isArchived == archived).toList();

    // Sort by lastActiveAt (newest first)
    filtered.sort((a, b) {
      final aTime = a.lastActiveAt ?? a.updatedAt ?? a.createdAt;
      final bTime = b.lastActiveAt ?? b.updatedAt ?? b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    // Calculate page slice
    final startIndex = page * size;
    final endIndex = startIndex + size;

    if (startIndex >= filtered.length) {
      return [];
    }

    return filtered.sublist(
      startIndex,
      endIndex.clamp(0, filtered.length),
    );
  }

  /// Load initial data
  Future<void> _loadInitialData() async {
    await Future.wait([
      _activePaginationController.loadInitial(),
      _archivedPaginationController.loadInitial(),
    ]);
  }

  /// Handle scroll events for infinite loading
  void _onScroll(ScrollController controller, bool isArchived) {
    if (!controller.hasClients) return;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    const threshold = 200.0; // Load more when 200px from bottom

    if (maxScroll - currentScroll <= threshold) {
      if (isArchived) {
        _archivedPaginationController.loadMore();
      } else {
        _activePaginationController.loadMore();
      }
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await ref.read(sessionProvider.notifier).refresh();
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, sessionState),
      floatingActionButton: _buildFAB(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('ClawChat'),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(context),
        ),
        // Archive toggle
        if (_archivedPaginationState.items.isNotEmpty)
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
          onPressed: () => _navigateToSettings(context),
        ),
      ],
      bottom: _buildConnectionStatusBar(context),
    );
  }

  PreferredSizeWidget _buildConnectionStatusBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: Colors.orange.withOpacity(0.1),
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

  Widget _buildBody(BuildContext context, SessionState sessionState) {
    if (sessionState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessionState.error != null) {
      return _buildError(context, sessionState.error!);
    }

    final paginationState = _showArchived ? _archivedPaginationState : _activePaginationState;
    final scrollController = _showArchived ? _archivedScrollController : _activeScrollController;

    if (paginationState.isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (paginationState.items.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: _PaginatedSessionList(
        sessions: paginationState.items,
        scrollController: scrollController,
        isLoadingMore: paginationState.isLoading && paginationState.items.isNotEmpty,
        hasMore: paginationState.hasMore,
        onLoadMore: () {
          if (_showArchived) {
            _archivedPaginationController.loadMore();
          } else {
            _activePaginationController.loadMore();
          }
        },
        activeSessionKey: sessionState.activeSessionKey,
        onSessionTap: _openSession,
        onDelete: _deleteSession,
        onArchive: _toggleArchive,
        onPin: _togglePin,
        showPinnedSection: !_showArchived,
        config: widget.optimizationConfig ?? ListOptimizationConfig.chatList,
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
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
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
            onPressed: refresh,
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
      ),
    );
  }

  void _deleteSession(Session session) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await ref.read(sessionProvider.notifier).deleteSession(session.key);

    // Refresh pagination
    await _loadInitialData();

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
    // Refresh pagination after archive toggle
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadInitialData();
    });
  }

  void _togglePin(Session session) {
    ref.read(sessionProvider.notifier).togglePin(session.key);
  }

  void _navigateToSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon')),
    );
  }
}

/// Paginated session list with infinite scroll
class _PaginatedSessionList extends StatelessWidget {
  final List<Session> sessions;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String? activeSessionKey;
  final void Function(Session) onSessionTap;
  final void Function(Session) onDelete;
  final void Function(Session) onArchive;
  final void Function(Session) onPin;
  final bool showPinnedSection;
  final ListOptimizationConfig config;

  const _PaginatedSessionList({
    required this.sessions,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.activeSessionKey,
    required this.onSessionTap,
    required this.onDelete,
    required this.onArchive,
    required this.onPin,
    required this.showPinnedSection,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Split sessions into pinned and unpinned
    final pinnedSessions = sessions.where((s) => s.isPinned).toList();
    final unpinnedSessions = sessions.where((s) => !s.isPinned).toList();

    // Calculate total items
    final hasPinned = showPinnedSection && pinnedSessions.isNotEmpty;
    final totalItems = sessions.length +
        (hasPinned ? 2 : 0) + // Section headers for Pinned and Recent
        (isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      itemCount: totalItems,
      cacheExtent: config.cacheExtent,
      addAutomaticKeepAlives: config.useKeepAlive,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (isLoadingMore && index == totalItems - 1) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Pinned section header
        if (hasPinned && index == 0) {
          return _buildSectionHeader(context, 'Pinned');
        }

        // Recent section header (after pinned items)
        if (hasPinned && index == pinnedSessions.length + 1) {
          return _buildSectionHeader(context, 'Recent');
        }

        // Calculate actual session index
        int sessionIndex;
        Session? session;

        if (hasPinned) {
          if (index <= pinnedSessions.length) {
            // Pinned session
            sessionIndex = index - 1;
            if (sessionIndex >= 0 && sessionIndex < pinnedSessions.length) {
              session = pinnedSessions[sessionIndex];
            }
          } else {
            // Unpinned session
            sessionIndex = index - pinnedSessions.length - 2;
            if (sessionIndex >= 0 && sessionIndex < unpinnedSessions.length) {
              session = unpinnedSessions[sessionIndex];
            }
          }
        } else {
          sessionIndex = index;
          if (sessionIndex >= 0 && sessionIndex < sessions.length) {
            session = sessions[sessionIndex];
          }
        }

        if (session == null) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          key: ValueKey('session_${session.key}'),
          child: SessionTile(
            session: session,
            isActive: activeSessionKey == session.key,
            onTap: () => onSessionTap(session),
            onDelete: onDelete,
            onArchive: onArchive,
            onPin: onPin,
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
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
          onTap: () => close(context, session),
        );
      },
    );
  }
}