/// Platform channel for push notification handling
/// 
/// Provides FCM integration for ClawChat:
/// - Token management (get, refresh)
/// - Topic subscription
/// - Foreground message handling
/// - Notification tap handling
library;

import 'dart:async';
import 'package:flutter/services.dart';

/// Push notification message data
class PushMessage {
  final String? messageId;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? conversationId;
  final String? senderId;
  final String? senderName;
  final int? sentTime;
  final Map<String, dynamic> rawData;

  PushMessage({
    this.messageId,
    this.title,
    this.body,
    this.imageUrl,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.sentTime,
    this.rawData = const {},
  });

  factory PushMessage.fromMap(Map<dynamic, dynamic> map) {
    return PushMessage(
      messageId: map['messageId'] as String? ?? map['dataMessageId'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      imageUrl: map['imageUrl'] as String?,
      conversationId: map['conversationId'] as String?,
      senderId: map['senderId'] as String?,
      senderName: map['senderName'] as String?,
      sentTime: map['sentTime'] as int?,
      rawData: Map<String, dynamic>.from(map as Map),
    );
  }

  @override
  String toString() {
    return 'PushMessage(conversationId: $conversationId, sender: $senderName, title: $title)';
  }
}

/// Push notification event
class PushEvent {
  final String type;
  final String? token;
  final PushMessage? message;

  PushEvent._({required this.type, this.token, this.message});

  factory PushEvent.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? 'unknown';
    
    return PushEvent._(
      type: type,
      token: map['token'] as String?,
      message: map['data'] != null 
          ? PushMessage.fromMap(map['data'] as Map<dynamic, dynamic>)
          : null,
    );
  }
}

/// Callback for handling push messages
typedef PushMessageCallback = void Function(PushMessage message);

/// Callback for handling notification taps
typedef NotificationTapCallback = void Function(String conversationId, String? messageId);

/// Push notification handling via platform channel
/// 
/// Usage:
/// ```dart
/// // Initialize and get token
/// await PushNotification.initialize();
/// final token = await PushNotification.getToken();
/// 
/// // Listen to events
/// PushNotification.onTokenRefresh.listen((token) {
///   print('New FCM token: $token');
/// });
/// 
/// PushNotification.onMessage.listen((message) {
///   print('Received message: ${message.title}');
/// });
/// 
/// // Handle notification tap
/// PushNotification.onNotificationTap.listen((conversationId, messageId) {
///   // Navigate to conversation
/// });
/// 
/// // Subscribe to topics
/// await PushNotification.subscribeToTopic('user_${userId}');
/// ```
class PushNotification {
  static const _methodChannel = MethodChannel('com.openclaw.clawchat/push_notification');
  static const _eventChannel = EventChannel('com.openclaw.clawchat/push_notification_event');

  static Stream<PushEvent>? _eventStream;
  static StreamSubscription? _eventSubscription;
  
  static String? _currentToken;
  static PushMessageCallback? _onMessageCallback;
  static NotificationTapCallback? _onTapCallback;
  
  // Public streams
  static Stream<String> get onTokenRefresh => _getTokenStream();
  static Stream<PushMessage> get onMessage => _getMessageStream();
  
  // Pending notification data (from cold start)
  static String? get pendingConversationId => _pendingConversationId;
  static String? get pendingMessageId => _pendingMessageId;
  static String? get pendingSenderId => _pendingSenderId;
  static String? get pendingSenderName => _pendingSenderName;
  
  static String? _pendingConversationId;
  static String? _pendingMessageId;
  static String? _pendingSenderId;
  static String? _pendingSenderName;

  /// Initialize push notifications
  /// 
  /// Returns true if initialization succeeded
  /// 
  /// [onMessage] - Callback for foreground messages
  /// [onTap] - Callback for notification taps
  static Future<bool> initialize({
    PushMessageCallback? onMessage,
    NotificationTapCallback? onTap,
  }) async {
    _onMessageCallback = onMessage;
    _onTapCallback = onTap;
    
    try {
      await _methodChannel.invokeMethod('initialize');
      
      // Start listening to events
      _startEventListening();
      
      // Check for pending notification from cold start
      await _checkPendingNotification();
      
      return true;
    } on PlatformException catch (e) {
      print('Failed to initialize push notifications: ${e.message}');
      return false;
    }
  }
  
