/// Network Monitor
/// Monitors network connectivity changes and provides network status
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Network status information
class NetworkStatus {
  final bool isConnected;
  final ConnectivityResult connectionType;
  final DateTime timestamp;
  final bool isWifi;
  final bool isMobile;
  final bool isExpensive; // Mobile data is considered expensive

  const NetworkStatus({
    required this.isConnected,
    required this.connectionType,
    required this.timestamp,
    this.isWifi = false,
    this.isMobile = false,
    this.isExpensive = false,
  });

  factory NetworkStatus.fromResult(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    final isWifi = result == ConnectivityResult.wifi;
    final isMobile = result == ConnectivityResult.mobile;

    return NetworkStatus(
      isConnected: isConnected,
      connectionType: result,
      timestamp: DateTime.now(),
      isWifi: isWifi,
      isMobile: isMobile,
      isExpensive: isMobile,
    );
  }

  static const NetworkStatus disconnected = NetworkStatus(
    isConnected: false,
    connectionType: ConnectivityResult.none,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  @override
  String toString() => 'NetworkStatus(connected: $isConnected, type: $connectionType)';
}

/// Callback for network status changes
typedef NetworkStatusCallback = void Function(NetworkStatus status);

/// Callback for network restoration (useful for triggering reconnect)
typedef NetworkRestorationCallback = void Function(
  NetworkStatus previous,
  NetworkStatus current,
);

/// Monitors network connectivity changes using connectivity_plus
class NetworkMonitor {
  final Logger _logger;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkStatus _currentStatus = NetworkStatus.disconnected;
  final List<NetworkStatusCallback> _statusCallbacks = [];
  final List<NetworkRestorationCallback> _restorationCallbacks = [];

  NetworkMonitor({Logger? logger})
      : _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether network is currently connected
  bool get isConnected => _currentStatus.isConnected;

  /// Whether currently on WiFi
  bool get isWifi => _currentStatus.isWifi;

  /// Whether currently on mobile data
  bool get isMobile => _currentStatus.isMobile;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream {
    final controller = StreamController<NetworkStatus>.broadcast();
    
    void emitStatus(NetworkStatus status) {
      controller.add(status);
    }

    // Add current status
    if (_currentStatus.isConnected || 
        _currentStatus != NetworkStatus.disconnected) {
      controller.add(_currentStatus);
    }

    // Subscribe to changes
    final callback = emitStatus;
    onStatusChange(callback);

    // Cleanup on cancel
    controller.onCancel = () {
      offStatusChange(callback);
    };

    return controller.stream;
  }

  /// Start monitoring network connectivity
  Future<void> start() async {
    if (_subscription != null) {
      _logger.w('Network monitor already started');
      return;
    }

    // Get initial status
    try {
      final results = await Connectivity().checkConnectivity();
      _updateStatus(results);
      _logger.i('Network monitor started. Initial status: $_currentStatus');
    } catch (e) {
      _logger.e('Failed to get initial connectivity status', error: e);
      _currentStatus = NetworkStatus.disconnected;
    }

    // Subscribe to changes
    _subscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        _logger.e('Connectivity stream error', error: error);
      },
    );
  }

  /// Stop monitoring
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _logger.i('Network monitor stopped');
  }

  /// Subscribe to network status changes
  void onStatusChange(NetworkStatusCallback callback) {
    _statusCallbacks.add(callback);
  }

  /// Unsubscribe from network status changes
  void offStatusChange(NetworkStatusCallback callback) {
    _statusCallbacks.remove(callback);
  }

  /// Subscribe to network restoration events
  void onRestoration(NetworkRestorationCallback callback) {
    _restorationCallbacks.add(callback);
  }

  /// Unsubscribe from network restoration events
  void offRestoration(NetworkRestorationCallback callback) {
    _restorationCallbacks.remove(callback);
  }

  /// Check current connectivity status
  Future<NetworkStatus> checkStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateStatus(results);
      return _currentStatus;
    } catch (e) {
      _logger.e('Failed to check connectivity', error: e);
      return NetworkStatus.disconnected;
    }
  }

  // ===========================================================================
  // Private Methods
  // ===========================================================================

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final previousStatus = _currentStatus;
    _updateStatus(results);

    _logger.i(
      'Network changed: $previousStatus -> $_currentStatus',
    );

    // Notify callbacks
    for (final callback in _statusCallbacks) {
      callback(_currentStatus);
    }

    // Check for network restoration (was disconnected, now connected)
    if (!previousStatus.isConnected && _currentStatus.isConnected) {
      _logger.i('Network restored: ${_currentStatus.connectionType}');
      for (final callback in _restorationCallbacks) {
        callback(previousStatus, _currentStatus);
      }
    }

    // Check for network type change (WiFi <-> Mobile)
    if (previousStatus.isConnected && _currentStatus.isConnected) {
      if (previousStatus.isWifi != _currentStatus.isWifi) {
        _logger.i(
          'Network type changed: ${previousStatus.connectionType} -> ${_currentStatus.connectionType}',
        );
      }
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Take the first result if multiple (e.g., WiFi + VPN)
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _currentStatus = NetworkStatus.fromResult(result);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    _statusCallbacks.clear();
    _restorationCallbacks.clear();
  }
}