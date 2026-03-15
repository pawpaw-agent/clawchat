/// Gateway API Service
/// Provides high-level API methods for ClawChat features
library;

import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

import 'gateway_client.dart';
import 'gateway_protocol.dart';
import '../models/message.dart';
import '../models/session.dart';
import '../models/node.dart';

/// API response wrapper
class ApiResponse<T> {
  final T? data;
  final GatewayError? error;
  final bool success;

  ApiResponse.success(this.data)
      : error = null,
        success = true;

  ApiResponse.failure(this.error)
      : data = null,
        success = false;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    if (json['ok'] == true && json['payload'] != null) {
      return ApiResponse.success(fromJsonT(json['payload'] as Map<String, dynamic>));
    } else if (json['error'] != null) {
      return ApiResponse.failure(GatewayError.fromJson(json['error'] as Map<String, dynamic>));
    }
    return ApiResponse.failure(GatewayError(
      code: 'UNKNOWN_RESPONSE',
      message: 'Unknown response format',
    ));
  }
}

/// Pairing response from Gateway
class PairingResponse {
  final String pairingCode;
  final String? deviceToken;
  final int? expiresIn;

  PairingResponse({
    required this.pairingCode,
    this.deviceToken,
    this.expiresIn,
  });

  factory PairingResponse.fromJson(Map<String, dynamic> json) {
    return PairingResponse(
      pairingCode: json['pairingCode'] as String? ?? '',
      deviceToken: json['deviceToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
    );
  }
}

/// Message send response
class MessageSendResponse {
  final String messageId;
  final String? runId;
  final bool queued;

  MessageSendResponse({
    required this.messageId,
    this.runId,
    this.queued = false,
  });

  factory MessageSendResponse.fromJson(Map<String, dynamic> json) {
    return MessageSendResponse(
      messageId: json['messageId'] as String? ?? '',
      runId: json['runId'] as String?,
      queued: json['queued'] as bool? ?? false,
    );
  }
}

/// Gateway API Service
/// Wraps GatewayClient to provide high-level API methods
class GatewayApiService {
  final GatewayClient _client;
  final Uuid _uuid;
  final Logger _logger;

  GatewayApiService({
    required GatewayClient client,
    Uuid? uuid,
    Logger? logger,
  })  : _client = client,
        _uuid = uuid ?? const Uuid(),
        _logger = logger ?? Logger(printer: PrettyPrinter());

  /// Check if connected
  bool get isConnected => _client.isConnected;

  /// Get event stream
  Stream<EventFrame> get eventStream => _client.eventStream;

  // =========================================================================
  // Device Pairing
  // =========================================================================

