/// Simple in-memory cache with TTL — survives tab switches.
class AppCache {
  AppCache._();
  static final AppCache instance = AppCache._();

  static const _ttl = Duration(minutes: 3);

  // ── Generic entry ───────────────────────────────────────────────────────────
  final Map<String, _Entry> _store = {};

  T? get<T>(String key) {
    final e = _store[key];
    if (e == null || DateTime.now().difference(e.at) > _ttl) return null;
    return e.value as T?;
  }

  void set<T>(String key, T value) =>
      _store[key] = _Entry(value, DateTime.now());

  void invalidate(String key) => _store.remove(key);

  void invalidateAll() => _store.clear();

  // ── Named slots (avoids typos) ──────────────────────────────────────────────
  static const kStores        = 'stores';
  static const kFeedProducts  = 'feed_products';
  static const kShopProducts  = 'shop_products';
  static const kFollowedIds   = 'followed_ids';
  static const kOwnerAvatars  = 'owner_avatars';
}

class _Entry {
  final dynamic value;
  final DateTime at;
  const _Entry(this.value, this.at);
}
