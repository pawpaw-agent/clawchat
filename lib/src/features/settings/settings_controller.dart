/// Settings controller with Riverpod state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../core/storage/app_settings.dart';
import '../../core/storage/secure_storage.dart';

/// Settings state class
class SettingsState {
  final AppThemeMode themeMode;
  final String language;
  final String? gatewayUrl;
  final String? deviceToken;
  final String? devicePublicKey;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.systemDefault,
    this.gatewayUrl,
    this.deviceToken,
    this.devicePublicKey,
    this.isLoading = false,
    this.error,
  });

  /// Check if device is authenticated
  bool get isAuthenticated => deviceToken != null && deviceToken!.isNotEmpty;

  /// Get masked device token for display (show first/last 8 chars)
  String? get maskedDeviceToken {
    if (deviceToken == null || deviceToken!.length < 20) return deviceToken;
    return '${deviceToken!.substring(0, 8)}...${deviceToken!.substring(deviceToken!.length - 8)}';
  }

  /// Get masked public key for display
  String? get maskedPublicKey {
    if (devicePublicKey == null || devicePublicKey!.length < 20) {
      return devicePublicKey;
    }
    return '${devicePublicKey!.substring(0, 12)}...';
  }

  SettingsState copyWith({
    AppThemeMode? themeMode,
    String? language,
    String? gatewayUrl,
    String? deviceToken,
    String? devicePublicKey,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearGatewayUrl = false,
    bool clearDeviceToken = false,
    bool clearDevicePublicKey = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      gatewayUrl: clearGatewayUrl ? null : (gatewayUrl ?? this.gatewayUrl),
      deviceToken: clearDeviceToken ? null : (deviceToken ?? this.deviceToken),
      devicePublicKey: clearDevicePublicKey ? null : (devicePublicKey ?? this.devicePublicKey),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Settings notifier
class SettingsNotifier extends Notifier<SettingsState> {
  late AppSettings _appSettings;
  late SecureStorage _secureStorage;

  @override
  SettingsState build() {
    _appSettings = AppSettings();
    _secureStorage = SecureStorage();
    
    // Initialize and load settings
    _initSettings();
    
    return const SettingsState(isLoading: true);
  }

  /// Initialize settings from storage
  Future<void> _initSettings() async {
    try {
      await _appSettings.init();
      await _loadSettings();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  /// Load all settings from storage
  Future<void> _loadSettings() async {
    try {
      // Load from app settings (SharedPreferences)
      final themeMode = _appSettings.getThemeMode();
      final language = _appSettings.getLanguage();
      final gatewayUrl = _appSettings.getGatewayUrl();
      final deviceToken = _appSettings.getDeviceToken();
      final devicePublicKey = _appSettings.getDevicePublicKey();

      // Also load from secure storage for sensitive data
      final secureToken = await _secureStorage.getDeviceToken();
      final secureGatewayUrl = await _secureStorage.getGatewayUrl();

      state = SettingsState(
        themeMode: themeMode,
        language: language,
        gatewayUrl: secureGatewayUrl ?? gatewayUrl,
        deviceToken: secureToken ?? deviceToken,
        devicePublicKey: devicePublicKey,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      await _appSettings.setThemeMode(mode);
      state = state.copyWith(themeMode: mode);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save theme: $e');
    }
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _appSettings.setLanguage(languageCode);
      state = state.copyWith(language: languageCode);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save language: $e');
    }
  }

  /// Set gateway URL
  Future<void> setGatewayUrl(String url) async {
    try {
      // Save to both storages
      await _appSettings.setGatewayUrl(url);
      await _secureStorage.setGatewayUrl(url);
      state = state.copyWith(gatewayUrl: url);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save gateway URL: $e');
    }
  }

  /// Clear gateway URL
  Future<void> clearGatewayUrl() async {
    try {
      await _appSettings.clearGatewayUrl();
      // Note: Don't clear from secure storage as it might be needed for reconnection
      state = state.copyWith(clearGatewayUrl: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear gateway URL: $e');
    }
  }

  /// Set device token
  Future<void> setDeviceToken(String token) async {
    try {
      await _appSettings.setDeviceToken(token);
      state = state.copyWith(deviceToken: token);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save device token: $e');
    }
  }

  /// Set device public key
  Future<void> setDevicePublicKey(String publicKey) async {
    try {
      await _appSettings.setDevicePublicKey(publicKey);
      state = state.copyWith(devicePublicKey: publicKey);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save device public key: $e');
    }
  }

  /// Clear authentication info
  Future<void> clearAuthInfo() async {
    try {
      await _appSettings.clearAuthInfo();
      await _secureStorage.clearAll();
      state = state.copyWith(
        clearDeviceToken: true,
        clearDevicePublicKey: true,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear auth info: $e');
    }
  }

  /// Clear all settings (factory reset)
  Future<void> clearAllSettings() async {
    try {
      await _appSettings.clearAll();
      await _secureStorage.clearAll();
      state = const SettingsState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear settings: $e');
    }
  }

  /// Refresh settings from storage
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadSettings();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for settings controller
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// Provider for theme mode (convenient for MaterialApp)
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode.toThemeMode();
});

/// Provider for language (convenient for localization)
final languageProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.language;
});

/// Provider for checking if authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isAuthenticated;
});