import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:clawchat/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ClawChatApp());
    
    // Wait for the app to settle
    await tester.pumpAndSettle();
    
    // Verify the app renders without errors
    // MaterialApp is the root widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}