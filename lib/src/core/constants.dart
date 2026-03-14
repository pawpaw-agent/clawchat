/// Constants
library;

class AppConstants {
  // App info
  static const String appName = 'ClawChat';
  static const String appVersion = '0.1.0';
  
  // Gateway defaults
  static const String defaultGatewayUrl = 'ws://localhost:18789';
  static const int defaultProtocolVersion = 3;
  static const Duration defaultTickInterval = Duration(seconds: 15);
  
  // Connection
  static const int maxReconnectAttempts = 10;
  static const Duration baseReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);
  static const Duration heartbeatTimeout = Duration(seconds: 60);
  
  // Timeouts
  static const Duration defaultRequestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Cache
  static const Duration cacheExpiry = Duration(minutes: 30);
  static const int maxCachedSessions = 100;
  static const int maxCachedMessages = 1000;
}