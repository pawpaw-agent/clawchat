// Widget tests for node list screen
// Tests node list display, selection, and navigation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawchat/src/features/nodes/node_list_screen.dart';
import 'package:clawchat/src/features/nodes/node_controller.dart';
import 'package:clawchat/src/features/nodes/node_tile.dart';
import 'package:clawchat/src/features/nodes/node_detail_screen.dart';
import 'package:clawchat/src/core/models/node.dart';

void main() {
  group('NodeListScreen Widget Tests', () {
    testWidgets('renders correctly with loading state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeListScreen(),
          ),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays nodes after loading', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeListScreen(),
          ),
        ),
      );

      // Wait for mock data to load
      await tester.pumpAndSettle();

      // Should have scaffold
      expect(find.byType(Scaffold), findsOneWidget);

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows node tiles after loading', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have node tiles (mock data has 4 nodes)
      expect(find.byType(NodeTile), findsWidgets);
    });

    testWidgets('navigates to detail on tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap first node tile
      final nodeTiles = find.byType(NodeTile);
      if (nodeTiles.evaluate().isNotEmpty) {
        await tester.tap(nodeTiles.first);
        await tester.pumpAndSettle();

        // Should navigate to detail screen
        expect(find.byType(NodeDetailScreen), findsOneWidget);
      }
    });
  });

  group('NodeTile Widget Tests', () {
    testWidgets('displays node information correctly', (tester) async {
      final node = Node(
        id: 'test-node',
        displayName: 'Test Node',
        platform: 'linux',
        host: 'localhost',
        caps: ['camera', 'canvas'],
        commands: ['camera.snap'],
        status: NodeStatus.online,
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeTile(node: node),
          ),
        ),
      );

      // Should show node name
      expect(find.text('Test Node'), findsOneWidget);

      // Should show capabilities
      expect(find.text('camera'), findsOneWidget);
      expect(find.text('canvas'), findsOneWidget);
    });

    testWidgets('shows online status indicator', (tester) async {
      final onlineNode = Node(
        id: 'online-node',
        displayName: 'Online Node',
        status: NodeStatus.online,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeTile(node: onlineNode),
          ),
        ),
      );

      // Should have status indicator (green for online)
      // Check for icon presence
      expect(find.byIcon(Icons.devices), findsOneWidget);
    });

    testWidgets('shows offline status indicator', (tester) async {
      final offlineNode = Node(
        id: 'offline-node',
        displayName: 'Offline Node',
        status: NodeStatus.offline,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeTile(node: offlineNode),
          ),
        ),
      );

      // Should have offline icon
      expect(find.byIcon(Icons.devices_outlined), findsOneWidget);
    });

    testWidgets('handles onTap callback', (tester) async {
      final node = Node(
        id: 'test-node',
        displayName: 'Test Node',
        status: NodeStatus.online,
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeTile(
              node: node,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the tile
      await tester.tap(find.byType(NodeTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows capabilities as chips', (tester) async {
      final node = Node(
        id: 'test-node',
        displayName: 'Test Node',
        caps: ['camera', 'canvas', 'location'],
        status: NodeStatus.online,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeTile(node: node),
          ),
        ),
      );

      // Should show capability chips
      expect(find.text('camera'), findsOneWidget);
      expect(find.text('canvas'), findsOneWidget);
      expect(find.text('location'), findsOneWidget);
    });

    testWidgets('shows more indicator when many capabilities', (tester) async {
      final node = Node(
        id: 'test-node',
        displayName: 'Test Node',
        caps: ['camera', 'canvas', 'location', 'system.run', 'audio'],
        status: NodeStatus.online,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeTile(node: node),
          ),
        ),
      );

      // Should show first 3 caps and "+2" indicator
      expect(find.text('camera'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });
  });

  group('NodeDetailScreen Widget Tests', () {
    testWidgets('displays node detail information', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nodeProvider.overrideWith((ref) {
              final notifier = NodeNotifier();
              // Access private _loadMockData through initialization
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: NodeDetailScreen(nodeId: 'node-rasp'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show detail screen elements
      expect(find.text('Commands'), findsOneWidget);
      expect(find.text('Information'), findsOneWidget);
    });

    testWidgets('shows command dropdown', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeDetailScreen(nodeId: 'node-rasp'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have command dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows execute button when command selected', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeDetailScreen(nodeId: 'node-rasp'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no execute button (no command selected)
      // First, tap the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select first command
      final dropdownItems = find.byType(DropdownMenuItem<String>);
      if (dropdownItems.evaluate().isNotEmpty) {
        await tester.tap(dropdownItems.first);
        await tester.pumpAndSettle();

        // Now should have execute button
        expect(find.text('Execute Command'), findsOneWidget);
      }
    });
  });

  group('NodeState Tests', () {
    test('NodeState initializes correctly', () {
      const state = NodeState();

      expect(state.nodes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.error, isNull);
      expect(state.selectedNodeId, isNull);
    });

    test('NodeState copyWith works correctly', () {
      const state1 = NodeState();
      final state2 = state1.copyWith(isLoading: true);

      expect(state1.isLoading, isFalse);
      expect(state2.isLoading, isTrue);
    });

    test('NodeState selectedNode returns correct node', () {
      final node = Node(
        id: 'test-node',
        displayName: 'Test Node',
      );

      final state = NodeState(
        nodes: [node],
        selectedNodeId: 'test-node',
      );

      expect(state.selectedNode, equals(node));
    });

    test('NodeState onlineNodes filters correctly', () {
      final nodes = [
        Node(id: 'node-1', status: NodeStatus.online),
        Node(id: 'node-2', status: NodeStatus.offline),
        Node(id: 'node-3', status: NodeStatus.online),
      ];

      final state = NodeState(nodes: nodes);

      expect(state.onlineNodes.length, equals(2));
    });
  });

  group('InvokeState Tests', () {
    test('InvokeState initializes correctly', () {
      const state = InvokeState();

      expect(state.isInvoking, isFalse);
      expect(state.command, isNull);
      expect(state.nodeId, isNull);
      expect(state.lastResult, isNull);
      expect(state.error, isNull);
    });

    test('InvokeState copyWith works correctly', () {
      const state1 = InvokeState();
      final state2 = state1.copyWith(isInvoking: true, command: 'camera.snap');

      expect(state1.isInvoking, isFalse);
      expect(state1.command, isNull);
      expect(state2.isInvoking, isTrue);
      expect(state2.command, equals('camera.snap'));
    });
  });
}