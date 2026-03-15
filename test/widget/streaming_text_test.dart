/// Tests for StreamingText widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/src/shared/widgets/streaming_text.dart';

void main() {
  group('StreamingText', () {
    testWidgets('displays initial text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Hello World',
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('shows cursor when streaming', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Hello',
              isStreaming: true,
              cursorChar: '▌',
            ),
          ),
        ),
      );

      // Should find the text plus cursor
      expect(find.textContaining('Hello'), findsOneWidget);
      expect(find.textContaining('▌'), findsOneWidget);
    });

    testWidgets('hides cursor when not streaming', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Hello',
              isStreaming: false,
              cursorChar: '▌',
            ),
          ),
        ),
      );

      // Should find only the text without cursor
      expect(find.text('Hello'), findsOneWidget);
      // Cursor should not appear in RichText children
      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);
    });

    testWidgets('applies custom style', (tester) async {
      const customStyle = TextStyle(fontSize: 24, color: Colors.red);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Styled Text',
              style: customStyle,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style, customStyle);
    });

    testWidgets('updates displayed text when widget text changes', (tester) async {
      const text1 = 'First text';
      const text2 = 'Second text with more content';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: text1,
              enableTypewriter: false,
            ),
          ),
        ),
      );

      expect(find.text(text1), findsOneWidget);

      // Update the text
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: text2,
              enableTypewriter: false,
            ),
          ),
        ),
      );

      expect(find.text(text2), findsOneWidget);
    });

    testWidgets('calls onComplete when streaming stops', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Hello',
              isStreaming: true,
              onComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );

      // Stop streaming
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Hello World',
              isStreaming: false,
              onComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(completed, true);
    });

    testWidgets('disables typewriter effect when enableTypewriter is false', (tester) async {
      const fullText = 'This is a long text that should appear immediately';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: fullText,
              isStreaming: true,
              enableTypewriter: false,
            ),
          ),
        ),
      );

      // Full text should be visible immediately (with cursor since isStreaming: true)
      expect(find.textContaining(fullText), findsOneWidget);
    });

    testWidgets('handles empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: '',
              isStreaming: true,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(StreamingText), findsOneWidget);
    });

    testWidgets('handles text reset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Long text here',
              enableTypewriter: false,
            ),
          ),
        ),
      );

      // Reset to shorter text
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingText(
              text: 'Short',
              enableTypewriter: false,
            ),
          ),
        ),
      );

      expect(find.text('Short'), findsOneWidget);
    });
  });

  group('StreamingTextFade', () {
    testWidgets('displays text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingTextFade(
              text: 'Fade text',
            ),
          ),
        ),
      );

      expect(find.text('Fade text'), findsOneWidget);
    });

    testWidgets('applies custom style', (tester) async {
      const customStyle = TextStyle(fontSize: 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingTextFade(
              text: 'Styled',
              style: customStyle,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style, customStyle);
    });
  });
}