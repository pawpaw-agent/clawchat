/// Cache manager
library;

/// Simple in-memory cache manager
class CacheManager<T> {
  final Duration defaultExpiry;
  final Map<String, _CacheEntry<T>> _cache = {};

  CacheManager({this.defaultExpiry = const Duration(minutes: 30)});

  /// Get cached value
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Set cached value
  void set(String key, T value, {Duration? expiry}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(expiry ?? defaultExpiry),
    );
  }

  /// Remove cached value
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cached values
  void clear() {
    _cache.clear();
  }

  /// Get or compute value
  Future<T> getOrCompute(
    String key,
    Future<T> Function() compute, {
    Duration? expiry,
  }) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await compute();
    set(key, value, expiry: expiry);
    return value;
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});
}