  /// Request device pairing
  /// Returns pairing code and optional device token
  Future<ApiResponse<PairingResponse>> requestPairing({
    String? displayName,
    String platform = 'android',
    List<String>? caps,
    List<String>? commands,
  }) async {
    try {
      final response = await _client.request(
        method: 'node.pair.request',
        params: {
          'nodeId': _uuid.v4(),
          if (displayName != null) 'displayName': displayName,
          'platform': platform,
          if (caps != null) 'caps': caps,
          if (commands != null) 'commands': commands,
        },
      );

      if (response.ok && response.payload != null) {
        return ApiResponse.success(PairingResponse.fromJson(response.payload!));
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'PAIRING_FAILED',
          message: 'Pairing request failed',
        ));
      }
    } catch (e) {
      _logger.e('Pairing request failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'PAIRING_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Approve device pairing
  Future<ApiResponse<bool>> approvePairing({
    required String requestId,
  }) async {
    try {
      final response = await _client.sendRequest(
        method: 'node.pair.approve',
        params: {'requestId': requestId},
      );

      return ApiResponse.success(response.ok);
    } catch (e) {
      _logger.e('Pairing approval failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'PAIRING_APPROVAL_ERROR',
        message: e.toString(),
      ));
    }
  }

  // =========================================================================
  // Chat / Messages
  // =========================================================================

  /// Send a chat message
  Future<ApiResponse<MessageSendResponse>> sendMessage({
    required String sessionKey,
    required String message,
    String? channel,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.request(
        method: 'chat.send',
        params: {
          'sessionKey': sessionKey,
          'message': message,
          'idempotencyKey': idempotencyKey ?? _uuid.v4(),
          if (channel != null) 'channel': channel,
        },
      );

      if (response.ok && response.payload != null) {
        return ApiResponse.success(MessageSendResponse.fromJson(response.payload!));
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'SEND_FAILED',
          message: 'Failed to send message',
        ));
      }
    } catch (e) {
      _logger.e('Send message failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'SEND_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Execute an agent turn
  Future<ApiResponse<MessageSendResponse>> agentTurn({
    required String message,
    String? sessionKey,
    String? agentId,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.request(
        method: 'agent.turn',
        params: {
          'message': message,
          'idempotencyKey': idempotencyKey ?? _uuid.v4(),
          if (sessionKey != null) 'sessionKey': sessionKey,
          if (agentId != null) 'agentId': agentId,
        },
      );

      if (response.ok && response.payload != null) {
        return ApiResponse.success(MessageSendResponse.fromJson(response.payload!));
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'AGENT_TURN_FAILED',
          message: 'Agent turn failed',
        ));
      }
    } catch (e) {
      _logger.e('Agent turn failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'AGENT_TURN_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Subscribe to chat updates
  Future<ApiResponse<bool>> subscribeToChat({
    String? sessionKey,
  }) async {
    try {
      final response = await _client.request(
        method: 'chat.subscribe',
        params: {
          if (sessionKey != null) 'sessionKey': sessionKey,
        },
      );

      return ApiResponse.success(response.ok);
    } catch (e) {
      _logger.e('Chat subscribe failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'SUBSCRIBE_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Get chat history
  Future<ApiResponse<List<Message>>> getChatHistory({
    String? sessionKey,
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await _client.request(
        method: 'chat.history',
        params: {
          if (sessionKey != null) 'sessionKey': sessionKey,
          'limit': limit,
          if (before != null) 'before': before,
        },
      );

      if (response.ok && response.payload != null) {
        final messages = (response.payload!['messages'] as List?)
                ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiResponse.success(messages);
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'HISTORY_FAILED',
          message: 'Failed to get history',
        ));
      }
    } catch (e) {
      _logger.e('Get history failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'HISTORY_ERROR',
        message: e.toString(),
      ));
    }
  }

  // =========================================================================
  // Sessions
  // =========================================================================

  /// List sessions
  Future<ApiResponse<List<Session>>> listSessions({
    int limit = 50,
    int? activeMinutes,
  }) async {
    try {
      final response = await _client.request(
        method: 'sessions.list',
        params: {
          'limit': limit,
          if (activeMinutes != null) 'activeMinutes': activeMinutes,
        },
      );

      if (response.ok && response.payload != null) {
        final sessions = (response.payload!['sessions'] as List?)
                ?.map((s) => Session.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiResponse.success(sessions);
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'SESSIONS_FAILED',
          message: 'Failed to list sessions',
        ));
      }
    } catch (e) {
      _logger.e('List sessions failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'SESSIONS_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Delete session
  Future<ApiResponse<bool>> deleteSession({
    required String key,
    bool deleteTranscript = true,
  }) async {
    try {
      final response = await _client.request(
        method: 'sessions.delete',
        params: {
          'key': key,
          'deleteTranscript': deleteTranscript,
        },
      );

      return ApiResponse.success(response.ok);
    } catch (e) {
      _logger.e('Delete session failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'DELETE_SESSION_ERROR',
        message: e.toString(),
      ));
    }
  }

  // =========================================================================
  // Nodes
  // =========================================================================

  /// List available nodes
  Future<ApiResponse<List<Node>>> listNodes() async {
    try {
      final response = await _client.request(
        method: 'node.list',
        params: {},
      );

      if (response.ok && response.payload != null) {
        final nodes = (response.payload!['nodes'] as List?)
                ?.map((n) => Node.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiResponse.success(nodes);
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'NODES_FAILED',
          message: 'Failed to list nodes',
        ));
      }
    } catch (e) {
      _logger.e('List nodes failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'NODES_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Describe a node
  Future<ApiResponse<Node>> describeNode({
    required String nodeId,
  }) async {
    try {
      final response = await _client.request(
        method: 'node.describe',
        params: {'nodeId': nodeId},
      );

      if (response.ok && response.payload != null) {
        return ApiResponse.success(Node.fromJson(response.payload!));
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'DESCRIBE_FAILED',
          message: 'Failed to describe node',
        ));
      }
    } catch (e) {
      _logger.e('Describe node failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'DESCRIBE_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Invoke a node command
  Future<ApiResponse<NodeInvokeResult>> invokeNode({
    required String nodeId,
    required String command,
    Map<String, dynamic>? params,
    int? timeoutMs,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.request(
        method: 'node.invoke',
        params: {
          'nodeId': nodeId,
          'command': command,
          'idempotencyKey': idempotencyKey ?? _uuid.v4(),
          if (params != null) 'params': params,
          if (timeoutMs != null) 'timeoutMs': timeoutMs,
        },
      );

      if (response.ok && response.payload != null) {
        return ApiResponse.success(NodeInvokeResult.fromJson(response.payload!));
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'INVOKE_FAILED',
          message: 'Failed to invoke node',
        ));
      }
    } catch (e) {
      _logger.e('Invoke node failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'INVOKE_ERROR',
        message: e.toString(),
      ));
    }
  }

  // =========================================================================
  // Approvals
  // =========================================================================

  /// Resolve an approval request
  Future<ApiResponse<bool>> resolveApproval({
    required String id,
    required String decision,
  }) async {
    try {
      final response = await _client.request(
        method: 'exec.approval.resolve',
        params: {
          'id': id,
          'decision': decision,
        },
      );

      return ApiResponse.success(response.ok);
    } catch (e) {
      _logger.e('Resolve approval failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'APPROVAL_ERROR',
        message: e.toString(),
      ));
    }
  }

  /// Get approval configuration
  Future<ApiResponse<Map<String, dynamic>>> getApprovalConfig() async {
    try {
      final response = await _client.request(
        method: 'exec.approvals.get',
        params: {},
      );

      if (response.ok && response.payload != null) {
        return ApiResponse.success(response.payload!);
      } else {
        return ApiResponse.failure(response.error ?? GatewayError(
          code: 'APPROVAL_CONFIG_FAILED',
          message: 'Failed to get approval config',
        ));
      }
    } catch (e) {
      _logger.e('Get approval config failed', error: e);
      return ApiResponse.failure(GatewayError(
        code: 'APPROVAL_CONFIG_ERROR',
        message: e.toString(),
      ));
    }
  }
}