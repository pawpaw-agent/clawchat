// Performance tests for list optimization
// Run with: flutter test test/performance/list_performance_test.dart --profile

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/src/core/utils/list_optimizer.dart';
import 'package:clawchat/src/core/models/message.dart';

void main() {
  group('DiffUtil Tests', () {
    late DiffUtil<Message> diffUtil;

    setUp(() {
      diffUtil = DiffUtil<Message>(
        idExtractor: (msg) => msg.id,
        contentComparator: (a, b) => a.content == b.content && a.isComplete == b.isComplete,
      );
    });

    test('detects inserted items', () {
      final oldList = [
        _createMessage('1', 'Hello'),
        _createMessage('2', 'World'),
      ];

      final newList = [
        _createMessage('1', 'Hello'),
        _createMessage('2', 'World'),
        _createMessage('3', 'New'),
      ];

      final result = diffUtil.calculateDiff(oldList: oldList, newList: newList);

      expect(result.hasChanges, isTrue);
      expect(result.newSize, equals(3));
      expect(result.oldSize, equals(2));

      final inserts = result.operations.whereType<InsertOperation<Message>>();
      expect(inserts.length, equals(1));
    });

    test('detects removed items', () {
      final oldList = [
        _createMessage('1', 'Hello'),
        _createMessage('2', 'World'),
        _createMessage('3', 'Deleted'),
      ];

      final newList = [
        _createMessage('1', 'Hello'),
        _createMessage('2', 'World'),
      ];

      final result = diffUtil.calculateDiff(oldList: oldList, newList: newList);

      expect(result.hasChanges, isTrue);
      final removes = result.operations.whereType<RemoveOperation<Message>>();
      expect(removes.length, equals(1));
    });

    test('detects updated items', () {
      final oldList = [
        _createMessage('1', 'Hello'),
        _createMessage('2', 'World'),
      ];

      final newList = [
        _createMessage('1', 'Hello'),
        _createMessage('2', 'Updated World'),
      ];

      final result = diffUtil.calculateDiff(oldList: oldList, newList: newList);

      final updates = result.operations.whereType<UpdateOperation<Message>>();
      expect(updates.length, equals(1));
    });

    test('handles empty lists', () {
      final result = diffUtil.calculateDiff(
        oldList: <Message>[],
        newList: <Message>[],
      );

      expect(result.hasChanges, isFalse);
      expect(result.newSize, equals(0));
    });

    test('detects complete replacement', () {
      final oldList = [
        _createMessage('1', 'Old 1'),
        _createMessage('2', 'Old 2'),
      ];

      final newList = [
        _createMessage('3', 'New 1'),
        _createMessage('4', 'New 2'),
      ];

      final result = diffUtil.calculateDiff(oldList: oldList, newList: newList);

      expect(result.hasChanges, isTrue);
      final removes = result.operations.whereType<RemoveOperation<Message>>();
      final inserts = result.operations.whereType<InsertOperation<Message>>();
      expect(removes.length, equals(2));
      expect(inserts.length, equals(2));
    });
  });

  group('ListItemCache Tests', () {
    test('stores and retrieves items', () {
      final cache = ListItemCache<String, int>(maxSize: 10);

      cache.put('a', 1);
      cache.put('b', 2);

      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), isNull);
    });

    test('evicts least recently used items', () {
      final cache = ListItemCache<String, int>(maxSize: 2);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3); // Should evict 'a'

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
    });

    test('updates LRU order on access', () {
      final cache = ListItemCache<String, int>(maxSize: 2);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.get('a'); // Access 'a' to make it more recent
      cache.put('c', 3); // Should evict 'b' (least recently used)

      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), equals(3));
    });

    test('clears all items', () {
      final cache = ListItemCache<String, int>(maxSize: 10);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();

      expect(cache.length, equals(0));
      expect(cache.contains('a'), isFalse);
    });
  });

  group('PaginationState Tests', () {
    test('initializes with correct defaults', () {
      const state = PaginationState<String>();

      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.currentPage, equals(0));
      expect(state.pageSize, equals(20));
      expect(state.error, isNull);
    });

    test('detects first load correctly', () {
      const loadingState = PaginationState<String>(isLoading: true, items: []);
      const loadedState = PaginationState<String>(isLoading: true, items: ['a']);

      expect(loadingState.isFirstLoad, isTrue);
      expect(loadedState.isFirstLoad, isFalse);
    });

    test('canLoadMore works correctly', () {
      const canLoadState = PaginationState<String>(hasMore: true, isLoading: false);
      const loadingState = PaginationState<String>(hasMore: true, isLoading: true);
      const noMoreState = PaginationState<String>(hasMore: false, isLoading: false);
      const errorState = PaginationState<String>(hasMore: true, isLoading: false, error: 'Error');

      expect(canLoadState.canLoadMore, isTrue);
      expect(loadingState.canLoadMore, isFalse);
      expect(noMoreState.canLoadMore, isFalse);
      expect(errorState.canLoadMore, isFalse);
    });

    test('copyWith works correctly', () {
      const original = PaginationState<String>();
      final updated = original.copyWith(
        items: ['a', 'b'],
        currentPage: 1,
        hasMore: false,
      );

      expect(updated.items.length, equals(2));
      expect(updated.currentPage, equals(1));
      expect(updated.hasMore, isFalse);
      expect(updated.pageSize, equals(20)); // Preserved from original
    });
  });

  group('PaginationController Tests', () {
    test('loads initial page', () async {
      final controller = PaginationController<int>(
        pageSize: 10,
        fetchPage: (page, size) async {
          return List.generate(size, (i) => page * size + i);
        },
      );

      await controller.loadInitial();

      expect(controller.state.items.length, equals(10));
      expect(controller.state.currentPage, equals(0));
      expect(controller.state.hasMore, isTrue);
    });

    test('loads subsequent pages', () async {
      final controller = PaginationController<int>(
        pageSize: 10,
        fetchPage: (page, size) async {
          return List.generate(size, (i) => page * size + i);
        },
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.state.items.length, equals(20));
      expect(controller.state.currentPage, equals(1));
    });

    test('detects end of data', () async {
      var callCount = 0;
      final controller = PaginationController<int>(
        pageSize: 10,
        fetchPage: (page, size) async {
          callCount++;
          // Return fewer items on second page to signal end
          if (page == 1) return [100, 101, 102];
          return List.generate(size, (i) => i);
        },
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.state.hasMore, isFalse);
      expect(controller.state.items.length, equals(13)); // 10 + 3
    });

    test('refresh resets and reloads', () async {
      final controller = PaginationController<int>(
        pageSize: 10,
        fetchPage: (page, size) async {
          return List.generate(size, (i) => page * size + i);
        },
      );

      await controller.loadInitial();
      await controller.loadMore();
      await controller.refresh();

      expect(controller.state.currentPage, equals(0));
      expect(controller.state.items.length, equals(10));
    });
  });

  group('ListPerformanceMetrics Tests', () {
    test('calculates average FPS correctly', () {
      final metrics = ListPerformanceMetrics(
        listId: 'test',
        startTime: DateTime.now(),
        itemCount: 100,
        visibleItemCount: 10,
      );

      // Record some frames (16.67ms = 60fps, 20ms = 50fps, 33ms = 30fps)
      metrics.recordFrame(const Duration(microseconds: 16667));
      metrics.recordFrame(const Duration(microseconds: 20000));
      metrics.recordFrame(const Duration(microseconds: 33333));

      expect(metrics.averageFps, isNotNull);
      expect(metrics.averageFps, greaterThan(30));
      expect(metrics.averageFps, lessThan(60));
    });

    test('counts dropped frames', () {
      final metrics = ListPerformanceMetrics(
        listId: 'test',
        startTime: DateTime.now(),
        itemCount: 100,
        visibleItemCount: 10,
      );

      // 60fps (no drop)
      metrics.recordFrame(const Duration(microseconds: 16667));
      // 30fps (drop)
      metrics.recordFrame(const Duration(microseconds: 33333));
      // 45fps (drop)
      metrics.recordFrame(const Duration(microseconds: 22222));

      expect(metrics.droppedFrames, equals(2));
    });

    test('converts to map correctly', () {
      final metrics = ListPerformanceMetrics(
        listId: 'test',
        startTime: DateTime.now(),
        itemCount: 100,
        visibleItemCount: 10,
      );

      metrics.recordFrame(const Duration(microseconds: 16667));
      metrics.setMemoryUsage(150.5);
      metrics.setScrollLatency(const Duration(milliseconds: 100));

      final map = metrics.toMap();

      expect(map['listId'], equals('test'));
      expect(map['itemCount'], equals(100));
      expect(map['memoryMB'], equals('150.5'));
      expect(map['scrollLatencyMs'], equals(100));
    });
  });
}

/// Helper to create test messages
Message _createMessage(String id, String content) {
  return Message(
    id: id,
    sessionKey: 'test-session',
    role: MessageRole.user.value,
    content: content,
    createdAt: DateTime.now(),
    isComplete: true,
  );
}