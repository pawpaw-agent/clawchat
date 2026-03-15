/// Reconnect Handler
/// Handles reconnection logic and message resend on network restoration
library;

import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'gateway_client.dart';
import 'gateway_protocol.dart';
import '../errors/app_exception.dart';

/// Pending message that needs to be resent after reconnection
class PendingMessage {
  final String id;
  final String method;
  final Map<String, dynamic> params;
  final DateTime createdAt;
  final int sendAttempts;
  final Duration? timeout;
  final bool requiresConfirmation;

  const PendingMessage({
    required this.id,
    required this.method,
    required this.params,
    required this.createdAt,
    this.sendAttempts = 0,
    this.timeout,
    this.requiresConfirmation = true,
  });

  /// Maximum number of resend attempts
  static const int maxAttempts = 3;

  /// Maximum age of pending message (5 minutes)
  static const Duration maxAge = Duration(minutes: 5);

  /// Create a copy with updated attempts
  PendingMessage withIncrementedAttempts() {
    return PendingMessage(
      id: id,
      method: method,
      params: params,
      createdAt: createdAt,
      sendAttempts: sendAttempts + 1,
      timeout: timeout,
      requiresConfirmation: requiresConfirmation,
    );
  }

  /// Check if message should be expired
  bool get isExpired => DateTime.now().difference(createdAt) > maxAge;

  /// Check if message can be retried
  bool get canRetry => sendAttempts < maxAttempts && !isExpired;

  @override
  String toString() => 'PendingMessage(id: $id, method: $method, attempts: $sendAttempts)';
}

/// Callback when a message is sent
typedef MessageSentCallback = void Function(PendingMessage message);

/// Callback when a message fails permanently
typedef MessageFailedCallback = void Function(
  PendingMessage message,
  String error,
);

/// Callback for resend progress
typedef ResendProgressCallback = void Function(
  int total,
  int sent,
  int failed,
);

/// Handles reconnection and message resending
class ReconnectHandler {
  final GatewayClient client;
  final Logger _logger;

