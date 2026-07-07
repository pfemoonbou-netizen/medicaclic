import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  static const _purple = Color(0xFF5F55D7);
  static const _dark = Color(0xFF101522);
  static const _grey = Color(0xFF9B9999);
  static const _bg = Color(0xFFF7F8FA);
  static const double _delivery = 300; // frais de livraison (DA)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _dark,
        centerTitle: true,
        title: const Text('Mon Panier', style: TextStyle(fontWeight: FontWeight.bold, color: _dark)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Color(0xFFCBD0D6)),
                  SizedBox(height: 16),
                  Text('Votre panier est vide', style: TextStyle(color: _grey, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          final subtotal = cart.total;
          final total = subtotal + _delivery;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    ...cart.items.map((item) => _cartCard(context, cart, item)),
                    const SizedBox(height: 8),
                    _summary(cart.items.length, subtotal, total),
                  ],
                ),
              ),
              _bottomBar(context, cart, total),
            ],
          );
        },
      ),
    );
  }

  Widget _cartCard(BuildContext context, CartProvider cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: _itemImage(item.image)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(color: _dark, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${item.price.toStringAsFixed(0)} DA', style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () => cart.updateQuantity(item.id, item.quantity - 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}', style: const TextStyle(color: _dark, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    _qtyBtn(Icons.add, () => cart.updateQuantity(item.id, item.quantity + 1)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => cart.removeFromCart(item.id),
                      child: const Icon(Icons.delete_outline, color: Color(0xFFFF5C5C), size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: _purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: _purple),
      ),
    );
  }

  Widget _summary(int count, double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Text('Récapitulatif', style: TextStyle(color: _dark, fontSize: 16, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          _summaryRow('Articles', '$count'),
          const SizedBox(height: 8),
          _summaryRow('Sous-total', '${subtotal.toStringAsFixed(0)} DA'),
          const SizedBox(height: 8),
          _summaryRow('Livraison', '${_delivery.toStringAsFixed(0)} DA'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFE5E7EB))),
          _summaryRow('Total', '${total.toStringAsFixed(0)} DA', bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: bold ? _dark : const Color(0xFF484747), fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        Text(value, style: TextStyle(color: bold ? _purple : _dark, fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, CartProvider cart, double total) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)]),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total', style: TextStyle(color: _grey, fontSize: 12)),
                Text('${total.toStringAsFixed(0)} DA', style: const TextStyle(color: _dark, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    cart.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande passée avec succès ✅')));
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: const Text('Payer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemImage(String? img) {
    const double s = 70;
    if (img != null && img.startsWith('http')) {
      return Image.network(img, width: s, height: s, fit: BoxFit.cover, errorBuilder: (c, e, st) => _placeholder());
    }
    if (img != null && img.startsWith('assets/')) {
      return Image.asset(img, width: s, height: s, fit: BoxFit.cover, errorBuilder: (c, e, st) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 70,
        height: 70,
        color: const Color(0xFFECEEF2),
        child: const Icon(Icons.medical_services_outlined, color: _purple),
      );
}
