import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String? image;
  CartItem({required this.id, required this.name, required this.price, this.quantity = 1, this.image});
  double get totalPrice => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;

  CartProvider() {
    fetchCart();
  }

  List<CartItem> get items => _items;
  double get total => _items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  String? get _userId => supabase.auth.currentUser?.id;

  Future<void> fetchCart() async {
    final userId = _userId;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final rows = await supabase.from('cart_items').select('quantity, products(id, name, price, image)').eq('user_id', userId);
      _items.clear();
      for (final row in rows as List) {
        final product = row['products'] as Map<String, dynamic>;
        _items.add(CartItem(
          id: product['id'] as String,
          name: product['name'] as String,
          price: (product['price'] as num).toDouble(),
          quantity: (row['quantity'] as num).toInt(),
          image: product['image'] as String?,
        ));
      }
    } catch (_) {
      // Garde le panier local si la requête échoue (ex: hors-ligne).
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(CartItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();

    final userId = _userId;
    if (userId == null) return;
    final quantity = _items.firstWhere((i) => i.id == item.id).quantity;
    await supabase.from('cart_items').upsert({'user_id': userId, 'product_id': item.id, 'quantity': quantity}, onConflict: 'user_id,product_id');
  }

  Future<void> removeFromCart(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();

    final userId = _userId;
    if (userId == null) return;
    await supabase.from('cart_items').delete().eq('user_id', userId).eq('product_id', id);
  }

  Future<void> updateQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(id);
      return;
    }
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();

    final userId = _userId;
    if (userId == null) return;
    await supabase.from('cart_items').upsert({'user_id': userId, 'product_id': id, 'quantity': quantity}, onConflict: 'user_id,product_id');
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    final userId = _userId;
    if (userId == null) return;
    await supabase.from('cart_items').delete().eq('user_id', userId);
  }
}
