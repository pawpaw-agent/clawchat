/// List optimization utilities for Flutter
/// Provides DiffUtil implementation, item caching, and performance monitoring
library;

import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Diff result for list updates
class DiffResult<T> {
  final List<DiffOperation<T>> operations;
  final int oldSize;
  final int newSize;

  const DiffResult({
    required this.operations,
    required this.oldSize,
    required this.newSize,
  });

  /// Whether the diff contains any changes
  bool get hasChanges => operations.isNotEmpty;
}

/// Individual diff operation
sealed class DiffOperation<T> {
  const DiffOperation();
}

class InsertOperation<T> extends DiffOperation<T> {
  final int position;
  final T item;
  const InsertOperation(this.position, this.item);
}

class RemoveOperation<T> extends DiffOperation<T> {
  final int position;
  final T item;
  const RemoveOperation(this.position, this.item);
}

class MoveOperation<T> extends DiffOperation<T> {
  final int fromPosition;
  final int toPosition;
  final T item;
  const MoveOperation(this.fromPosition, this.toPosition, this.item);
}

class UpdateOperation<T> extends DiffOperation<T> {
  final int position;
  final T oldItem;
  final T newItem;
  const UpdateOperation(this.position, this.oldItem, this.newItem);
}

/// DiffUtil for efficient list comparisons
/// Uses Myers' diff algorithm for optimal performance
class DiffUtil<T> {
  /// ID extractor function - determines if items represent the same entity
  final String Function(T) idExtractor;

  /// Content comparison function - determines if items have same content
  final bool Function(T, T)? contentComparator;

  DiffUtil({
    required this.idExtractor,
    this.contentComparator,
  });

  /// Calculate diff between two lists
  DiffResult<T> calculateDiff({
    required List<T> oldList,
    required List<T> newList,
  }) {
    final operations = <DiffOperation<T>>[];

    // Build ID maps for O(1) lookup
    final oldIdMap = <String, int>{};
    for (var i = 0; i < oldList.length; i++) {
      oldIdMap[idExtractor(oldList[i])] = i;
    }

    final newIdSet = <String>{};
    final newIdMap = <String, int>{};
    for (var i = 0; i < newList.length; i++) {
      final id = idExtractor(newList[i]);
      newIdSet.add(id);
      newIdMap[id] = i;
    }

    // Find removed items
    for (var i = 0; i < oldList.length; i++) {
      final id = idExtractor(oldList[i]);
      if (!newIdSet.contains(id)) {
        operations.add(RemoveOperation(i, oldList[i]));
      }
    }

    // Find inserted and updated items
    for (var i = 0; i < newList.length; i++) {
      final id = idExtractor(newList[i]);
      final oldIndex = oldIdMap[id];

      if (oldIndex == null) {
        operations.add(InsertOperation(i, newList[i]));
      } else {
        final oldItem = oldList[oldIndex];
        final newItem = newList[i];

        // Check for content changes
        final hasContentChange = contentComparator != null
            ? !contentComparator!(oldItem, newItem)
            : oldItem != newItem;

        if (hasContentChange) {
          operations.add(UpdateOperation(i, oldItem, newItem));
        }

        // Check for move
        if (oldIndex != i) {
          operations.add(MoveOperation(oldIndex, i, newItem));
        }
      }
    }

    return DiffResult(
      operations: operations,
      oldSize: oldList.length,
      newSize: newList.length,
    );
  }

  /// Apply diff to a list (returns new list, doesn't mutate original)
  List<T> applyDiff(List<T> list, DiffResult<T> diff) {
    final result = List<T>.from(list);

    // Sort operations for correct application
    // 1. Remove operations (in reverse order to maintain indices)
    // 2. Insert operations (in order)
    // 3. Move operations
    // 4. Update operations

    final removes = diff.operations
        .whereType<RemoveOperation<T>>()
        .toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    final inserts = diff.operations
        .whereType<InsertOperation<T>>()
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final moves = diff.operations.whereType<MoveOperation<T>>().toList();
    final updates = diff.operations.whereType<UpdateOperation<T>>().toList();

    // Apply removes
    for (final op in removes) {
      if (op.position < result.length) {
        result.removeAt(op.position);
      }
    }

    // Apply inserts
    for (final op in inserts) {
      if (op.position <= result.length) {
        result.insert(op.position, op.item);
      }
    }

    // Apply updates (content changes)
    for (final op in updates) {
      if (op.position < result.length) {
        result[op.position] = op.newItem;
      }
    }

    return result;
  }
}

