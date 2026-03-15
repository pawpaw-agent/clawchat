/// Node controller with Riverpod state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/node.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/api/gateway_api_service.dart';

/// Node state
class NodeState {
  final List<Node> nodes;
  final Map<String, NodeDetail> nodeDetails;
  final bool isLoading;
  final bool isRefreshing;
  final AppException? error;
  final String? selectedNodeId;

  const NodeState({
    this.nodes = const [],
    this.nodeDetails = const {},
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedNodeId,
  });

  NodeState copyWith({
    List<Node>? nodes,
    Map<String, NodeDetail>? nodeDetails,
    bool? isLoading,
    bool? isRefreshing,
    AppException? error,
    String? selectedNodeId,
    bool clearError = false,
    bool clearSelectedNode = false,
  }) {
    return NodeState(
      nodes: nodes ?? this.nodes,
      nodeDetails: nodeDetails ?? this.nodeDetails,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      selectedNodeId: clearSelectedNode ? null : (selectedNodeId ?? this.selectedNodeId),
    );
  }

  /// Get selected node
  Node? get selectedNode {
    if (selectedNodeId == null) return null;
    try {
      return nodes.firstWhere((n) => n.id == selectedNodeId);
    } catch (_) {
      return null;
    }
  }

  /// Get selected node detail
  NodeDetail? get selectedNodeDetail {
    if (selectedNodeId == null) return null;
    return nodeDetails[selectedNodeId];
  }

  /// Get online nodes
  List<Node> get onlineNodes =>
      nodes.where((n) => n.status == NodeStatus.online).toList();

  /// Get nodes by status
  List<Node> getNodesByStatus(NodeStatus status) =>
      nodes.where((n) => n.status == status).toList();

  /// Whether there's an error
  bool get hasError => error != null;

  /// Whether error is recoverable (can retry)
  bool get canRetry => error?.isRecoverable ?? false;
}

/// Invoke state for tracking command execution
class InvokeState {
  final bool isInvoking;
  final String? command;
  final String? nodeId;
  final NodeInvokeResult? lastResult;
  final AppException? error;

  const InvokeState({
    this.isInvoking = false,
    this.command,
    this.nodeId,
    this.lastResult,
    this.error,
  });

