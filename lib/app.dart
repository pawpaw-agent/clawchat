import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/features/settings/settings_controller.dart';
import 'src/features/onboarding/onboarding_screen.dart';
import 'src/features/onboarding/gateway_config_screen.dart';
import 'src/features/onboarding/app_bootstrap.dart';
import 'src/shared/widgets/main_shell.dart';

class ClawChatApp extends ConsumerWidget {
  const ClawChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bootstrapState = ref.watch(appBootstrapProvider);

    return MaterialApp(
      title: 'ClawChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: _buildHome(bootstrapState, ref),
    );
  }

  Widget _buildHome(BootstrapState state, WidgetRef ref) {
    switch (state) {
      case BootstrapState.needsOnboarding:
        return const OnboardingScreen();
      case BootstrapState.needsPairing:
        // Gateway is configured but not paired - go to gateway config
        final settings = ref.read(settingsProvider);
        return GatewayConfigScreen(
          initialUrl: settings.gatewayUrl ?? '',
        );
      case BootstrapState.ready:
        return const MainShell();
    }
  }
}