// Widget tests for node list screen
// Tests node list display, selection, and navigation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawchat/src/features/nodes/node_list_screen.dart';
import 'package:clawchat/src/features/nodes/node_controller.dart';
import 'package:clawchat/src/core/models/node.dart';

void main() {
  group('NodeListScreen Widget Tests', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeListScreen(),
          ),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle();

      // Should show scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has refresh button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NodeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
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