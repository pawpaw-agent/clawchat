/// Gateway WebSocket Client
/// Main client for communicating with OpenClaw Gateway
library;

import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

import 'gateway_protocol.dart';
import 'auth_service.dart';
import '../errors/app_exception.dart';

/// Callback for connection state changes
typedef ConnectionStateCallback = void Function(ConnectionState state);

/// Main WebSocket client for OpenClaw Gateway
class GatewayClient {
  final String gatewayUrl;
  final AuthService authService;
  final Uuid _uuid;
  final Logger _logger;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final Map<String, Completer<ResponseFrame>> _pendingRequests = {};
  final StreamController<EventFrame> _eventController = StreamController.broadcast();
  
  ConnectionState _state = GatewayConnectionState.disconnected;
  final List<ConnectionStateCallback> _stateCallbacks = [];
  
  String? _challengeNonce;
  int _protocol = 3;
  // ignore: unused_field
  PolicyConfig? _policy;
  String? _deviceToken;

  GatewayClient({
    required this.gatewayUrl,
    required this.authService,
    Uuid? uuid,
    Logger? logger,
  })  : _uuid = uuid ?? const Uuid(),
        _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Current connection state
  ConnectionState get state => _state;

  /// Stream of events from gateway
  Stream<EventFrame> get eventStream => _eventController.stream;

  /// Whether client is connected
  bool get isConnected => _state == GatewayConnectionState.connected;

  /// Whether client is authenticated
  bool get isAuthenticated => _state == GatewayConnectionState.authenticated;

  /// Subscribe to connection state changes
  void onStateChange(ConnectionStateCallback callback) {
    _stateCallbacks.add(callback);
  }

  /// Unsubscribe from connection state changes
  void offStateChange(ConnectionStateCallback callback) {
    _stateCallbacks.remove(callback);
  }

  /// Connect to gateway
  Future<void> connect() async {
    if (_state != GatewayConnectionState.disconnected) {
      throw WebSocketException(
        type: WebSocketErrorType.protocolError,
        details: 'Already connecting or connected',
      );
    }

    _setState(GatewayConnectionState.connecting);
    _logger.i('Connecting to gateway: $gatewayUrl');

    try {
      final uri = Uri.parse(gatewayUrl);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _setState(GatewayConnectionState.connected);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // Wait for challenge
      await _waitForChallenge();
    } on WebSocketException {
      _setState(GatewayConnectionState.error);
      rethrow;
    } on NetworkException {
      _setState(GatewayConnectionState.error);
      rethrow;
    } catch (e) {
      _setState(GatewayConnectionState.error);
      _logger.e('Connection failed', error: e);
      throw WebSocketException(
        type: WebSocketErrorType.connectionLost,
        details: e.toString(),
      );
    }
  }

