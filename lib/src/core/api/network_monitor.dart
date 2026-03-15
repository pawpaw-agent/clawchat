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

  /// Disconnected status factory (not const due to DateTime.now())
  static NetworkStatus disconnected() => NetworkStatus(
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

  StreamSubscription<ConnectivityResult>? _subscription;
  NetworkStatus _currentStatus = NetworkStatus.disconnected();
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
    emitStatus(_currentStatus);

    // Listen for changes
    _statusCallbacks.add(emitStatus);

    return controller.stream;
  }

  /// Start monitoring network connectivity
  Future<void> start() async {
    _logger.i('Starting network monitor...');
    
    try {
      // Get initial status
      final result = await Connectivity().checkConnectivity();
      _updateStatus(result);
      
      // Listen for changes
      _subscription = Connectivity().onConnectivityChanged.listen(
        _updateStatus,
        onError: (error) {
          _logger.e('Network monitor error', error: error);
        },
      );
      
      _logger.i('Network monitor started');
    } catch (e) {
      _logger.e('Failed to start network monitor', error: e);
    }
  }

  /// Stop monitoring
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _logger.i('Network monitor stopped');
  }

  /// Register a callback for network status changes
  void onStatusChanged(NetworkStatusCallback callback) {
    _statusCallbacks.add(callback);
  }

  /// Register a callback for network restoration (reconnect trigger)
  void onRestoration(NetworkRestorationCallback callback) {
    _restorationCallbacks.add(callback);
  }

  /// Remove a registered callback
  void removeCallback(NetworkStatusCallback callback) {
    _statusCallbacks.remove(callback);
  }

  /// Remove a registered restoration callback
  void removeRestorationCallback(NetworkRestorationCallback callback) {
    _restorationCallbacks.remove(callback);
  }

  void _updateStatus(ConnectivityResult result) {
    final previousStatus = _currentStatus;
    final newStatus = NetworkStatus.fromResult(result);
    
    _currentStatus = newStatus;
    
    _logger.d('Network status changed: $previousStatus -> $newStatus');
    
    // Notify status callbacks
    for (final callback in _statusCallbacks) {
      try {
        callback(newStatus);
      } catch (e) {
        _logger.e('Error in status callback', error: e);
      }
    }
    
    // Check for restoration (was disconnected, now connected)
    if (!previousStatus.isConnected && newStatus.isConnected) {
      _logger.i('Network restored: ${newStatus.connectionType}');
      for (final callback in _restorationCallbacks) {
        try {
          callback(previousStatus, newStatus);
        } catch (e) {
          _logger.e('Error in restoration callback', error: e);
        }
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    stop();
    _statusCallbacks.clear();
    _restorationCallbacks.clear();
  }
}