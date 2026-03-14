/// Secure storage wrapper
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data
class SecureStorage {
  final FlutterSecureStorage _storage;

  static const _deviceTokenKey = 'device_token';
  static const _gatewayUrlKey = 'gateway_url';
  static const _userIdKey = 'user_id';

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  /// Store device token
  Future<void> setDeviceToken(String token) async {
    await _storage.write(key: _deviceTokenKey, value: token);
  }

  /// Get device token
  Future<String?> getDeviceToken() async {
    return _storage.read(key: _deviceTokenKey);
  }

  /// Delete device token
  Future<void> deleteDeviceToken() async {
    await _storage.delete(key: _deviceTokenKey);
  }

  /// Store gateway URL
  Future<void> setGatewayUrl(String url) async {
    await _storage.write(key: _gatewayUrlKey, value: url);
  }

  /// Get gateway URL
  Future<String?> getGatewayUrl() async {
    return _storage.read(key: _gatewayUrlKey);
  }

  /// Store user ID
  Future<void> setUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if has credentials
  Future<bool> hasCredentials() async {
    final token = await getDeviceToken();
    return token != null && token.isNotEmpty;
  }
}