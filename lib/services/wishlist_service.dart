import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistService {
  WishlistService._();
  static final WishlistService instance = WishlistService._();

  final ValueNotifier<Set<String>> ids   = ValueNotifier({});
  final ValueNotifier<List<Map<String, dynamic>>> items = ValueNotifier([]);

  bool _loaded = false;

  bool contains(String id) => ids.value.contains(id);

  Future<void> load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _clear();
        _loaded = true;
        return;
      }
      _loaded = true;
      final rows = await Supabase.instance.client
          .from('product_wishlist')
          .select('product_id, products(id, name, price, promo_price, images, '
              'stores(store_name))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final idSet  = <String>{};
      final itemList = <Map<String, dynamic>>[];
      for (final row in rows as List) {
        final pid = row['product_id'];
        if (pid is! String) continue;
        idSet.add(pid);
        final prod = row['products'];
        if (prod is Map<String, dynamic>) itemList.add(prod);
      }
      ids.value   = idSet;
      items.value = itemList;
    } catch (_) {
      _loaded = true;
      _clear();
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<void> add(String productId, Map<String, dynamic> product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    ids.value   = {...ids.value, productId};
    items.value = [product, ...items.value.where((p) => p['id'] != productId)];
    try {
      await Supabase.instance.client.from('product_wishlist').upsert(
          {'user_id': user.id, 'product_id': productId},
          onConflict: 'user_id,product_id');
    } catch (_) {}
  }

  Future<void> remove(String productId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    ids.value   = ids.value.where((id) => id != productId).toSet();
    items.value = items.value.where((p) => p['id'] != productId).toList();
    try {
      await Supabase.instance.client
          .from('product_wishlist')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    } catch (_) {}
  }

  Future<void> toggle(String productId, Map<String, dynamic> product) async {
    if (contains(productId)) {
      await remove(productId);
    } else {
      await add(productId, product);
    }
  }

  void _clear() {
    ids.value   = {};
    items.value = [];
  }

  void reset() {
    _loaded = false;
    _clear();
  }
}
