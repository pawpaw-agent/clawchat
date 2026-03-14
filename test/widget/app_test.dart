import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ClawChatApp());
    
    // Verify app title appears
    expect(find.text('ClawChat'), findsOneWidget);
  });
}