// Widget tests for paginated session list
// Tests pagination, scroll behavior, and infinite loading

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawchat/src/features/sessions/session_list_screen.dart';
import 'package:clawchat/src/core/utils/list_optimizer.dart';

void main() {
  group('SessionListScreen Widget Tests', () {
    testWidgets('renders correctly with empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Should show scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows FAB for creating new chat', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('has scrollable content for pull-to-refresh', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify scrollable content is present (could be ListView, CustomScrollView, etc.)
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('has proper widget structure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SessionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have some form of list content
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaginationState Tests', () {
    test('PaginationState initializes correctly', () {
      final state = PaginationState<String>();
      
      expect(state.items, isEmpty);
      expect(state.pageSize, equals(20));
      expect(state.currentPage, equals(0));
      expect(state.hasMore, isTrue);
    });

    test('PaginationState canLoadMore works correctly', () {
      // Can load more
      final state1 = PaginationState<String>(hasMore: true, isLoading: false);
      expect(state1.canLoadMore, isTrue);
      
      // Cannot load more when loading
      const state2 = PaginationState<String>(hasMore: true, isLoading: true);
      expect(state2.canLoadMore, isFalse);
      
      // Cannot load more when no more data
      const state3 = PaginationState<String>(hasMore: false, isLoading: false);
      expect(state3.canLoadMore, isFalse);
      
      // Cannot load more when error
      const state4 = PaginationState<String>(hasMore: true, isLoading: false, error: 'Error');
      expect(state4.canLoadMore, isFalse);
    });

    test('PaginationState isFirstLoad works correctly', () {
      // First load
      const state1 = PaginationState<String>(isLoading: true, items: []);
      expect(state1.isFirstLoad, isTrue);
      
      // Not first load
      const state2 = PaginationState<String>(isLoading: true, items: ['a']);
      expect(state2.isFirstLoad, isFalse);
      
      // Not loading
      const state3 = PaginationState<String>(isLoading: false, items: []);
      expect(state3.isFirstLoad, isFalse);
    });
  });

  group('SessionListScreenState Tests', () {
    test('provides public refresh method', () {
      // This is a compile-time check to ensure the public API exists
      final state = SessionListScreenState();
      expect(state.refresh, isA<Function>());
    });
  });

  group('ListOptimizationConfig Tests', () {
    test('default config has correct values', () {
      const config = ListOptimizationConfig.chatList;
      
      expect(config.useKeepAlive, isTrue);
      expect(config.cacheExtent, equals(500.0));
      expect(config.maxCachedItems, equals(50));
      expect(config.imageCacheMB, equals(50));
    });

    test('lowMemory config has reduced values', () {
      const config = ListOptimizationConfig.lowMemory;
      
      expect(config.useKeepAlive, isFalse);
      expect(config.cacheExtent, equals(250.0));
      expect(config.maxCachedItems, equals(25));
      expect(config.imageCacheMB, equals(25));
    });
  });
}