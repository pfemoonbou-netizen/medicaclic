import 'package:flutter/material.dart';
import '../providers/product_provider.dart';
import '../screens/pharmacy/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;
  /// Appele si l'image du produit ne charge pas, pour que le parent
  /// retire ce produit de la liste (evite un emplacement vide).
  final VoidCallback? onImageError;
  const ProductCard({super.key, required this.product, required this.onAddToCart, this.onImageError});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static const _purple = Color(0xFF5F55D7);
  static const _dark = Color(0xFF101522);
  static const _grey = Color(0xFF9B9999);
  bool _fav = false;
  bool _hidden = false;

  void _hideCard() {
    if (_hidden) return;
    _hidden = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onImageError?.call();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    // Aucune image utilisable : ne pas afficher de carte avec icone generique.
    if (_hidden || p.image == null || p.image!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final discount = p.discountPercent;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _image(p),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _fav = !_fav),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
                      ),
                      child: Icon(_fav ? Icons.favorite : Icons.favorite_border, size: 16, color: _fav ? Colors.red : Colors.grey),
                    ),
                  ),
                ),
                if (discount != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                      child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(p.brand, style: const TextStyle(fontSize: 11, color: _grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFFFB020)),
                      const SizedBox(width: 3),
                      Text('${p.rating}', style: const TextStyle(fontSize: 11, color: _dark, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.price.toStringAsFixed(0)} DA', style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w800)),
                            if (p.originalPrice != null)
                              Text('${p.originalPrice!.toStringAsFixed(0)} DA', style: const TextStyle(color: _grey, fontSize: 10, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onAddToCart,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
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

  Widget _image(Product p) {
    final img = p.image!;
    if (img.startsWith('http')) {
      return Image.network(
        img,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, progress) => progress == null
            ? child
            : Container(
                height: 120,
                color: const Color(0xFFF3F4F6),
                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
        errorBuilder: (c, e, s) {
          _hideCard();
          return const SizedBox.shrink();
        },
      );
    }
    return Image.asset(
      img,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) {
        _hideCard();
        return const SizedBox.shrink();
      },
    );
  }
}
