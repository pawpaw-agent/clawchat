/// Connection Manager
/// Handles reconnection, heartbeat, network monitoring, and message queue
library;

import 'dart:async';

import 'package:logger/logger.dart';

import 'gateway_client.dart';
import 'gateway_protocol.dart';
import 'network_monitor.dart';
import 'reconnect_handler.dart';
import '../errors/app_exception.dart';

/// Configuration for ConnectionManager
class ConnectionConfig {
  final String version;
  final String? token;
  final String locale;
  final bool autoReconnect;
  final bool enableMessageQueue;
  final int maxPendingMessages;
  final Duration heartbeatTimeout;
  final Duration defaultTickInterval;
  final int maxReconnectAttempts;
  final Duration baseReconnectDelay;
  final Duration maxReconnectDelay;

  const ConnectionConfig({
    required this.version,
    this.token,
    this.locale = 'zh-CN',
    this.autoReconnect = true,
    this.enableMessageQueue = true,
    this.maxPendingMessages = 100,
    this.heartbeatTimeout = const Duration(seconds: 60),
    this.defaultTickInterval = const Duration(seconds: 15),
    this.maxReconnectAttempts = 10,
    this.baseReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
  });
}

/// Connection state with additional context
class ManagedGatewayConnectionState {
  final GatewayConnectionState connectionState;
  final NetworkStatus networkStatus;
  final bool isReconnecting;
  final int pendingMessages;
  final String? lastError;

  const ManagedGatewayConnectionState({
    required this.connectionState,
    required this.networkStatus,
    this.isReconnecting = false,
    this.pendingMessages = 0,
    this.lastError,
  });

  bool get isConnected => connectionState == GatewayConnectionState.authenticated;
  bool get hasNetwork => networkStatus.isConnected;
  bool get canSend => isConnected && hasNetwork && !isReconnecting;

  @override
  String toString() =>
      'ManagedGatewayConnectionState(connection: $connectionState, network: ${networkStatus.connectionTypes}, pending: $pendingMessages)';
}

/// Callback for managed connection state changes
typedef ManagedStateCallback = void Function(ManagedGatewayConnectionState state);

/// Manages WebSocket connection lifecycle with network monitoring and message queue
class ConnectionManager {
  final GatewayClient client;
  final NetworkMonitor networkMonitor;
  final ReconnectHandler reconnectHandler;
  final Logger _logger;

  // Configuration
  ConnectionConfig _config = const ConnectionConfig(version: '0.1.0');

  // State
  ManagedGatewayConnectionState _state = ManagedGatewayConnectionState(
    connectionState: GatewayConnectionState.disconnected,
    networkStatus: NetworkStatus.disconnected(),
  );
  
  final List<ManagedStateCallback> _stateCallbacks = [];

  // Heartbeat
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeat;
  Duration _tickInterval = const Duration(seconds: 15);

  // Subscriptions
  StreamSubscription? _clientStateSubscription;
  StreamSubscription? _eventSubscription;
  StreamSubscription? _networkSubscription;

  // Handshake parameters
  String _storedLocale = 'zh-CN';

  ConnectionManager({
    required this.client,
    NetworkMonitor? networkMonitor,
    ReconnectHandler? reconnectHandler,
    Logger? logger,
  })  : networkMonitor = networkMonitor ?? NetworkMonitor(logger: logger),
        reconnectHandler = reconnectHandler ?? ReconnectHandler(client: client, logger: logger),
        _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Current managed connection state
  ManagedGatewayConnectionState get state => _state;

  /// Whether connection is fully established and authenticated
  bool get isConnected => _state.isConnected;

  /// Whether network is available
  bool get hasNetwork => _state.hasNetwork;

  /// Whether messages can be sent
  bool get canSend => _state.canSend;

  /// Number of pending messages in queue
  int get pendingMessages => _state.pendingMessages;

  /// Configure the connection manager
  void configure(ConnectionConfig config) {
    _config = config;
    _tickInterval = config.defaultTickInterval;
    _logger.i('ConnectionManager configured');
  }

  /// Connect and maintain connection
  Future<void> connect({
    required String version,
    String? token,
    String locale = 'zh-CN',
  }) async {
    _storedLocale = locale;

    // Initialize reconnect handler
    reconnectHandler.initialize(
      version: version,
      token: token,
      locale: locale,
    );

    // Start network monitoring
    await networkMonitor.start();

    // Setup event listeners
    _setupEventListeners();

    // Attempt connection
    await _attemptConnection(version, token, locale);
  }

  /// Disconnect and stop all monitoring
  /// Disconnect and cleanup
  void disconnect() {
    _logger.i('Disconnecting...');

    // Stop monitoring
    networkMonitor.stop();
    _stopHeartbeatMonitoring();

    // Cancel subscriptions
    _clientStateSubscription?.cancel();
    _eventSubscription?.cancel();
    _networkSubscription?.cancel();

    // Disconnect client
    client.disconnect();

    _updateState(_state.copyWith(
      connectionState: GatewayConnectionState.disconnected,
    ));

    _logger.i('Disconnected');
  }

