/// Platform channel for Android foreground service
/// 
/// Provides control over the background service that maintains
/// WebSocket connection when the app is in the background.
library;

import 'dart:async';
import 'package:flutter/services.dart';

/// Connection status for the background service
enum BackgroundServiceStatus {
  connected,
  disconnected,
  reconnecting;

  static BackgroundServiceStatus fromString(String value) {
    return switch (value) {
      'connected' => BackgroundServiceStatus.connected,
      'disconnected' => BackgroundServiceStatus.disconnected,
      'reconnecting' => BackgroundServiceStatus.reconnecting,
      _ => BackgroundServiceStatus.disconnected,
    };
  }
}

/// Background service control via platform channel
/// 
/// Usage:
/// ```dart
/// // Start the service
/// await BackgroundService.startService(
///   title: 'ClawChat',
///   content: 'Connected to Gateway',
///   status: BackgroundServiceStatus.connected,
/// );
/// 
/// // Listen to status changes
/// BackgroundService.statusStream.listen((status) {
///   print('Service status: $status');
/// });
/// 
/// // Update status when connection changes
/// await BackgroundService.updateStatus(
///   status: BackgroundServiceStatus.reconnecting,
///   content: 'Attempting to reconnect...',
/// );
/// 
/// // Stop the service
/// await BackgroundService.stopService();
/// ```
class BackgroundService {
  static const _methodChannel = MethodChannel('com.openclaw.clawchat/background_service');
  static const _eventChannel = EventChannel('com.openclaw.clawchat/background_service_status');

  static Stream<BackgroundServiceStatus>? _statusStream;

  /// Stream of service status updates from the native side
  static Stream<BackgroundServiceStatus> get statusStream {
    return _statusStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => BackgroundServiceStatus.fromString(event as String));
  }

  /// Start foreground service with initial status
  /// 
  /// [title] - Notification title (default: "ClawChat")
  /// [content] - Notification content text
  /// [status] - Initial connection status
  /// 
  /// Returns true if service started successfully
  static Future<bool> startService({
    String title = 'ClawChat',
    String content = 'Connected to Gateway',
    BackgroundServiceStatus status = BackgroundServiceStatus.connected,
  }) async {
    try {
      await _methodChannel.invokeMethod('startService', {
        'title': title,
        'content': content,
        'status': status.name,
      });
      return true;
    } on PlatformException catch (e) {
      print('Failed to start background service: ${e.message}');
      return false;
    }
  }

  /// Stop foreground service
  /// 
  /// Returns true if service stopped successfully
  static Future<bool> stopService() async {
    try {
      await _methodChannel.invokeMethod('stopService');
      return true;
    } on PlatformException catch (e) {
      print('Failed to stop background service: ${e.message}');
      return false;
    }
  }

  /// Update notification status
  /// 
  /// [status] - Current connection status
  /// [title] - Optional new notification title
  /// [content] - Optional new notification content
  /// 
  /// Returns true if update succeeded
  static Future<bool> updateStatus({
    required BackgroundServiceStatus status,
    String? title,
    String? content,
  }) async {
    try {
      await _methodChannel.invokeMethod('updateNotification', {
        'status': status.name,
        'title': title,
        'content': content,
      });
      return true;
    } on PlatformException catch (e) {
      print('Failed to update notification: ${e.message}');
      return false;
    }
  }

  /// Get current service status
  /// 
  /// Returns the current status or null if unavailable
  static Future<BackgroundServiceStatus?> getStatus() async {
    try {
      final result = await _methodChannel.invokeMethod('getStatus');
      return BackgroundServiceStatus.fromString(result as String);
    } on PlatformException {
      return null;
    }
  }

  /// Update notification to show connected state
  static Future<bool> setConnected({String? content}) {
    return updateStatus(
      status: BackgroundServiceStatus.connected,
      title: 'ClawChat - Connected',
      content: content ?? 'WebSocket connection active',
    );
  }

  /// Update notification to show disconnected state
  static Future<bool> setDisconnected({String? content}) {
    return updateStatus(
      status: BackgroundServiceStatus.disconnected,
      title: 'ClawChat - Disconnected',
      content: content ?? 'WebSocket connection lost',
    );
  }

  /// Update notification to show reconnecting state
  static Future<bool> setReconnecting({String? content}) {
    return updateStatus(
      status: BackgroundServiceStatus.reconnecting,
      title: 'ClawChat - Reconnecting',
      content: content ?? 'Attempting to reconnect...',
    );
  }
}