  InvokeState copyWith({
    bool? isInvoking,
    String? command,
    String? nodeId,
    NodeInvokeResult? lastResult,
    AppException? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return InvokeState(
      isInvoking: isInvoking ?? this.isInvoking,
      command: command ?? this.command,
      nodeId: nodeId ?? this.nodeId,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Node notifier with error handling
class NodeNotifier extends StateNotifier<NodeState> with ErrorHandlingMixin {
  final GatewayApiService? _apiService;

  NodeNotifier({GatewayApiService? apiService})
      : _apiService = apiService,
        super(const NodeState()) {
    _loadData();
  }

  /// Load node data from API or mock
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);

    try {
      final apiService = _apiService;
      if (apiService != null && apiService.isConnected) {
        // Use real API
        final response = await apiService.listNodes();
        if (response.success && response.data != null) {
          state = state.copyWith(
            nodes: response.data,
            isLoading: false,
          );
          return;
        }
      }
    } catch (e) {
      // Fall back to mock
    }

    // Use mock data
    await _loadMockData();
  }

  /// Load mock data for development
  Future<void> _loadMockData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
      final mockNodes = [
        Node(
          id: 'node-rasp',
          displayName: 'Raspberry Pi',
          platform: 'linux',
          host: 'rasp',
          caps: ['camera', 'canvas', 'location'],
          commands: [
            'camera.snap',
            'camera.clip',
            'canvas.navigate',
            'canvas.snapshot',
            'location.get',
          ],
          status: NodeStatus.online,
          lastSeen: now.subtract(const Duration(seconds: 30)),
          createdAt: now.subtract(const Duration(days: 30)),
          version: '1.0.0',
          metadata: {
            'model': 'Raspberry Pi 5',
            'ip': '192.168.1.100',
          },
        ),
        Node(
          id: 'node-macos',
          displayName: 'MacBook Pro',
          platform: 'darwin',
          host: 'macbook',
          caps: ['canvas', 'system.run'],
          commands: [
            'canvas.navigate',
            'canvas.snapshot',
            'canvas.eval',
            'system.run',
          ],
          status: NodeStatus.online,
          lastSeen: now.subtract(const Duration(minutes: 5)),
          createdAt: now.subtract(const Duration(days: 60)),
          version: '1.0.0',
          metadata: {
            'model': 'MacBook Pro 14"',
            'ip': '192.168.1.101',
          },
        ),
        Node(
          id: 'node-android',
          displayName: 'Pixel Phone',
          platform: 'android',
          host: null,
          caps: ['camera', 'location'],
          commands: ['camera.snap', 'camera.clip', 'location.get'],
          status: NodeStatus.offline,
          lastSeen: now.subtract(const Duration(hours: 2)),
          createdAt: now.subtract(const Duration(days: 7)),
          version: '1.0.0',
          metadata: {
            'model': 'Pixel 8 Pro',
          },
        ),
        Node(
          id: 'node-browser',
          displayName: 'Chrome Browser',
          platform: 'web',
          host: null,
          caps: ['canvas'],
          commands: ['canvas.navigate', 'canvas.snapshot', 'canvas.eval'],
          status: NodeStatus.busy,
          lastSeen: now.subtract(const Duration(minutes: 10)),
          createdAt: now.subtract(const Duration(days: 14)),
          version: '1.0.0',
        ),
      ];

      state = state.copyWith(
        nodes: mockNodes,
        isLoading: false,
      );
  }

  /// Fetch node list
  Future<void> fetchNodes() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(isRefreshing: false);
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'NodeNotifier.fetchNodes',
      );
      state = state.copyWith(
        isRefreshing: false,
        error: result.exception,
      );
    }
  }

  /// Select a node
  void selectNode(String? nodeId) {
    if (nodeId == null) {
      state = state.copyWith(clearSelectedNode: true);
    } else {
      state = state.copyWith(selectedNodeId: nodeId);

      // Load details if not already loaded
      if (!state.nodeDetails.containsKey(nodeId)) {
        _loadNodeDetail(nodeId);
      }
    }
  }

  /// Load node detail
  Future<void> _loadNodeDetail(String nodeId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));

      final node = state.nodes.firstWhere((n) => n.id == nodeId);
      final detail = NodeDetail(
        id: node.id,
        displayName: node.displayName,
        platform: node.platform,
        host: node.host,
        caps: node.caps,
        commands: node.commands,
        status: node.status,
        lastSeen: node.lastSeen,
        createdAt: node.createdAt,
        version: node.version,
        metadata: node.metadata,
        commandDetails: _getMockCommandDetails(node.commands),
        capabilities: _getMockCapabilities(node.caps),
        uptimeSeconds: node.status == NodeStatus.online
            ? DateTime.now().difference(node.lastSeen ?? DateTime.now()).inSeconds + 86400
            : null,
      );

      state = state.copyWith(
        nodeDetails: {...state.nodeDetails, nodeId: detail},
      );
    } catch (e, stackTrace) {
      final result = handleError(
        e,
        stackTrace: stackTrace,
        context: 'NodeNotifier._loadNodeDetail',
      );
      state = state.copyWith(error: result.exception);
    }
  }

  /// Get mock command details
  Map<String, CommandInfo> _getMockCommandDetails(List<String> commands) {
    return {
      for (final cmd in commands)
        cmd: _getCommandInfo(cmd),
    };
  }

  /// Get command info for a command
  CommandInfo _getCommandInfo(String command) {
    return switch (command) {
      'camera.snap' => const CommandInfo(
          name: 'camera.snap',
          description: 'Take a photo with the camera',
          params: {'quality': 'number (0-100)', 'flash': 'boolean'},
          resultType: 'image',
        ),
      'camera.clip' => const CommandInfo(
          name: 'camera.clip',
          description: 'Record a video clip',
          params: {'duration': 'number (seconds)', 'quality': 'string'},
          resultType: 'video',
        ),
      'canvas.navigate' => const CommandInfo(
          name: 'canvas.navigate',
          description: 'Navigate to a URL',
          params: {'url': 'string (required)'},
          resultType: 'none',
        ),
      'canvas.snapshot' => const CommandInfo(
          name: 'canvas.snapshot',
          description: 'Take a screenshot of the canvas',
          params: {'fullPage': 'boolean'},
          resultType: 'image',
        ),
      'canvas.eval' => const CommandInfo(
          name: 'canvas.eval',
          description: 'Execute JavaScript in the canvas',
          params: {'script': 'string (required)'},
          resultType: 'any',
        ),
      'location.get' => const CommandInfo(
          name: 'location.get',
          description: 'Get current location',
          params: {},
          resultType: 'location',
        ),
      'system.run' => const CommandInfo(
          name: 'system.run',
          description: 'Run a system command',
          params: {
            'command': 'string (required)',
            'args': 'array of strings',
            'cwd': 'string',
          },
          resultType: 'command_result',
        ),
      _ => CommandInfo(name: command, description: 'Unknown command'),
    };
  }

  /// Get mock capabilities
  Map<String, dynamic> _getMockCapabilities(List<String> caps) {
    return {
      for (final cap in caps)
        cap: {
          'available': true,
          'lastChecked': DateTime.now().toIso8601String(),
        },
    };
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Retry the last failed operation
  Future<void> retry() async {
    if (!state.canRetry) return;
    await fetchNodes();
  }
}