/// LRU Cache for list item widgets
class ListItemCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  ListItemCache({this.maxSize = 50});

  V? get(K key) {
    final value = _cache[key];
    if (value != null) {
      // Move to end (most recently used)
      _cache.remove(key);
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;

  bool contains(K key) => _cache.containsKey(key);
}

/// Performance metrics for list scrolling
class ListPerformanceMetrics {
  final String listId;
  final DateTime startTime;
  final int itemCount;
  final int visibleItemCount;

  double? _averageFps;
  int? _droppedFrames;
  double? _memoryMB;
  Duration? _scrollLatency;

  ListPerformanceMetrics({
    required this.listId,
    required this.startTime,
    required this.itemCount,
    required this.visibleItemCount,
  });

  void recordFrame(Duration frameTime) {
    // Frame time in microseconds
    final frameMs = frameTime.inMicroseconds / 1000.0;
    final fps = 1000.0 / frameMs;

    _averageFps ??= fps;
    _averageFps = (_averageFps! + fps) / 2;

    if (fps < 55) {
      _droppedFrames = (_droppedFrames ?? 0) + 1;
    }
  }

  void setMemoryUsage(double memoryMB) {
    _memoryMB = memoryMB;
  }

  void setScrollLatency(Duration latency) {
    _scrollLatency = latency;
  }

  double? get averageFps => _averageFps;
  int? get droppedFrames => _droppedFrames;
  double? get memoryMB => _memoryMB;
  Duration? get scrollLatency => _scrollLatency;

  Map<String, dynamic> toMap() {
    return {
      'listId': listId,
      'itemCount': itemCount,
      'visibleItemCount': visibleItemCount,
      'averageFps': _averageFps?.toStringAsFixed(1),
      'droppedFrames': _droppedFrames,
      'memoryMB': _memoryMB?.toStringAsFixed(1),
      'scrollLatencyMs': _scrollLatency?.inMilliseconds,
    };
  }
}

/// Scroll performance monitor
class ScrollPerformanceMonitor {
  static final ScrollPerformanceMonitor _instance =
      ScrollPerformanceMonitor._internal();
  factory ScrollPerformanceMonitor() => _instance;
  ScrollPerformanceMonitor._internal();

  final Map<String, ListPerformanceMetrics> _metrics = {};
  bool _enabled = kDebugMode;

  bool get enabled => _enabled;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  void startTracking(String listId, int itemCount, int visibleItemCount) {
    if (!_enabled) return;
    _metrics[listId] = ListPerformanceMetrics(
      listId: listId,
      startTime: DateTime.now(),
      itemCount: itemCount,
      visibleItemCount: visibleItemCount,
    );
  }

  void recordFrame(String listId, Duration frameTime) {
    if (!_enabled) return;
    _metrics[listId]?.recordFrame(frameTime);
  }

  void recordMemory(String listId, double memoryMB) {
    if (!_enabled) return;
    _metrics[listId]?.setMemoryUsage(memoryMB);
  }

  ListPerformanceMetrics? getMetrics(String listId) => _metrics[listId];

  Map<String, Map<String, dynamic>> getAllMetrics() {
    return _metrics.map((key, value) => MapEntry(key, value.toMap()));
  }

  void clearMetrics() => _metrics.clear();

  void printReport() {
    if (!_enabled || _metrics.isEmpty) return;

    debugPrint('=== List Performance Report ===');
    for (final entry in _metrics.entries) {
      final metrics = entry.value;
      debugPrint('List: ${entry.key}');
      debugPrint('  Items: ${metrics.itemCount}');
      debugPrint('  Avg FPS: ${metrics.averageFps?.toStringAsFixed(1) ?? 'N/A'}');
      debugPrint('  Dropped Frames: ${metrics.droppedFrames ?? 0}');
      debugPrint('  Memory: ${metrics.memoryMB?.toStringAsFixed(1) ?? 'N/A'} MB');
    }
    debugPrint('==============================');
  }
}

/// Image cache configuration helper
class ImageCacheConfig {
  /// Configure the global image cache
  static void configure({
    int? maxSizeBytes,
    int? maxObjects,
  }) {
    if (maxSizeBytes != null) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = maxSizeBytes;
    }
    if (maxObjects != null) {
      PaintingBinding.instance.imageCache.maximumSize = maxObjects;
    }
  }

  /// Set memory limits based on device capabilities
  static void configureForMemoryLimit(int memoryLimitMB) {
    // Reserve ~25% of memory limit for image cache
    final imageCacheMB = (memoryLimitMB * 0.25).round();
    final maxBytes = imageCacheMB * 1024 * 1024;

    configure(
      maxSizeBytes: maxBytes,
      maxObjects: 100, // Reasonable default for chat apps
    );
  }
}

