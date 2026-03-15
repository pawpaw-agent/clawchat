/// Application exception types
/// Unified exception hierarchy for ClawChat
library;

/// Base exception type for all app exceptions
abstract class AppException implements Exception {
  /// User-friendly message to display
  String get userMessage;

  /// Technical message for logging
  String get technicalMessage;

  /// Whether this error is recoverable (e.g., network error can retry)
  bool get isRecoverable => false;

  /// Suggested action for the user
  String? get suggestedAction => null;

  /// Error code for server errors
  String? get errorCode => null;

  @override
  String toString() => technicalMessage;
}

/// Network-related exceptions
class NetworkException extends AppException {
  final NetworkErrorType type;
  final String? details;
  final int? statusCode;

  NetworkException({
    required this.type,
    this.details,
    this.statusCode,
  });

  @override
  String get userMessage => switch (type) {
        NetworkErrorType.noConnection =>
          '网络连接不可用，请检查网络设置',
        NetworkErrorType.timeout => '请求超时，请稍后重试',
        NetworkErrorType.connectionFailed => '无法连接到服务器',
        NetworkErrorType.sslError => '安全连接失败',
        NetworkErrorType.unknown => '网络请求失败',
      };

  @override
  String get technicalMessage =>
      'NetworkException: $type${details != null ? ' - $details' : ''}';

  @override
  bool get isRecoverable => true;

  @override
  String? get suggestedAction => '点击重试';

  @override
  String? get errorCode => statusCode?.toString();
}

enum NetworkErrorType {
  noConnection,
  timeout,
  connectionFailed,
  sslError,
  unknown,
}

/// Server-related exceptions
class ServerException extends AppException {
  final ServerErrorType type;
  final String? code;
  final String? details;
  final int? statusCode;

  ServerException({
    required this.type,
    this.code,
    this.details,
    this.statusCode,
  });

  @override
  String get userMessage => switch (type) {
        ServerErrorType.internal => '服务器内部错误，请稍后重试',
        ServerErrorType.unavailable => '服务暂时不可用',
        ServerErrorType.rateLimited => '请求过于频繁，请稍后再试',
        ServerErrorType.badGateway => '网关错误',
        ServerErrorType.serviceTimeout => '服务响应超时',
        ServerErrorType.unknown => '服务器错误',
      };

  @override
  String get technicalMessage =>
      'ServerException: $type${code != null ? ' (code: $code)' : ''}${details != null ? ' - $details' : ''}';

  @override
  bool get isRecoverable => type != ServerErrorType.internal;

  @override
  String? get suggestedAction => switch (type) {
        ServerErrorType.rateLimited => '等待几分钟后重试',
        ServerErrorType.unavailable => '稍后重试或联系客服',
        _ => '点击重试',
      };

  @override
  String? get errorCode => code ?? statusCode?.toString();
}

enum ServerErrorType {
  internal,
  unavailable,
  rateLimited,
  badGateway,
  serviceTimeout,
  unknown,
}

/// Authentication-related exceptions
class AuthException extends AppException {
  final AuthErrorType type;
  final String? details;

  AuthException({
    required this.type,
    this.details,
  });

  @override
  String get userMessage => switch (type) {
        AuthErrorType.notPaired => '设备未配对',
        AuthErrorType.pairingExpired => '配对已过期，请重新配对',
        AuthErrorType.invalidToken => '认证信息无效',
        AuthErrorType.sessionExpired => '会话已过期',
        AuthErrorType.deviceRevoked => '设备已被注销',
        AuthErrorType.unauthorized => '未授权访问',
      };

  @override
  String get technicalMessage =>
      'AuthException: $type${details != null ? ' - $details' : ''}';

  @override
  bool get isRecoverable => type == AuthErrorType.sessionExpired;

  @override
  String? get suggestedAction => switch (type) {
        AuthErrorType.notPaired => '前往配对新设备',
        AuthErrorType.pairingExpired => '重新扫描配对码',
        AuthErrorType.invalidToken => '重新配对设备',
        AuthErrorType.sessionExpired => '重新连接',
        AuthErrorType.deviceRevoked => '重新配对设备',
        AuthErrorType.unauthorized => '重新配对设备',
      };

  @override
  String? get errorCode => type.name;
}

enum AuthErrorType {
  notPaired,
  pairingExpired,
  invalidToken,
  sessionExpired,
  deviceRevoked,
  unauthorized,
}

/// WebSocket-related exceptions
class WebSocketException extends AppException {
  final WebSocketErrorType type;
  final String? details;
  final int? closeCode;

  WebSocketException({
    required this.type,
    this.details,
    this.closeCode,
  });