  /// Enable or disable automatic reconnection
  void setAutoReconnect(bool enabled) {
    reconnectHandler.setReconnectEnabled(enabled);
    _logger.i('Auto-reconnect ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Manually trigger reconnection
  Future<bool> reconnect() async {
    return reconnectHandler.reconnect();
  }

  /// Send a message (with queuing if disconnected)
  Future<ResponseFrame> send(
    String method,
    Map<String, dynamic> params, {
    Duration? timeout,
    bool requiresConfirmation = true,
  }) async {
    if (!canSend) {
      if (_config.enableMessageQueue) {
        // Queue for later
        return reconnectHandler.queueMessage(
          method,
          params,
          timeout: timeout,
          requiresConfirmation: requiresConfirmation,
        );
      }
      throw GatewayException('Cannot send: not connected');
    }

    return client.sendRequest(method, params, timeout: timeout ?? const Duration(seconds: 30));
  }

  /// Subscribe to connection state changes
  void onStateChange(ManagedStateCallback callback) {
    _stateCallbacks.add(callback);
  }

  /// Unsubscribe from connection state changes
  void offStateChange(ManagedStateCallback callback) {
    _stateCallbacks.remove(callback);
  }

  // ===========================================================================
  // Private Methods
  // ===========================================================================

  void _setupEventListeners() {
    // Monitor client connection state
    client.onStateChange(_handleClientStateChange);

    // Monitor network status
    networkMonitor.onStatusChange(_handleNetworkStatusChange);
    networkMonitor.onRestoration(_handleNetworkRestoration);

    // Monitor reconnect handler events
    reconnectHandler.onResendProgress((total, sent, failed) {
      _updateState(_state.copyWith(pendingMessages: total - sent - failed));
    });
  }

  Future<void> _attemptConnection(
    String version,
    String? token,
    String locale,
  ) async {
    _updateState(_state.copyWith(
      connectionState: GatewayConnectionState.connecting,
    ));

    try {
      await client.connect();
      final response = await client.completeHandshake(
        version: version,
        token: token,
        locale: locale,
      );

      // Update tick interval from policy
      if (response.policy?.tickIntervalMs != null) {
        _tickInterval = Duration(milliseconds: response.policy!.tickIntervalMs);
      }

      // Start heartbeat monitoring
      _startHeartbeatMonitoring();

      _updateState(_state.copyWith(
        connectionState: GatewayConnectionState.authenticated,
        pendingMessages: reconnectHandler.pendingCount,
      ));

      _logger.i('Connection established');
    } catch (e) {
      _logger.e('Connection failed', error: e);
      _updateState(_state.copyWith(
        connectionState: GatewayConnectionState.error,
        lastError: e.toString(),
      ));

      // Schedule reconnect if auto-reconnect is enabled
      if (_config.autoReconnect) {
        _scheduleReconnect();
      }

      rethrow;
    }
  }

  void _handleClientStateChange(GatewayConnectionState newState) {
    _logger.d('Client state changed: $newState');

    if (newState == GatewayConnectionState.disconnected) {
      // Connection lost - pause sending
      reconnectHandler.handleDisconnection();
    }

    _updateState(_state.copyWith(
      connectionState: newState,
    ));
  }

  void _handleNetworkStatusChange(NetworkStatus status) {
    _logger.i('Network status changed: $status');

    _updateState(_state.copyWith(
      networkStatus: status,
    ));
  }

  void _handleNetworkRestoration(NetworkStatus previous, NetworkStatus current) {
    _logger.i('Network restored: ${previous.connectionTypes} -> ${current.connectionTypes}');

    // If we're disconnected but should be connected, trigger reconnect
    if (_state.connectionState == GatewayConnectionState.disconnected ||
        _state.connectionState == GatewayConnectionState.error) {
      reconnectHandler.handleNetworkRestoration();
    }
  }

  void _startHeartbeatMonitoring() {
    _eventSubscription = client.eventStream.listen((event) {
      if (event.event == EventType.tick.value) {
        _lastHeartbeat = DateTime.now();
        _logger.d('Heartbeat received');
      }
    });

    _heartbeatTimer = Timer.periodic(_tickInterval, (_) => _checkHeartbeat());
    _lastHeartbeat = DateTime.now();
    _logger.d('Heartbeat monitoring started');
  }

  void _stopHeartbeatMonitoring() {
    _eventSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _logger.d('Heartbeat monitoring stopped');
  }

  void _checkHeartbeat() {
    if (_lastHeartbeat == null) return;

    final elapsed = DateTime.now().difference(_lastHeartbeat!);
    if (elapsed > _config.heartbeatTimeout) {
      _logger.w('Heartbeat timeout (${elapsed.inSeconds}s), triggering reconnect');
      _handleHeartbeatTimeout();
    }
  }

  void _handleHeartbeatTimeout() {
    // Disconnect and let reconnect handler deal with it
    client.disconnect().then((_) {
      reconnectHandler.handleDisconnection();
      if (_config.autoReconnect) {
        reconnectHandler.handleNetworkRestoration();
      }
    });
  }

  void _scheduleReconnect() {
    // ReconnectHandler will handle the scheduling
    reconnectHandler.handleNetworkRestoration();
  }

  void _updateState(ManagedGatewayConnectionState newState) {
    _state = newState;
    for (final callback in _stateCallbacks) {
      callback(_state);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    await networkMonitor.dispose();
    await reconnectHandler.dispose();
    _stateCallbacks.clear();
    _logger.i('ConnectionManager disposed');
  }
}

/// Extension to add copyWith to ManagedGatewayConnectionState
extension ManagedGatewayConnectionStateCopyWith on ManagedGatewayConnectionState {
  ManagedGatewayConnectionState copyWith({
    GatewayConnectionState? connectionState,
    NetworkStatus? networkStatus,
    bool? isReconnecting,
    int? pendingMessages,
    String? lastError,
  }) {
    return ManagedGatewayConnectionState(
      connectionState: connectionState ?? this.connectionState,
      networkStatus: networkStatus ?? this.networkStatus,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      pendingMessages: pendingMessages ?? this.pendingMessages,
      lastError: lastError ?? this.lastError,
    );
  }
}