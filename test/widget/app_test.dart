import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawchat/app.dart';
import 'package:clawchat/src/features/settings/settings_controller.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: const ClawChatApp(),
      ),
    );
    
    // Wait for the app to settle
    await tester.pumpAndSettle();
    
    // Verify the app renders MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

/// Mock settings notifier for testing
class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    return const SettingsState();
  }
}