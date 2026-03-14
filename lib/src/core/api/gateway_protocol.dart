/// Gateway Protocol Definitions
/// Based on OpenClaw Gateway WebSocket API
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'gateway_protocol.freezed.dart';
part 'gateway_protocol.g.dart';

// ============================================================================
// Frame Types
// ============================================================================

/// Base frame type for WebSocket communication
sealed class GatewayFrame {
  const GatewayFrame();
}

/// Request frame - sent by client to invoke methods
class RequestFrame extends GatewayFrame {
  final String type;
  final String id;
  final String method;
  final Map<String, dynamic> params;

  const RequestFrame({
    required this.id,
    required this.method,
    required this.params,
  }) : type = 'req';

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'method': method,
        'params': params,
      };
}

/// Response frame - sent by gateway in response to requests
class ResponseFrame extends GatewayFrame {
  final String type;
  final String id;
  final bool ok;
  final Map<String, dynamic>? payload;
  final GatewayError? error;

  const ResponseFrame({
    required this.id,
    required this.ok,
    this.payload,
    this.error,
  }) : type = 'res';

  factory ResponseFrame.fromJson(Map<String, dynamic> json) {
    return ResponseFrame(
      id: json['id'] as String,
      ok: json['ok'] as bool,
      payload: json['payload'] as Map<String, dynamic>?,
      error: json['error'] != null
          ? GatewayError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Event frame - sent by gateway to push events
class EventFrame extends GatewayFrame {
  final String type;
  final String event;
  final Map<String, dynamic> payload;
  final int? seq;
  final Map<String, int>? stateVersion;

  const EventFrame({
    required this.event,
    required this.payload,
    this.seq,
    this.stateVersion,
  }) : type = 'event';

  factory EventFrame.fromJson(Map<String, dynamic> json) {
    return EventFrame(
      event: json['event'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      seq: json['seq'] as int?,
      stateVersion: (json['stateVersion'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }
}

/// Gateway error structure
@freezed
class GatewayError with _$GatewayError {
  const factory GatewayError({
    required String code,
    required String message,
    Map<String, dynamic>? details,
    @Default(false) bool retryable,
  }) = _GatewayError;

  factory GatewayError.fromJson(Map<String, dynamic> json) =>
      _$GatewayErrorFromJson(json);
}

// ============================================================================
// Event Types
// ============================================================================

/// All known event types from Gateway
enum EventType {
  connectChallenge('connect.challenge'),
  tick('tick'),
  shutdown('shutdown'),
  chat('chat'),
  agentEvent('agent.event'),
  execApprovalRequested('exec.approval.requested'),
  nodePairRequested('node.pair.requested');

  final String value;
  const EventType(this.value);

  static EventType? fromString(String value) {
    for (final type in EventType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

// ============================================================================
// Client Info
// ============================================================================

/// Client identification for connect handshake
@freezed
class ClientInfo with _$ClientInfo {
  const factory ClientInfo({
    @Default('openclaw-android') String id,
    required String version,
    @Default('android') String platform,
    @Default('operator') String mode,
  }) = _ClientInfo;

  factory ClientInfo.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoFromJson(json);
}

// ============================================================================
// Device Authentication
// ============================================================================

/// Device authentication payload for connect handshake
@freezed
class DeviceAuth with _$DeviceAuth {
  const factory DeviceAuth({
    required String id,
    required String publicKey,
    required String signature,
    required int signedAt,
    required String nonce,
  }) = _DeviceAuth;

  factory DeviceAuth.fromJson(Map<String, dynamic> json) =>
      _$DeviceAuthFromJson(json);
}

// ============================================================================
// Connect Params
// ============================================================================

/// Parameters for connect method
@freezed
class ConnectParams with _$ConnectParams {
  const factory ConnectParams({
    @Default(3) int minProtocol,
    @Default(3) int maxProtocol,
    required ClientInfo client,
    @Default('operator') String role,
    @Default(['operator.read', 'operator.write']) List<String> scopes,
    @Default([]) List<String> caps,
    @Default([]) List<String> commands,
    @Default({}) Map<String, dynamic> permissions,
    Map<String, dynamic>? auth,
    String? locale,
    String? userAgent,
    DeviceAuth? device,
  }) = _ConnectParams;

  factory ConnectParams.fromJson(Map<String, dynamic> json) =>
      _$ConnectParamsFromJson(json);
}

// ============================================================================
// Connect Response
// ============================================================================

/// Response payload from successful connect
@freezed
class ConnectResponse with _$ConnectResponse {
  const factory ConnectResponse({
    @Default('hello-ok') String type,
    @Default(3) int protocol,
    PolicyConfig? policy,
    AuthResponse? auth,
  }) = _ConnectResponse;

  factory ConnectResponse.fromJson(Map<String, dynamic> json) =>
      _$ConnectResponseFromJson(json);
}

/// Policy configuration from gateway
@freezed
class PolicyConfig with _$PolicyConfig {
  const factory PolicyConfig({
    @Default(15000) int tickIntervalMs,
  }) = _PolicyConfig;

  factory PolicyConfig.fromJson(Map<String, dynamic> json) =>
      _$PolicyConfigFromJson(json);
}

/// Auth information in connect response
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    String? deviceToken,
    String? role,
    List<String>? scopes,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

// ============================================================================
// Challenge Event
// ============================================================================

/// Challenge payload from gateway
@freezed
class ChallengePayload with _$ChallengePayload {
  const factory ChallengePayload({
    required String nonce,
    required int ts,
  }) = _ChallengePayload;

  factory ChallengePayload.fromJson(Map<String, dynamic> json) =>
      _$ChallengePayloadFromJson(json);
}

// ============================================================================
// Common Error Codes
// ============================================================================

/// Device authentication error codes
enum DeviceAuthErrorCode {
  nonceRequired('DEVICE_AUTH_NONCE_REQUIRED'),
  nonceMismatch('DEVICE_AUTH_NONCE_MISMATCH'),
  signatureInvalid('DEVICE_AUTH_SIGNATURE_INVALID'),
  signatureExpired('DEVICE_AUTH_SIGNATURE_EXPIRED'),
  deviceIdMismatch('DEVICE_AUTH_DEVICE_ID_MISMATCH'),
  publicKeyInvalid('DEVICE_AUTH_PUBLIC_KEY_INVALID');

  final String code;
  const DeviceAuthErrorCode(this.code);
}