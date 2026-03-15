import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/features/chat/chat_screen.dart';
import 'src/features/settings/settings_controller.dart';
import 'src/features/onboarding/onboarding_screen.dart';
import 'src/features/onboarding/app_bootstrap.dart';

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
      home: _buildHome(bootstrapState),
    );
  }

  Widget _buildHome(BootstrapState state) {
    switch (state) {
      case BootstrapState.needsOnboarding:
        return const OnboardingScreen();
      case BootstrapState.needsPairing:
        // If pairing is needed, we still show onboarding to reconfigure
        return const OnboardingScreen();
      case BootstrapState.ready:
        return const ChatScreen();
    }
  }
}