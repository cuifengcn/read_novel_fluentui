/// https://github.com/flame-engine/flame/blob/main/packages/flame/lib/src/memory_cache.dart
library memory_cache;

import 'dart:collection';

/// Simple class to cache values with size based eviction.
///
class MemoryCache<K, V> {
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  final int cacheSize;
  final void Function(K key, V? value)? onDelete;

  MemoryCache({this.cacheSize = 20, this.onDelete});

  void setValue(K key, V value) {
    if (!_cache.containsKey(key)) {
      _cache[key] = value;

      // 没必要每次都清理
      if (_cache.length > cacheSize + 10) {
        while (_cache.length > cacheSize) {
          final k = _cache.keys.first;
          final v = _cache[k];
          print('清理缓存 $k $v $size');
          onDelete?.call(k, v);
          _cache.remove(k);
        }
      }
    }
  }

  V? getValue(K key) => _cache[key];

  V? getValueOrSet(K key, V? Function() or) {
    var value = _cache[key];
    if (value == null) {
      value = or();
      if (value != null) setValue(key, value);
    }
    return value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  int get size => _cache.length;

  clear() {
    _cache.forEach((key, value) {
      onDelete?.call(key, value);
    });
    _cache.clear();
  }
}
