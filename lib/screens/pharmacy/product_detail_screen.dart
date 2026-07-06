import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import 'boutique_theme.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;
    return Scaffold(
      backgroundColor: BoutiqueColors.background,
      appBar: AppBar(
        backgroundColor: BoutiqueColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: BoutiqueColors.textPrimary),
        title: const Text('Détails', style: TextStyle(color: BoutiqueColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: BoutiqueColors.border)),
                child: _productImage(product.image),
              ),
              if (discount != null)
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: BoutiqueColors.red, borderRadius: BorderRadius.circular(20)),
                    child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(product.name, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(product.brand, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: BoutiqueColors.orange),
              const SizedBox(width: 4),
              Text('${product.rating}', style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('(${product.reviewCount} avis)', style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${product.price.toStringAsFixed(0)} DA', style: const TextStyle(color: BoutiqueColors.accent, fontSize: 22, fontWeight: FontWeight.w800)),
              if (product.originalPrice != null) ...[
                const SizedBox(width: 8),
                Text('${product.originalPrice!.toStringAsFixed(0)} DA', style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 14, decoration: TextDecoration.lineThrough)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BoutiqueColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(product.description, style: const TextStyle(color: BoutiqueColors.textSecondary, fontSize: 14, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BoutiqueColors.border)),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: BoutiqueColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.store_outlined, color: BoutiqueColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.seller, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(product.phone, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: product.phone)),
                  icon: const Icon(Icons.call, color: BoutiqueColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<CartProvider>().addToCart(CartItem(id: product.id, name: product.name, price: product.price, image: product.image));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} ajouté au panier'), duration: const Duration(seconds: 1)));
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              label: const Text('Ajouter au panier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(backgroundColor: BoutiqueColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productImage(String? img) {
    if (img != null && img.startsWith('http')) {
      return Image.network(img, height: 220, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => _imgPlaceholder());
    }
    if (img != null && img.startsWith('assets/')) {
      return Image.asset(img, height: 220, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => _imgPlaceholder());
    }
    return _imgPlaceholder();
  }

  Widget _imgPlaceholder() => const Center(child: Icon(Icons.medical_services_outlined, size: 56, color: BoutiqueColors.accent));
}
