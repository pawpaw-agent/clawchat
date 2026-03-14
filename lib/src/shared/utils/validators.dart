/// Validators
library;

/// Validate WebSocket URL
bool isValidWebSocketUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme == 'ws' || uri.scheme == 'wss';
  } catch (_) {
    return false;
  }
}

/// Validate device ID format
bool isValidDeviceId(String id) {
  // UUID v4 format
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(id);
}

/// Validate session key format
bool isValidSessionKey(String key) {
  return key.isNotEmpty && key.length <= 256;
}

/// Sanitize message content
String sanitizeMessage(String content) {
  // Remove control characters
  return content.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}

/// Validate timeout value
bool isValidTimeout(int timeoutMs) {
  return timeoutMs > 0 && timeoutMs <= 300000; // Max 5 minutes
}