  /// Set app foreground state
  /// 
  /// When foreground is true, messages are delivered to the app without
  /// showing notifications. When false, notifications are shown.
  static Future<void> setForeground(bool foreground) async {
    try {
      await _methodChannel.invokeMethod('setForeground', {'foreground': foreground});
    } on PlatformException catch (e) {
      print('Failed to set foreground state: ${e.message}');
    }
  }

  /// Get FCM token
  /// 
  /// Returns the current FCM token or null if unavailable
  static Future<String?> getToken() async {
    try {
      final token = await _methodChannel.invokeMethod<String>('getToken');
      _currentToken = token;
      return token;
    } on PlatformException catch (e) {
      print('Failed to get FCM token: ${e.message}');
      return null;
    }
  }
  
  /// Get current cached token (if available)
  static String? get currentToken => _currentToken;

  /// Subscribe to topic
  /// 
  /// Returns true if subscription succeeded
  static Future<bool> subscribeToTopic(String topic) async {
    try {
      await _methodChannel.invokeMethod('subscribeToTopic', {'topic': topic});
      return true;
    } on PlatformException catch (e) {
      print('Failed to subscribe to topic: ${e.message}');
      return false;
    }
  }

  /// Unsubscribe from topic
  /// 
  /// Returns true if unsubscription succeeded
  static Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _methodChannel.invokeMethod('unsubscribeFromTopic', {'topic': topic});
      return true;
    } on PlatformException catch (e) {
      print('Failed to unsubscribe from topic: ${e.message}');
      return false;
    }
  }
  
  /// Register callback for notification taps
  static void onNotificationTap(NotificationTapCallback callback) {
    _onTapCallback = callback;
    // Handle any pending notification
    if (_pendingConversationId != null) {
      callback(_pendingConversationId!, _pendingMessageId);
      _clearPendingNotification();
    }
  }
  
  /// Dispose resources
  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
  
  // Private methods
  
  static void _startEventListening() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => PushEvent.fromMap(event as Map<dynamic, dynamic>));
    
    _eventSubscription ??= _eventStream?.listen(_handleEvent);
  }
  
  static void _handleEvent(PushEvent event) {
    switch (event.type) {
      case 'token':
        if (event.token != null) {
          _currentToken = event.token;
        }
        break;
      case 'message':
        if (event.message != null) {
          _onMessageCallback?.call(event.message!);
        }
        break;
    }
  }
  
  static Future<void> _checkPendingNotification() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getPendingNotification');
      if (result != null) {
        _pendingConversationId = result['conversationId'] as String?;
        _pendingMessageId = result['messageId'] as String?;
        _pendingSenderId = result['senderId'] as String?;
        _pendingSenderName = result['senderName'] as String?;
        
        if (_pendingConversationId != null && _onTapCallback != null) {
          _onTapCallback!(_pendingConversationId!, _pendingMessageId);
          _clearPendingNotification();
        }
      }
    } on PlatformException {
      // Method not implemented, use pending data from MainActivity
      if (_pendingConversationId != null && _onTapCallback != null) {
        _onTapCallback!(_pendingConversationId!, _pendingMessageId);
        _clearPendingNotification();
      }
    }
  }
  
  static void _clearPendingNotification() {
    _pendingConversationId = null;
    _pendingMessageId = null;
    _pendingSenderId = null;
    _pendingSenderName = null;
  }
  
  static Stream<String> _getTokenStream() {
    return _getEventStream()
        .where((event) => event.type == 'token' && event.token != null)
        .map((event) => event.token!);
  }
  
  static Stream<PushMessage> _getMessageStream() {
    return _getEventStream()
        .where((event) => event.type == 'message' && event.message != null)
        .map((event) => event.message!);
  }
  
  static Stream<PushEvent> _getEventStream() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => PushEvent.fromMap(event as Map<dynamic, dynamic>));
    return _eventStream!;
  }
}