/// Node invoke notifier for command execution
class NodeInvokeNotifier extends StateNotifier<InvokeState> with ErrorHandlingMixin {
  final String nodeId;

  NodeInvokeNotifier({
    required this.nodeId,
  }) : super(const InvokeState());

  /// Invoke a command on the node
  Future<NodeInvokeResult> invokeCommand({
    required String command,
    Map<String, dynamic>? params,
  }) async {
    state = state.copyWith(
      isInvoking: true,
      command: command,
      nodeId: nodeId,
      clearError: true,
      clearResult: true,
    );

    try {
      // Simulate command execution
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock result
      final result = NodeInvokeResult(
        id: const Uuid().v4(),
        nodeId: nodeId,
        command: command,
        success: true,
        result: _getMockResult(command),
        completedAt: DateTime.now(),
      );

      state = state.copyWith(
        isInvoking: false,
        lastResult: result,
      );

      return result;
    } catch (e, stackTrace) {
      final errorResult = handleError(
        e,
        stackTrace: stackTrace,
        context: 'NodeInvokeNotifier.invokeCommand',
      );

      state = state.copyWith(
        isInvoking: false,
        error: errorResult.exception,
      );

      final failedResult = NodeInvokeResult(
        id: const Uuid().v4(),
        nodeId: nodeId,
        command: command,
        success: false,
        error: errorResult.exception.userMessage,
        completedAt: DateTime.now(),
      );

      return failedResult;
    }
  }

  /// Get mock result for a command
  dynamic _getMockResult(String command) {
    return switch (command) {
      'camera.snap' => {
          'imageUrl': 'https://example.com/photos/mock_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'width': 1920,
          'height': 1080,
        },
      'camera.clip' => {
          'videoUrl': 'https://example.com/videos/mock_${DateTime.now().millisecondsSinceEpoch}.mp4',
          'duration': 5,
        },
      'canvas.navigate' => {
          'url': 'https://example.com',
          'title': 'Example Page',
        },
      'canvas.snapshot' => {
          'imageUrl': 'https://example.com/screenshots/mock_${DateTime.now().millisecondsSinceEpoch}.png',
          'width': 1920,
          'height': 1080,
        },
      'canvas.eval' => {
          'result': 'Script executed successfully',
        },
      'location.get' => {
          'latitude': 31.2304,
          'longitude': 121.4737,
          'accuracy': 10.0,
          'address': 'Shanghai, China',
        },
      'system.run' => {
          'stdout': 'Command executed successfully\nOutput: OK',
          'stderr': '',
          'exitCode': 0,
        },
      _ => {'status': 'completed'},
    };
  }

  /// Clear the last result
  void clearResult() {
    state = state.copyWith(clearResult: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Node state provider
final nodeProvider =
    StateNotifierProvider<NodeNotifier, NodeState>((ref) {
  return NodeNotifier();
});

/// Selected node provider
final selectedNodeProvider = Provider<Node?>((ref) {
  final state = ref.watch(nodeProvider);
  return state.selectedNode;
});

/// Selected node detail provider
final selectedNodeDetailProvider = Provider<NodeDetail?>((ref) {
  final state = ref.watch(nodeProvider);
  return state.selectedNodeDetail;
});

/// Online nodes provider
final onlineNodesProvider = Provider<List<Node>>((ref) {
  final state = ref.watch(nodeProvider);
  return state.onlineNodes;
});

/// Node invoke provider family (one per node)
final nodeInvokeProvider = StateNotifierProvider.family<NodeInvokeNotifier, InvokeState, String>(
  (ref, nodeId) => NodeInvokeNotifier(nodeId: nodeId),
);