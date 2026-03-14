/// Connection Manager
/// Handles reconnection, heartbeat, and network state
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import 'gateway_client.dart';
import 'gateway_protocol.dart';

/// Manages WebSocket connection lifecycle
class ConnectionManager {
  final GatewayClient client;
  final Logger _logger;

  // Reconnection settings
  static const int maxReconnectAttempts = 10;
  static const Duration baseReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);

  // Heartbeat settings
  static const Duration heartbeatTimeout = Duration(seconds: 60);
  static const Duration defaultTickInterval = Duration(seconds: 15);

  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  bool _shouldReconnect = true;
  
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeat;
  
  Duration _tickInterval = defaultTickInterval;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<EventFrame>? _eventSubscription;

  ConnectionManager({
    required this.client,
    Logger? logger,
  }) : _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Connect and maintain connection
  Future<void> connectAndMaintain({
    required String version,
    String? token,
    String locale = 'zh-CN',
  }) async {
    _shouldReconnect = true;
    
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

      // Reset reconnect attempts on success
      _reconnectAttempts = 0;
      _logger.i('Connection established');
    } catch (e) {
      _logger.e('Connection failed', error: e);
      
      if (_shouldReconnect) {
        _scheduleReconnect(version, token, locale);
      }
      
      rethrow;
    }
  }

  /// Disconnect and stop reconnection
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _stopHeartbeatMonitoring();
    _cancelReconnectTimer();
    await client.disconnect();
    _logger.i('Disconnected');
  }

  /// Start monitoring network connectivity
  void startNetworkMonitoring({
    required String version,
    String? token,
    String locale = 'zh-CN',
  }) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((result) {
      _handleConnectivityChange(result, version, token, locale);
    });
    _logger.d('Network monitoring started');
  }

  /// Stop network monitoring
  void stopNetworkMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _logger.d('Network monitoring stopped');
  }

  // ===========================================================================
  // Private Methods
  // ===========================================================================

  void _startHeartbeatMonitoring() {
    _eventSubscription = client.eventStream.listen((event) {
      if (event.event == EventType.tick.value) {
        _lastHeartbeat = DateTime.now();
        _logger.d('Heartbeat received');
      }
    });

    _heartbeatTimer = Timer.periodic(
      _tickInterval,
      (_) => _checkHeartbeat(),
    );

    _lastHeartbeat = DateTime.now();
    _logger.d('Heartbeat monitoring started');
  }

  void _stopHeartbeatMonitoring() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _logger.d('Heartbeat monitoring stopped');
  }

  void _checkHeartbeat() {
    if (_lastHeartbeat == null) return;

    final elapsed = DateTime.now().difference(_lastHeartbeat!);
    
    if (elapsed > heartbeatTimeout) {
      _logger.w('Heartbeat timeout (${elapsed.inSeconds}s), reconnecting...');
      _forceReconnect();
    }
  }

  void _forceReconnect() async {
    await client.disconnect();
    
    // Reconnect will be triggered by state change
    // Or manually trigger here
  }

  void _handleConnectivityChange(
    ConnectivityResult result,
    String version,
    String? token,
    String locale,
  ) {
    _logger.i('Network connectivity changed: $result');

    if (result == ConnectivityResult.none) {
      // Network lost
      _logger.w('Network lost');
      return;
    }

    // Network available, check if we need to reconnect
    if (!client.isConnected && _shouldReconnect && !_isReconnecting) {
      _logger.i('Network restored, reconnecting...');
      _scheduleReconnect(version, token, locale, immediate: true);
    }
  }

  void _scheduleReconnect(
    String version,
    String? token,
    String locale, {
    bool immediate = false,
  }) {
    if (!_shouldReconnect || _isReconnecting) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      _logger.e('Max reconnect attempts reached');
      return;
    }

    _isReconnecting = true;

    final delay = immediate
        ? Duration.zero
        : _calculateReconnectDelay();

    _logger.i('Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () async {
      try {
        _reconnectAttempts++;
        await connectAndMaintain(
          version: version,
          token: token,
          locale: locale,
        );
        _isReconnecting = false;
      } catch (e) {
        _isReconnecting = false;
        // Will schedule another reconnect via connectAndMaintain error handling
      }
    });
  }

  Duration _calculateReconnectDelay() {
    final delayMs = baseReconnectDelay.inMilliseconds *
        (1 << _reconnectAttempts.clamp(0, 10));
    
    final clamped = delayMs.clamp(
      baseReconnectDelay.inMilliseconds,
      maxReconnectDelay.inMilliseconds,
    );
    
    return Duration(milliseconds: clamped);
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    stopNetworkMonitoring();
  }
}