/// Background Polling Service
/// Uses WorkManager to periodically check for new messages when WebSocket is disconnected
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:logger/logger.dart';

/// Callback dispatcher for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger(printer: PrettyPrinter());
    
    try {
      logger.i('[PollingService] Background task started: $task');
      
      // Get stored credentials
      final gatewayUrl = inputData?['gatewayUrl'] as String?;
      final deviceToken = inputData?['deviceToken'] as String?;
      
      if (gatewayUrl == null || deviceToken == null) {
        logger.w('[PollingService] Missing credentials, skipping poll');
        return Future.value(true);
      }
      
      // Poll for new messages
      final pollResult = await _pollForMessages(gatewayUrl, deviceToken, logger);
      
      logger.i('[PollingService] Poll completed: $pollResult');
      return Future.value(true);
    } catch (e, stack) {
      logger.e('[PollingService] Background task failed', error: e, stackTrace: stack);
      return Future.value(false);
    }
  });
}

/// Poll gateway for new messages
Future<PollResult> _pollForMessages(
  String gatewayUrl,
  String deviceToken,
  Logger logger,
) async {
  try {
    // Create a temporary client for polling
    // In production, this would use HTTP REST API instead of WebSocket
    logger.i('[PollingService] Polling $gatewayUrl for new messages');
    
    // Simulate poll result
    // Real implementation would:
    // 1. Make HTTP request to gateway REST API
    // 2. Get list of unread messages
    // 3. Store locally
    // 4. Show notification if needed
    
    return PollResult(
      success: true,
      newMessageCount: 0,
      timestamp: DateTime.now(),
    );
  } catch (e) {
    logger.e('[PollingService] Poll failed', error: e);
    return PollResult(
      success: false,
      error: e.toString(),
      timestamp: DateTime.now(),
    );
  }
}

/// Result of a poll operation
class PollResult {
  final bool success;
  final int newMessageCount;
  final String? error;
  final DateTime timestamp;

  PollResult({
    required this.success,
    this.newMessageCount = 0,
    this.error,
    required this.timestamp,
  });

  @override
  String toString() => 'PollResult(success: $success, newMessages: $newMessageCount)';
}

/// Background polling service manager
class PollingService {
  static const String taskName = 'clawchat-poll-messages';
  static const Duration defaultInterval = Duration(minutes: 15);
  
  final Logger _logger;
  bool _isInitialized = false;

  PollingService({Logger? logger})
      : _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Initialize the polling service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('[PollingService] Already initialized');
      return;
    }

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    _isInitialized = true;
    _logger.i('[PollingService] Initialized');
  }

  /// Start periodic polling
  Future<void> startPolling({
    required String gatewayUrl,
    required String deviceToken,
    Duration interval = defaultInterval,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _logger.i('[PollingService] Starting periodic polling (interval: $interval)');

    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: interval,
      inputData: {
        'gatewayUrl': gatewayUrl,
        'deviceToken': deviceToken,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  /// Stop polling
  Future<void> stopPolling() async {
    _logger.i('[PollingService] Stopping polling');
    await Workmanager().cancelByUniqueName(taskName);
  }

  /// Stop all tasks
  Future<void> stopAll() async {
    _logger.i('[PollingService] Stopping all tasks');
    await Workmanager().cancelAll();
  }

  /// Run a one-off poll immediately
  Future<void> pollNow({
    required String gatewayUrl,
    required String deviceToken,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _logger.i('[PollingService] Running one-off poll');

    await Workmanager().registerOneOffTask(
      '${taskName}-once',
      taskName,
      inputData: {
        'gatewayUrl': gatewayUrl,
        'deviceToken': deviceToken,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}