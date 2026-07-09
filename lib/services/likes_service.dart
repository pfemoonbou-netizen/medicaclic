import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikesService {
  LikesService._();
  static final LikesService instance = LikesService._();

  final ValueNotifier<Set<String>> likedIds = ValueNotifier({});

  bool _loaded = false;

  bool isLiked(String id) => likedIds.value.contains(id);

  Future<void> load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { likedIds.value = {}; return; }
    _loaded = true;
    try {
      final rows = await Supabase.instance.client
          .from('product_likes')
          .select('product_id')
          .eq('user_id', user.id);
      final ids = <String>{};
      for (final row in rows as List) {
        final pid = row['product_id'];
        if (pid is String) ids.add(pid);
      }
      likedIds.value = ids;
    } catch (_) {}
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<void> toggle(String productId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final wasLiked = isLiked(productId);
    // Optimistic update
    likedIds.value = wasLiked
        ? likedIds.value.where((id) => id != productId).toSet()
        : {...likedIds.value, productId};
    try {
      if (wasLiked) {
        await Supabase.instance.client
            .from('product_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      } else {
        await Supabase.instance.client.from('product_likes').upsert(
            {'user_id': user.id, 'product_id': productId},
            onConflict: 'user_id,product_id');
      }
    } catch (_) {
      // Revert on failure
      likedIds.value = wasLiked
          ? {...likedIds.value, productId}
          : likedIds.value.where((id) => id != productId).toSet();
    }
  }

  void reset() {
    _loaded = false;
    likedIds.value = {};
  }
}