  /// Wait for connect.challenge event
  Future<void> _waitForChallenge() async {
    final completer = Completer<void>();
    
    StreamSubscription? sub;
    sub = eventStream.listen((event) {
      if (event.event == EventType.connectChallenge.value) {
        final payload = ChallengePayload.fromJson(event.payload);
        _challengeNonce = payload.nonce;
        _logger.d('Received challenge: ${payload.nonce}');
        completer.complete();
      }
    });

    // Timeout after 10 seconds
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub?.cancel();
        throw WebSocketException(
          type: WebSocketErrorType.handshakeFailed,
          details: 'Timeout waiting for challenge',
        );
      },
    );
    
    sub.cancel();
  }

  /// Complete handshake with device authentication
  Future<ConnectResponse> completeHandshake({
    required String version,
    String? token,
    String locale = 'zh-CN',
  }) async {
    if (_challengeNonce == null) {
      throw WebSocketException(
        type: WebSocketErrorType.handshakeFailed,
        details: 'No challenge received. Call connect() first.',
      );
    }

    _logger.i('Completing handshake...');

    // Build auth payload
    Map<String, dynamic>? auth;
    DeviceAuth? deviceAuth;

    // Try device token first
    final storedToken = await authService.deviceToken;
    if (token != null || storedToken != null) {
      auth = {'token': token ?? storedToken};
    } else {
      // Create device auth
      try {
        deviceAuth = await authService.createDeviceAuth(_challengeNonce!);
      } catch (e) {
        _logger.w('Failed to create device auth: $e');
        // Continue without device auth
      }
    }

    // Prepare connect params
    final params = ConnectParams(
      client: ClientInfo(version: version),
      auth: auth,
      device: deviceAuth,
      locale: locale,
      userAgent: 'openclaw-android/$version',
    );

    // Send connect request
    final response = await sendRequest('connect', params.toJson());

    if (!response.ok) {
      _setState(GatewayConnectionState.error);
      final error = response.error;
      if (error != null) {
        // Check for auth-related errors
        final code = error.code?.toString() ?? '';
        if (code.contains('auth') || code.contains('token') || code.contains('unauthorized')) {
          throw AuthException(
            type: AuthErrorType.invalidToken,
            details: error.message,
          );
        }
        throw ServerException(
          type: ServerErrorType.unknown,
          code: error.code?.toString(),
          details: error.message,
        );
      }
      throw WebSocketException(
        type: WebSocketErrorType.handshakeFailed,
        details: 'Handshake failed',
      );
    }

    // Parse connect response
    final connectResponse = ConnectResponse.fromJson(response.payload ?? {});
    _protocol = connectResponse.protocol;
    _policy = connectResponse.policy;
    
    if (connectResponse.auth?.deviceToken != null) {
      _deviceToken = connectResponse.auth!.deviceToken;
      await authService.storeDeviceToken(_deviceToken!);
    }

    _setState(GatewayConnectionState.authenticated);
    _logger.i('Handshake complete. Protocol: $_protocol');

    return connectResponse;
  }

  /// Send a request and wait for response
  Future<ResponseFrame> sendRequest(
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final id = _uuid.v4();
    final frame = RequestFrame(
      id: id,
      method: method,
      params: params,
    );

    final completer = Completer<ResponseFrame>();
    _pendingRequests[id] = completer;

    _sendFrame(frame);
    _logger.d('Sent request: $method (id: $id)');

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pendingRequests.remove(id);
        throw NetworkException(
          type: NetworkErrorType.timeout,
          details: 'Request timeout: $method',
        );
      },
    );
  }

  /// Send a request without waiting for response
  void sendRequestNoWait(String method, Map<String, dynamic> params) {
    final id = _uuid.v4();
    final frame = RequestFrame(
      id: id,
      method: method,
      params: params,
    );
    _sendFrame(frame);
  }

  /// Disconnect from gateway
  Future<void> disconnect() async {
    _logger.i('Disconnecting...');
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close();
    _channel = null;

    // Complete all pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(WebSocketException(
          type: WebSocketErrorType.connectionLost,
          details: 'Disconnected',
        ));
      }
    }
    _pendingRequests.clear();

    _challengeNonce = null;
    _setState(GatewayConnectionState.disconnected);
  }

  // ===========================================================================
  // Internal Methods
  // ===========================================================================

  void _sendFrame(RequestFrame frame) {
    if (_channel == null) {
      throw WebSocketException(
        type: WebSocketErrorType.connectionLost,
        details: 'Not connected',
      );
    }
    
    _channel!.sink.add(jsonEncode(frame.toJson()));
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String;

      switch (type) {
        case 'res':
          _handleResponse(ResponseFrame.fromJson(json));
        case 'event':
          _handleEvent(EventFrame.fromJson(json));
        default:
          _logger.w('Unknown frame type: $type');
      }
    } catch (e, stack) {
      _logger.e('Failed to parse message', error: e, stackTrace: stack);
    }
  }

  void _handleResponse(ResponseFrame response) {
    final completer = _pendingRequests.remove(response.id);
    if (completer == null) {
      _logger.w('Received response for unknown request: ${response.id}');
      return;
    }

    if (!completer.isCompleted) {
      completer.complete(response);
    }
  }

  void _handleEvent(EventFrame event) {
    _logger.d('Received event: ${event.event}');
    _eventController.add(event);
  }

  void _handleError(dynamic error) {
    _logger.e('WebSocket error', error: error);
    _setState(GatewayConnectionState.error);
  }

  void _handleDone() {
    _logger.i('WebSocket closed');
    _setState(GatewayConnectionState.disconnected);
  }

  void _setState(ConnectionState state) {
    _state = state;
    for (final callback in _stateCallbacks) {
      callback(state);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
  }
}

/// Connection states
enum GatewayConnectionState {
  disconnected,
  connecting,
  connected,
  authenticated,
  error,
}