  // Reconnection settings
  static const int maxReconnectAttempts = 10;
  static const Duration baseReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);
  static const Duration immediateReconnectDelay = Duration(milliseconds: 500);

  // Message queue settings
  final int maxPendingMessages;
  final bool enableMessageQueue;

  // State
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  bool _shouldReconnect = true;
  bool _sendPaused = false;

  // Pending messages (ordered by creation time)
  final Queue<PendingMessage> _pendingQueue = Queue<PendingMessage>();
  
  // Messages awaiting confirmation
  final Map<String, PendingMessage> _unconfirmedMessages = {};

  // Callbacks
  Timer? _reconnectTimer;
  Timer? _queueCleanupTimer;
  
  final List<MessageSentCallback> _sentCallbacks = [];
  final List<MessageFailedCallback> _failedCallbacks = [];
  final List<ResendProgressCallback> _resendProgressCallbacks = [];

  // Connection state subscription
  StreamSubscription? _stateSubscription;
  StreamSubscription? _eventSubscription;

  // Handshake parameters (stored for reconnection)
  String? _storedVersion;
  String? _storedToken;
  String _storedLocale = 'zh-CN';

  ReconnectHandler({
    required this.client,
    Logger? logger,
    this.maxPendingMessages = 100,
    this.enableMessageQueue = true,
  }) : _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Whether currently reconnecting
  bool get isReconnecting => _isReconnecting;

  /// Whether automatic reconnection is enabled
  bool get shouldReconnect => _shouldReconnect;

  /// Number of pending messages in queue
  int get pendingCount => _pendingQueue.length + _unconfirmedMessages.length;

  /// Whether sending is paused (due to disconnection)
  bool get sendPaused => _sendPaused;

  /// Enable or disable automatic reconnection
  void setReconnectEnabled(bool enabled) {
    _shouldReconnect = enabled;
    _logger.i('Auto-reconnect ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Initialize handler and subscribe to client state changes
  void initialize({
    required String version,
    String? token,
    String locale = 'zh-CN',
  }) {
    _storedVersion = version;
    _storedToken = token;
    _storedLocale = locale;

    // Subscribe to connection state changes
    _stateSubscription = null; // Will be set up differently based on client implementation
    
    // Start periodic queue cleanup
    _startQueueCleanup();

    _logger.i('ReconnectHandler initialized');
  }

  /// Handle network disconnection - pause sending and cache messages
  void handleDisconnection() {
    _logger.w('Handling disconnection - pausing sends');
    _sendPaused = true;
  }

  /// Handle network restoration - reconnect and resend pending messages
  Future<void> handleNetworkRestoration() async {
    if (!_shouldReconnect) {
      _logger.i('Auto-reconnect disabled, skipping');
      return;
    }

    _logger.i('Network restored, initiating reconnection...');
    await reconnect();
  }

  /// Trigger reconnection
  Future<bool> reconnect() async {
    if (_isReconnecting) {
      _logger.w('Already reconnecting, skipping');
      return false;
    }

    // Check all required parameters
    if (_storedVersion == null || _storedLocale.isEmpty) {
      _logger.e('Cannot reconnect: handshake parameters not set (version=${_storedVersion}, locale=$_storedLocale)');
      return false;
    }

    _isReconnecting = true;

    try {
      _logger.i('Reconnecting (attempt ${_reconnectAttempts + 1})...');

      // Disconnect existing connection if any
      if (client.state != GatewayConnectionState.disconnected) {
        await client.disconnect();
      }

      // Attempt to connect
      await client.connect();
      await client.completeHandshake(
        version: _storedVersion!,
        token: _storedToken,
        locale: _storedLocale,
      );

      _logger.i('Reconnection successful');
      _reconnectAttempts = 0;
      _sendPaused = false;
      _isReconnecting = false;

      // Resend pending messages
      await _resendPendingMessages();

      return true;
    } catch (e) {
      _logger.e('Reconnection failed', error: e);
      _isReconnecting = false;
      _reconnectAttempts++;

      // Schedule next attempt
      if (_shouldReconnect && _reconnectAttempts < maxReconnectAttempts) {
        _scheduleReconnect();
      }

      return false;
    }
  }

  /// Queue a message for sending (will be cached if disconnected)
  Future<ResponseFrame> queueMessage(
    String method,
    Map<String, dynamic> params, {
    String? id,
    Duration? timeout,
    bool requiresConfirmation = true,
  }) {
    final messageId = id ?? const Uuid().v4();

    if (_sendPaused || !client.isConnected) {
      if (!enableMessageQueue) {
        throw GatewayException('Not connected and message queue disabled');
      }

      // Queue the message
      final pending = PendingMessage(
        id: messageId,
        method: method,
        params: params,
        createdAt: DateTime.now(),
        timeout: timeout,
        requiresConfirmation: requiresConfirmation,
      );

      _addToQueue(pending);
      _logger.i('Message queued: $method (id: $messageId)');

      // Return a future that will complete when the message is sent
      // This is a placeholder - actual implementation would need to track this
      throw GatewayException('Message queued for later delivery');
    }

    // Send immediately if connected
    return client.sendRequest(method, params);
  }

  /// Add message to pending queue
  void _addToQueue(PendingMessage message) {
    if (_pendingQueue.length >= maxPendingMessages) {
      // Remove oldest message
      final removed = _pendingQueue.removeFirst();
      _notifyFailed(removed, 'Queue full, message dropped');
      _logger.w('Queue full, dropped oldest message: ${removed.id}');
    }

    _pendingQueue.add(message);
  }

  /// Mark a message as sent (awaiting confirmation)
  void markAsSent(PendingMessage message) {
    _unconfirmedMessages[message.id] = message;
    _notifySent(message);
  }

  /// Mark a message as confirmed (remove from pending)
  void markAsConfirmed(String messageId) {
    final removed = _unconfirmedMessages.remove(messageId);
    if (removed != null) {
      _logger.d('Message confirmed: $messageId');
    }
  }

  /// Resend all pending messages after reconnection
  Future<void> _resendPendingMessages() async {
    if (!client.isConnected) {
      _logger.w('Cannot resend: not connected');
      return;
    }

    final total = _pendingQueue.length + _unconfirmedMessages.length;
    if (total == 0) {
      _logger.i('No pending messages to resend');
      return;
    }

    _logger.i('Resending $total pending messages...');
    int sent = 0;
    int failed = 0;

    // First, resend unconfirmed messages
    final unconfirmedCopy = Map<String, PendingMessage>.from(_unconfirmedMessages);
    for (final entry in unconfirmedCopy.entries) {
      final message = entry.value;
      if (await _tryResend(message)) {
        sent++;
      } else {
        failed++;
      }
      _notifyProgress(total, sent, failed);
    }

    // Then, send queued messages
    while (_pendingQueue.isNotEmpty) {
      final message = _pendingQueue.removeFirst();
      if (await _tryResend(message)) {
        sent++;
      } else {
        failed++;
      }
      _notifyProgress(total, sent, failed);
    }

    _logger.i('Resend complete: $sent sent, $failed failed');
  }

  /// Try to resend a single message
  Future<bool> _tryResend(PendingMessage message) async {
    if (!message.canRetry) {
      _notifyFailed(message, 'Message expired or max attempts reached');
      return false;
    }

    try {
      final updatedMessage = message.withIncrementedAttempts();
      
      await client.sendRequest(
        message.method,
        message.params,
        timeout: message.timeout ?? const Duration(seconds: 30),
      );

      if (message.requiresConfirmation) {
        markAsSent(updatedMessage);
      }

      _logger.d('Resent message: ${message.id}');
      return true;
    } catch (e) {
      _logger.w('Failed to resend message ${message.id}: $e');
      
      if (!message.canRetry) {
        _notifyFailed(message, e.toString());
        return false;
      }

      // Re-queue for later attempt
      _addToQueue(message.withIncrementedAttempts());
      return false;
    }
  }

  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (!_shouldReconnect || _isReconnecting) return;

    final delay = _calculateReconnectDelay();
    _logger.i('Scheduling reconnect in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      await reconnect();
    });
  }

  /// Calculate delay for next reconnection attempt (exponential backoff)
  Duration _calculateReconnectDelay() {
    if (_reconnectAttempts == 0) {
      return immediateReconnectDelay;
    }

    final delayMs = baseReconnectDelay.inMilliseconds *
        (1 << _reconnectAttempts.clamp(0, 10));

    final clamped = delayMs.clamp(
      baseReconnectDelay.inMilliseconds,
      maxReconnectDelay.inMilliseconds,
    );

    return Duration(milliseconds: clamped);
  }

  /// Start periodic cleanup of expired messages
  void _startQueueCleanup() {
    _queueCleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupExpiredMessages(),
    );
  }

  /// Remove expired messages from queue
  void _cleanupExpiredMessages() {
    final before = _pendingQueue.length;
    
    _pendingQueue.removeWhere((message) {
      if (message.isExpired) {
        _notifyFailed(message, 'Message expired');
        return true;
      }
      return false;
    });

    _unconfirmedMessages.removeWhere((key, message) {
      if (message.isExpired) {
        _notifyFailed(message, 'Message expired');
        return true;
      }
      return false;
    });

    final removed = before - _pendingQueue.length;
    if (removed > 0) {
      _logger.d('Cleaned up $removed expired messages');
    }
  }

  /// Notify callbacks about sent message
  void _notifySent(PendingMessage message) {
    for (final callback in _sentCallbacks) {
      callback(message);
    }
  }

  /// Notify callbacks about failed message
  void _notifyFailed(PendingMessage message, String error) {
    for (final callback in _failedCallbacks) {
      callback(message, error);
    }
  }

  /// Notify callbacks about resend progress
  void _notifyProgress(int total, int sent, int failed) {
    for (final callback in _resendProgressCallbacks) {
      callback(total, sent, failed);
    }
  }

  // ===========================================================================
  // Callback Registration
  // ===========================================================================

  /// Subscribe to message sent events
  void onMessageSent(MessageSentCallback callback) {
    _sentCallbacks.add(callback);
  }

  /// Unsubscribe from message sent events
  void offMessageSent(MessageSentCallback callback) {
    _sentCallbacks.remove(callback);
  }

  /// Subscribe to message failed events
  void onMessageFailed(MessageFailedCallback callback) {
    _failedCallbacks.add(callback);
  }

  /// Unsubscribe from message failed events
  void offMessageFailed(MessageFailedCallback callback) {
    _failedCallbacks.remove(callback);
  }

  /// Subscribe to resend progress events
  void onResendProgress(ResendProgressCallback callback) {
    _resendProgressCallbacks.add(callback);
  }

  /// Unsubscribe from resend progress events
  void offResendProgress(ResendProgressCallback callback) {
    _resendProgressCallbacks.remove(callback);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    _queueCleanupTimer?.cancel();
    _stateSubscription?.cancel();
    _eventSubscription?.cancel();

    _pendingQueue.clear();
    _unconfirmedMessages.clear();

    _sentCallbacks.clear();
    _failedCallbacks.clear();
    _resendProgressCallbacks.clear();

    _logger.i('ReconnectHandler disposed');
  }
}