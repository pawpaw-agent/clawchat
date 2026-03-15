/// App bootstrap controller for startup flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/settings_controller.dart';

/// Bootstrap state representing the app's initial state
enum BootstrapState {
  /// First time setup - show onboarding
  needsOnboarding,
  
  /// Gateway configured but not authenticated - show pairing
  needsPairing,
  
  /// Fully configured - show main app
  ready,
}

/// App bootstrap notifier
class AppBootstrapNotifier extends Notifier<BootstrapState> {
  @override
  BootstrapState build() {
    _checkState();
    return BootstrapState.needsOnboarding; // Default while checking
  }

  void _checkState() {
    final settings = ref.watch(settingsProvider);
    
    // Check if gateway URL is configured
    if (settings.gatewayUrl == null || settings.gatewayUrl!.isEmpty) {
      state = BootstrapState.needsOnboarding;
      return;
    }
    
    // Check if device is authenticated
    if (settings.deviceToken == null || settings.deviceToken!.isEmpty) {
      state = BootstrapState.needsPairing;
      return;
    }
    
    // Fully configured
    state = BootstrapState.ready;
  }

  /// Refresh bootstrap state after configuration changes
  void refresh() {
    _checkState();
  }
}

/// Provider for app bootstrap state
final appBootstrapProvider = NotifierProvider<AppBootstrapNotifier, BootstrapState>(() {
  return AppBootstrapNotifier();
});

/// Provider to check if app is ready (gateway configured and authenticated)
final isAppReadyProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.gatewayUrl != null && 
         settings.gatewayUrl!.isNotEmpty &&
         settings.deviceToken != null && 
         settings.deviceToken!.isNotEmpty;
});

/// Provider to check if onboarding is needed
final needsOnboardingProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.gatewayUrl == null || settings.gatewayUrl!.isEmpty;
});

/// Provider to check if pairing is needed
final needsPairingProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.gatewayUrl != null && 
         settings.gatewayUrl!.isNotEmpty &&
         (settings.deviceToken == null || settings.deviceToken!.isEmpty);
});