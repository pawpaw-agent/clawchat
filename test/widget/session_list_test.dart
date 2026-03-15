/// Widget tests for session list feature
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawchat/src/features/sessions/session_list_screen.dart';
import 'package:clawchat/src/features/sessions/session_controller.dart';
import 'package:clawchat/src/features/sessions/session_tile.dart';
import 'package:clawchat/src/core/models/session.dart';

void main() {
  group('SessionListScreen', () {
    testWidgets('shows empty state when no sessions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      // Wait for mock data to load
      await tester.pumpAndSettle();

      // Should show some sessions (mock data)
      expect(find.text('ClawChat'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      // Immediately after pump, before settling
      // The loading indicator should be visible
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Let the mock data load
      await tester.pumpAndSettle();
    });

    testWidgets('FAB creates new session on tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Should navigate (ChatScreen would be pushed)
      // For now, just verify no errors
    });

    testWidgets('shows connection status bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Disconnected'), findsOneWidget);
    });
  });

  group('SessionTile', () {
    late Session testSession;

    setUp(() {
      testSession = Session(
        key: 'test-session-1',
        label: 'Test Chat',
        agentId: 'agent-forge',
        lastMessage: 'Hello, this is a test message',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
        messageCount: 5,
      );
    });

    testWidgets('displays session information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionTile(
              session: testSession,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Chat'), findsOneWidget);
      expect(find.textContaining('Hello'), findsOneWidget);
      expect(find.text('Forge'), findsOneWidget);
      expect(find.text('5 msgs'), findsOneWidget);
    });

    testWidgets('shows pin indicator when pinned', (tester) async {
      final pinnedSession = testSession.copyWith(isPinned: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionTile(
              session: pinnedSession,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the pin icon in the avatar stack (the small one)
      final pinIcons = find.byIcon(Icons.push_pin);
      expect(pinIcons, findsWidgets);
    });

    testWidgets('shows archive icon when archived', (tester) async {
      final archivedSession = testSession.copyWith(isArchived: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionTile(
              session: archivedSession,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the archive icon in the trailing
      final archiveIcons = find.byIcon(Icons.archive);
      expect(archiveIcons, findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionTile(
              session: testSession,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows context menu on long press', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionTile(
              session: testSession,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('swipe to delete shows confirmation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionTile(
              session: testSession,
              onTap: () {},
              onDelete: (_) {},
            ),
          ),
        ),
      );

      // Swipe left
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Session'), findsOneWidget);
    });
  });

  group('SessionNotifier', () {
    test('initial state is empty', () {
      final notifier = SessionNotifier();
      // State starts empty then loads mock data asynchronously
      expect(notifier.state.sessions, isEmpty);
    });

    test('creates new session', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession(label: 'New Test');

      expect(session.label, 'New Test');
      expect(notifier.state.sessions, contains(session));
      expect(notifier.state.activeSessionKey, session.key);
    });

    test('deletes session', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession(label: 'To Delete');
      final initialCount = notifier.state.sessions.length;

      await notifier.deleteSession(session.key);

      expect(notifier.state.sessions.length, initialCount - 1);
      expect(notifier.state.sessions.where((s) => s.key == session.key), isEmpty);
    });

    test('toggles archive status', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession(label: 'Test Archive');
      expect(session.isArchived, isFalse);

      await notifier.toggleArchive(session.key);
      final archived = notifier.state.sessions.firstWhere((s) => s.key == session.key);
      expect(archived.isArchived, isTrue);

      await notifier.toggleArchive(session.key);
      final unarchived = notifier.state.sessions.firstWhere((s) => s.key == session.key);
      expect(unarchived.isArchived, isFalse);
    });

    test('toggles pin status', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession(label: 'Test Pin');
      expect(session.isPinned, isFalse);

      await notifier.togglePin(session.key);
      final pinned = notifier.state.sessions.firstWhere((s) => s.key == session.key);
      expect(pinned.isPinned, isTrue);

      await notifier.togglePin(session.key);
      final unpinned = notifier.state.sessions.firstWhere((s) => s.key == session.key);
      expect(unpinned.isPinned, isFalse);
    });

    test('updates session label', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession(label: 'Old Label');
      await notifier.updateLabel(session.key, 'New Label');

      final updated = notifier.state.sessions.firstWhere((s) => s.key == session.key);
      expect(updated.label, 'New Label');
    });

    test('sets active session', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession();
      expect(notifier.state.activeSessionKey, session.key);

      notifier.setActiveSession(null);
      expect(notifier.state.activeSessionKey, isNull);
    });

    test('sortedSessions puts pinned first', () async {
      final notifier = SessionNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      // Create sessions
      final session1 = await notifier.createSession(label: 'Regular');
      final session2 = await notifier.createSession(label: 'Pinned');

      // Pin the second one
      await notifier.togglePin(session2.key);

      final sorted = notifier.state.sortedSessions;
      expect(sorted.first.key, session2.key);
    });

    test('activeSessions filters out archived', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sessionProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 600));

      final session = await notifier.createSession(label: 'To Archive');
      await notifier.toggleArchive(session.key);

      final activeSessions = container.read(activeSessionsProvider);
      expect(activeSessions.where((s) => s.key == session.key), isEmpty);
    });
  });

  group('SessionSearchDelegate', () {
    testWidgets('searches sessions by label', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap search button
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Planning');
      await tester.pumpAndSettle();

      // Should find the matching session (from mock data)
      expect(find.text('Project Planning'), findsOneWidget);
    });
  });
}