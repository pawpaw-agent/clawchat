/// Push notification handler for navigation and UI updates
/// 
/// Provides:
/// - Navigation to conversation on notification tap
/// - Foreground message handling
/// - Integration with app's navigation system
library;

import 'package:flutter/foundation.dart';
import 'push_notification.dart';

/// Navigation callback type
typedef NavigateToConversationCallback = void Function(
  String conversationId, {
  String? messageId,
  String? senderId,
  String? senderName,
});

/// Handler for push notifications
/// 
/// Coordinates between PushNotification platform channel and app logic:
/// - Shows notifications in background (handled by native)
/// - Forwards foreground messages to UI
/// - Handles notification taps for navigation
/// 
/// Usage:
/// ```dart
/// // In your app initialization
/// await PushHandler.initialize(
///   onNavigateToConversation: (conversationId, {messageId, senderId, senderName}) {
///     // Navigate to chat screen
///     navigator.push(ChatScreen(conversationId: conversationId));
///   },
/// );
/// 
/// // Check for initial notification (from cold start)
/// final initialNotification = await PushHandler.getInitialNotification();
/// if (initialNotification != null) {
///   // Handle navigation
/// }
/// ```
class PushHandler {
  static bool _initialized = false;
  static NavigateToConversationCallback? _navigateCallback;
  static final List<PushMessage> _pendingMessages = [];
  
  /// Get all pending foreground messages
  /// 
  /// Messages are accumulated when app is in foreground and
  /// can be processed when UI is ready
  static List<PushMessage> get pendingMessages => List.unmodifiable(_pendingMessages);
  
  /// Check if handler is initialized
  static bool get isInitialized => _initialized;

  /// Initialize push notification handling
  /// 
  /// [onNavigateToConversation] - Callback to navigate to a conversation
  /// [showForegroundNotifications] - Whether to show notifications when app is in foreground
  ///   (default: false, just update UI)
  /// 
  /// Returns true if initialization succeeded
  static Future<bool> initialize({
    NavigateToConversationCallback? onNavigateToConversation,
    bool showForegroundNotifications = false,
  }) async {
    if (_initialized) {
      print('PushHandler already initialized');
      return true;
    }
    
    _navigateCallback = onNavigateToConversation;
    
    try {
      // Initialize platform channel
      final success = await PushNotification.initialize(
        onMessage: _handleForegroundMessage,
        onTap: _handleNotificationTap,
      );
      
      if (success) {
        _initialized = true;
        
        // Get FCM token
        final token = await PushNotification.getToken();
        if (token != null) {
          print('FCM Token: ${token.substring(0, 20)}...');
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Failed to initialize PushHandler: $e');
      return false;
    }
  }
  
  /// Set navigation callback after initialization
  /// 
  /// Use this if you need to set the callback later (e.g., after
  /// navigator is available)
  static void setNavigationCallback(NavigateToConversationCallback callback) {
    _navigateCallback = callback;
    
    // Process any pending navigation
    final pendingConvId = PushNotification.pendingConversationId;
    if (pendingConvId != null) {
      _navigateCallback?.call(
        pendingConvId,
        messageId: PushNotification.pendingMessageId,
        senderId: PushNotification.pendingSenderId,
        senderName: PushNotification.pendingSenderName,
      );
    }
  }
  
  /// Notify handler when app enters foreground
  /// 
  /// This stops showing notifications and starts forwarding
  /// messages directly to the app
  static Future<void> onAppForeground() async {
    await PushNotification.setForeground(true);
    debugPrint('PushHandler: App in foreground');
  }
  
  /// Notify handler when app enters background
  /// 
  /// This starts showing notifications for incoming messages
  static Future<void> onAppBackground() async {
    await PushNotification.setForeground(false);
    debugPrint('PushHandler: App in background');
  }
  
  /// Subscribe to user-specific topic for push notifications
  /// 
  /// Call this after user login to receive personal notifications
  static Future<bool> subscribeToUserTopic(String userId) async {
    return PushNotification.subscribeToTopic('user_$userId');
  }
  
  /// Unsubscribe from user-specific topic
  /// 
  /// Call this on user logout
  static Future<bool> unsubscribeFromUserTopic(String userId) async {
    return PushNotification.unsubscribeFromTopic('user_$userId');
  }
  
  /// Subscribe to conversation topic
  /// 
  /// Optional: Subscribe to specific conversation notifications
  static Future<bool> subscribeToConversationTopic(String conversationId) async {
    return PushNotification.subscribeToTopic('conversation_$conversationId');
  }
  
  /// Unsubscribe from conversation topic
  static Future<bool> unsubscribeFromConversationTopic(String conversationId) async {
    return PushNotification.unsubscribeFromTopic('conversation_$conversationId');
  }
  
  /// Get current FCM token
  static String? get currentToken => PushNotification.currentToken;
  
  /// Stream of foreground messages
  /// 
  /// Use this to update UI when messages arrive while app is visible
  static Stream<PushMessage> get onForegroundMessage => 
      PushNotification.onMessage;
  
  /// Clear pending messages
  static void clearPendingMessages() {
    _pendingMessages.clear();
  }
  
  /// Dispose handler
  static void dispose() {
    PushNotification.dispose();
    _initialized = false;
    _navigateCallback = null;
    _pendingMessages.clear();
  }
  
  // Private handlers
  
  static void _handleForegroundMessage(PushMessage message) {
    debugPrint('PushHandler: Foreground message: ${message.title}');
    
    // Store for UI to process
    _pendingMessages.add(message);
    
    // Keep only last 100 messages
    if (_pendingMessages.length > 100) {
      _pendingMessages.removeAt(0);
    }
  }
  
  static void _handleNotificationTap(String conversationId, String? messageId) {
    debugPrint('PushHandler: Notification tap for conversation: $conversationId');
    
    _navigateCallback?.call(
      conversationId,
      messageId: messageId,
      senderId: PushNotification.pendingSenderId,
      senderName: PushNotification.pendingSenderName,
    );
  }
}