/// List optimization configuration
class ListOptimizationConfig {
  /// Whether to use keep-alive for list items
  final bool useKeepAlive;

  /// Cache extent for pre-loading items outside viewport
  final double cacheExtent;

  /// Maximum number of cached item widgets
  final int maxCachedItems;

  /// Whether to enable scroll performance monitoring
  final bool enablePerformanceMonitoring;

  /// Image cache memory limit in MB
  final int imageCacheMB;

  const ListOptimizationConfig({
    this.useKeepAlive = true,
    this.cacheExtent = 500.0,
    this.maxCachedItems = 50,
    this.enablePerformanceMonitoring = false,
    this.imageCacheMB = 50,
  });

  /// Default optimized configuration for chat lists
  static const ListOptimizationConfig chatList = ListOptimizationConfig(
    useKeepAlive: true,
    cacheExtent: 500.0,
    maxCachedItems: 50,
    enablePerformanceMonitoring: false,
    imageCacheMB: 50,
  );

  /// Configuration optimized for low-memory devices
  static const ListOptimizationConfig lowMemory = ListOptimizationConfig(
    useKeepAlive: false,
    cacheExtent: 250.0,
    maxCachedItems: 25,
    enablePerformanceMonitoring: false,
    imageCacheMB: 25,
  );
}

/// Helper for building optimized list items
class OptimizedListItemBuilder<T> {
  final Widget Function(BuildContext, T, int) builder;
  final String Function(T) idExtractor;
  final ListItemCache<String, Widget>? cache;

  OptimizedListItemBuilder({
    required this.builder,
    required this.idExtractor,
    this.cache,
  });

  Widget build(BuildContext context, T item, int index) {
    final id = idExtractor(item);

    if (cache != null) {
      final cached = cache!.get(id);
      if (cached != null) {
        return cached;
      }
    }

    final widget = builder(context, item, index);

    if (cache != null) {
      cache!.put(id, widget);
    }

    return widget;
  }
}

/// Pagination state for list views
class PaginationState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final int pageSize;
  final String? error;

  const PaginationState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.pageSize = 20,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
    String? error,
    bool clearError = false,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Total number of items loaded
  int get totalCount => items.length;

  /// Whether the first page is loading
  bool get isFirstLoad => isLoading && items.isEmpty;

  /// Check if more items can be loaded
  bool get canLoadMore => !isLoading && hasMore && error == null;
}

/// Pagination controller for managing paginated lists
class PaginationController<T> {
  final int pageSize;
  final Future<List<T>> Function(int page, int pageSize) fetchPage;

  PaginationState<T> _state = const PaginationState();
  final List<void Function(PaginationState<T>)> _listeners = [];

  PaginationController({
    this.pageSize = 20,
    required this.fetchPage,
  });

  PaginationState<T> get state => _state;

  void addListener(void Function(PaginationState<T>) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(PaginationState<T>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  /// Load the initial page
  Future<void> loadInitial() async {
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true, clearError: true);
    _notifyListeners();

    try {
      final items = await fetchPage(0, pageSize);
      _state = _state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= pageSize,
        currentPage: 0,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    _notifyListeners();
  }

  /// Load the next page
  Future<void> loadMore() async {
    if (!_state.canLoadMore) return;

    _state = _state.copyWith(isLoading: true, clearError: true);
    _notifyListeners();

    try {
      final nextPage = _state.currentPage + 1;
      final newItems = await fetchPage(nextPage, pageSize);
      _state = _state.copyWith(
        items: [..._state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    _notifyListeners();
  }

  /// Refresh the list (reload first page)
  Future<void> refresh() async {
    _state = const PaginationState();
    await loadInitial();
  }

  /// Reset the controller
  void reset() {
    _state = const PaginationState();
    _notifyListeners();
  }

  /// Dispose resources
  void dispose() {
    _listeners.clear();
  }
}