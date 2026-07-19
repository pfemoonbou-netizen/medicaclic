import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _purple = Color(0xFF5F55D7);
  static const _dark = Color(0xFF101522);
  static const _grey = Color(0xFF9B9999);
  static const _bg = Color(0xFFF7F8FA);

  bool _fav = false;
  bool _sendingRequest = false;

  Future<void> _sendRequest() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faire une demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Votre téléphone')),
            const SizedBox(height: 12),
            TextField(controller: messageController, maxLines: 3, decoration: const InputDecoration(labelText: 'Message (optionnel)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sendingRequest = true);
    try {
      final buyerName = context.read<AuthProvider>().user?.name ?? '';
      await context.read<ProductProvider>().sendProductRequest(
            productId: widget.product.id,
            productName: widget.product.name,
            sellerId: widget.product.sellerId!,
            buyerId: uid,
            buyerName: buyerName,
            buyerPhone: phoneController.text.trim(),
            message: messageController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée au vendeur.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  Future<void> _call() async {
    final phone = widget.product.phone;
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _addToCart() {
    final p = widget.product;
    context.read<CartProvider>().addToCart(CartItem(id: p.id, name: p.name, price: p.price, image: p.image));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.name} ajouté au panier'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final discount = p.discountPercent;

    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Image + boutons superposés ----
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                child: SizedBox(height: 360, width: double.infinity, child: _productImage(p.image)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                      _circleBtn(_fav ? Icons.favorite : Icons.favorite_border, () => setState(() => _fav = !_fav), iconColor: _fav ? Colors.red : _dark),
                    ],
                  ),
                ),
              ),
              if (discount != null)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Nom + prix ----
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(p.name, style: const TextStyle(color: _dark, fontSize: 22, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.price.toStringAsFixed(0)} DA', style: const TextStyle(color: _purple, fontSize: 20, fontWeight: FontWeight.w800)),
                        if (p.originalPrice != null)
                          Text('${p.originalPrice!.toStringAsFixed(0)} DA', style: const TextStyle(color: _grey, fontSize: 13, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.brand, style: const TextStyle(color: _grey, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Color(0xFFFFB020)),
                    const SizedBox(width: 6),
                    Text('${p.rating}', style: const TextStyle(color: _dark, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('( ${p.reviewCount} avis )', style: const TextStyle(color: _grey, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(p.category, style: const TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ---- Description ----
                const Text('Description', style: TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(p.description, style: const TextStyle(color: _grey, fontSize: 14, height: 1.5)),
                const SizedBox(height: 22),

                // ---- Contact vendeur ----
                const Text('Vendeur', style: TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: _purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.storefront, color: _purple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.seller.isEmpty ? 'Vendeur MedicaClic' : p.seller, style: const TextStyle(color: _dark, fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(p.phone.isEmpty ? 'Contact indisponible' : p.phone, style: const TextStyle(color: _grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _call,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFF1AA88F), shape: BoxShape.circle),
                          child: const Icon(Icons.call, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.sellerId != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sendingRequest ? null : _sendRequest,
                      icon: _sendingRequest
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_purple)))
                          : const Icon(Icons.send_outlined, color: _purple, size: 18),
                      label: const Text('Faire une demande au vendeur', style: TextStyle(color: _purple, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: _purple), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),

      // ---- Barre du bas : panier + appeler ----
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                    label: const Text('Ajouter au panier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: _purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _call,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: const Color(0xFF1AA88F).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.call, color: Color(0xFF1AA88F)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color iconColor = _dark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)]),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _productImage(String? img) {
    if (img != null && img.startsWith('http')) {
      return Image.network(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => _imgPlaceholder());
    }
    if (img != null && img.startsWith('assets/')) {
      return Image.asset(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => _imgPlaceholder());
    }
    return _imgPlaceholder();
  }

  Widget _imgPlaceholder() => Container(
        color: const Color(0xFFECEEF2),
        child: const Center(child: Icon(Icons.medical_services_outlined, size: 64, color: _purple)),
      );
}
