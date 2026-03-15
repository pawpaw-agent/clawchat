/// Application settings storage
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Theme mode enum for type-safe theme settings
enum AppThemeMode {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  /// Convert to Flutter ThemeMode
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Convert from Flutter ThemeMode
  static AppThemeMode fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppThemeMode.system;
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
    }
  }
}

/// Language code constants
class AppLanguage {
  static const String systemDefault = 'system';
  static const String english = 'en';
  static const String chinese = 'zh';
  static const String chineseSimplified = 'zh_CN';
  static const String chineseTraditional = 'zh_TW';

  static const List<String> supportedLanguages = [
    systemDefault,
    english,
    chineseSimplified,
    chineseTraditional,
  ];

  static String getDisplayName(String code) {
    switch (code) {
      case systemDefault:
        return 'System Default';
      case english:
        return 'English';
      case chineseSimplified:
        return '简体中文';
      case chineseTraditional:
        return '繁體中文';
      default:
        return code;
    }
  }
}

/// Application settings service
class AppSettings {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyGatewayUrl = 'gateway_url';
  static const String _keyDeviceToken = 'device_token';
  static const String _keyDevicePublicKey = 'device_public_key';

  SharedPreferences? _prefs;

  /// Initialize settings service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('AppSettings not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== Theme Settings ====================

  /// Get current theme mode
  AppThemeMode getThemeMode() {
    final value = _preferences.getString(_keyThemeMode);
    if (value == null) return AppThemeMode.system;
    
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Set theme mode
  Future<bool> setThemeMode(AppThemeMode mode) async {
    return _preferences.setString(_keyThemeMode, mode.name);
  }

  // ==================== Language Settings ====================

  /// Get current language code
  String getLanguage() {
    return _preferences.getString(_keyLanguage) ?? AppLanguage.systemDefault;
  }

  /// Set language code
  Future<bool> setLanguage(String languageCode) async {
    return _preferences.setString(_keyLanguage, languageCode);
  }

  // ==================== Gateway Settings ====================

  /// Get gateway URL (stored in SharedPreferences for quick access,
  /// also synced with SecureStorage for sensitive operations)
  String? getGatewayUrl() {
    return _preferences.getString(_keyGatewayUrl);
  }

  /// Set gateway URL
  Future<bool> setGatewayUrl(String url) async {
    return _preferences.setString(_keyGatewayUrl, url);
  }

  /// Clear gateway URL
  Future<bool> clearGatewayUrl() async {
    return _preferences.remove(_keyGatewayUrl);
  }

  // ==================== Device Auth Info ====================

  /// Get device token (stored here for display, SecureStorage for actual use)
  String? getDeviceToken() {
    return _preferences.getString(_keyDeviceToken);
  }

  /// Set device token (for display purposes)
  Future<bool> setDeviceToken(String token) async {
    return _preferences.setString(_keyDeviceToken, token);
  }

  /// Get device public key (for display purposes)
  String? getDevicePublicKey() {
    return _preferences.getString(_keyDevicePublicKey);
  }

  /// Set device public key (for display purposes)
  Future<bool> setDevicePublicKey(String publicKey) async {
    return _preferences.setString(_keyDevicePublicKey, publicKey);
  }

  /// Check if device is authenticated
  bool isAuthenticated() {
    return getDeviceToken() != null && getDeviceToken()!.isNotEmpty;
  }

  /// Clear device auth info
  Future<void> clearAuthInfo() async {
    await _preferences.remove(_keyDeviceToken);
    await _preferences.remove(_keyDevicePublicKey);
  }

  // ==================== Clear All Settings ====================

  /// Clear all settings (for logout/factory reset)
  Future<void> clearAll() async {
    await _preferences.clear();
  }

  // ==================== Export Settings ====================

  /// Export all settings as a map (for debugging/backup)
  Map<String, dynamic> exportSettings() {
    return {
      'themeMode': getThemeMode().name,
      'language': getLanguage(),
      'gatewayUrl': getGatewayUrl(),
      'hasDeviceToken': getDeviceToken() != null,
      'hasDevicePublicKey': getDevicePublicKey() != null,
    };
  }
}