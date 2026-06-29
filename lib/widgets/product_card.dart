import 'package:flutter/material.dart';
import '../providers/product_provider.dart';
import '../screens/pharmacy/boutique_theme.dart';
import '../screens/pharmacy/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  const ProductCard({Key? key, required this.product, required this.onAddToCart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BoutiqueColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: BoutiqueColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  child: Center(child: Text(product.image ?? 'RX', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BoutiqueColors.accent))),
                ),
                if (discount != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: BoutiqueColors.red, borderRadius: BorderRadius.circular(20)),
                      child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(product.name, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.chevron_right, size: 16, color: BoutiqueColors.textFaint),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(product.brand, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: BoutiqueColors.orange),
                      const SizedBox(width: 4),
                      Text('${product.rating}', style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('(${product.reviewCount})', style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${product.price.toStringAsFixed(0)} DA', style: const TextStyle(color: BoutiqueColors.accent, fontSize: 15, fontWeight: FontWeight.w700)),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text('${product.originalPrice!.toStringAsFixed(0)} DA', style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 12, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                      label: const Text('Acheter', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: BoutiqueColors.accent, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: BoutiqueColors.border, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.store_outlined, size: 13, color: BoutiqueColors.textFaint),
                      const SizedBox(width: 4),
                      Expanded(child: Text(product.seller, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11), overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.call_outlined, size: 14, color: BoutiqueColors.accent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