  @override
  String get userMessage => switch (type) {
        WebSocketErrorType.connectionLost => '连接已断开',
        WebSocketErrorType.handshakeFailed => '握手失败',
        WebSocketErrorType.protocolError => '协议错误',
        WebSocketErrorType.heartbeatTimeout => '心跳超时，连接断开',
        WebSocketErrorType.forcedDisconnect => '连接被强制关闭',
        WebSocketErrorType.unknown => 'WebSocket错误',
      };

  @override
  String get technicalMessage =>
      'WebSocketException: $type${closeCode != null ? ' (code: $closeCode)' : ''}${details != null ? ' - $details' : ''}';

  @override
  bool get isRecoverable => type != WebSocketErrorType.forcedDisconnect;

  @override
  String? get suggestedAction => '点击重新连接';

  @override
  String? get errorCode => closeCode?.toString();
}

enum WebSocketErrorType {
  connectionLost,
  handshakeFailed,
  protocolError,
  heartbeatTimeout,
  forcedDisconnect,
  unknown,
}

/// Gateway-related exceptions
class GatewayException extends AppException {
  final String reason;
  final String? code;

  GatewayException(this.reason, {this.code});

  @override
  String get userMessage => '网关错误: $reason';

  @override
  String get technicalMessage => 'GatewayException: $reason${code != null ? ' (code: $code)' : ''}';

  @override
  bool get isRecoverable => true;

  @override
  String? get suggestedAction => '重试';
}

/// Storage-related exceptions
class StorageException extends AppException {
  final StorageErrorType type;
  final String? details;

  StorageException({
    required this.type,
    this.details,
  });

  @override
  String get userMessage => switch (type) {
        StorageErrorType.readFailed => '数据读取失败',
        StorageErrorType.writeFailed => '数据保存失败',
        StorageErrorType.deleteFailed => '数据删除失败',
        StorageErrorType.corruptedData => '数据已损坏',
        StorageErrorType.insufficientSpace => '存储空间不足',
        StorageErrorType.unknown => '存储错误',
      };

  @override
  String get technicalMessage =>
      'StorageException: $type${details != null ? ' - $details' : ''}';

  @override
  bool get isRecoverable => type != StorageErrorType.corruptedData;

  @override
  String? get suggestedAction => type == StorageErrorType.insufficientSpace
      ? '清理设备存储空间'
      : null;

  @override
  String? get errorCode => type.name;
}

enum StorageErrorType {
  readFailed,
  writeFailed,
  deleteFailed,
  corruptedData,
  insufficientSpace,
  unknown,
}

/// Validation exceptions
class ValidationException extends AppException {
  final String field;
  final String reason;

  ValidationException({
    required this.field,
    required this.reason,
  });

  @override
  String get userMessage => '$field: $reason';

  @override
  String get technicalMessage =>
      'ValidationException: $field - $reason';

  @override
  bool get isRecoverable => true;

  @override
  String? get suggestedAction => '请修改后重试';
}

/// Generic app exception for unexpected errors
class GenericAppException extends AppException {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  GenericAppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String get userMessage => '操作失败，请稍后重试';

  @override
  String get technicalMessage =>
      'GenericAppException: $message${code != null ? ' (code: $code)' : ''}';

  @override
  bool get isRecoverable => true;

  @override
  String? get suggestedAction => '重试';

  @override
  String? get errorCode => code;
}

/// Exception classification helper
class ExceptionClassifier {
  /// Classify a generic exception into AppException
  static AppException classify(Object error) {
    // Already classified
    if (error is AppException) return error;

    // Gateway exception
    if (error.toString().contains('GatewayException')) {
      final msg = error.toString();
      if (msg.contains('Timeout') || msg.contains('timeout')) {
        return NetworkException(type: NetworkErrorType.timeout);
      }
      if (msg.contains('auth') || msg.contains('Auth')) {
        return AuthException(type: AuthErrorType.unauthorized);
      }
      return WebSocketException(type: WebSocketErrorType.unknown);
    }

    // Auth exception
    if (error.toString().contains('AuthException')) {
      return AuthException(type: AuthErrorType.unauthorized);
    }

    // Common Flutter/Dart exceptions
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('socket exception')) {
      return NetworkException(
        type: NetworkErrorType.connectionFailed,
        details: error.toString(),
      );
    }

    if (errorString.contains('timeoutexception') ||
        errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return NetworkException(type: NetworkErrorType.timeout);
    }

    if (errorString.contains('handshake') || errorString.contains('ssl')) {
      return NetworkException(type: NetworkErrorType.sslError);
    }

    if (errorString.contains('formatexception') ||
        errorString.contains('type error')) {
      return ServerException(
        type: ServerErrorType.unknown,
        details: error.toString(),
      );
    }

    // Default to generic
    return GenericAppException(
      message: error.toString(),
      originalError: error,
    );
  }
}