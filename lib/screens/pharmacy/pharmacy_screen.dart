import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  static const _purple = Color(0xFF5F55D7);
  static const _dark = Color(0xFF101522);
  static const _bg = Color(0xFFF7F8FA);

  String _category = 'Tout';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final row = await supabase.from('profiles').select('name').eq('id', uid).maybeSingle();
      final n = (row?['name'] as String?)?.trim();
      if (mounted && n != null && n.isNotEmpty) setState(() => _name = n);
    } catch (_) {}
  }

  void _add(Product p) {
    context.read<CartProvider>().addToCart(CartItem(id: p.id, name: p.name, price: p.price, image: p.image));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} ajouté au panier'), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.byCategory(_category);
    final featured = provider.featured;

    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _searchBar(),
                  const SizedBox(height: 18),
                  _promoBanner(provider),
                  const SizedBox(height: 22),
                  if (featured.isNotEmpty) ...[
                    _sectionHeader('En vedette'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => SizedBox(width: 165, child: ProductCard(product: featured[i], onAddToCart: () => _add(featured[i]))),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _categoryChips(provider),
                  const SizedBox(height: 16),
                  _sectionHeader('Tous les produits'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.66, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: products.length,
                    itemBuilder: (context, i) => ProductCard(product: products[i], onAddToCart: () => _add(products[i])),
                  ),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('Aucun produit dans cette catégorie.', style: TextStyle(color: Colors.grey))),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    final display = _name.isEmpty ? 'Bienvenue' : _name;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: _purple.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.person, color: _purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bonjour 👋', style: TextStyle(color: Color(0xFF9B9999), fontSize: 13)),
              Text(display, style: const TextStyle(color: _dark, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/cart'),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart_outlined, color: _dark, size: 22),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Consumer<CartProvider>(
                builder: (context, cart, _) => cart.itemCount == 0
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.search, size: 20, color: Color(0xFF9B9999)),
          SizedBox(width: 10),
          Text('Rechercher un produit...', style: TextStyle(color: Color(0xFF9B9999), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _promoBanner(ProductProvider provider) {
    final offer = provider.promoOffers.isNotEmpty ? provider.promoOffers.first : null;
    final title = offer?.title ?? 'Offre spéciale';
    final discount = offer?.discountText ?? '-20% Orthopédie';
    final sub = offer?.deliveryText ?? 'Livraison partout en Algérie';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C5FE0), Color(0xFF5147C4)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(discount, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.bold)),
        const Text('Voir tout', style: TextStyle(color: _purple, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _categoryChips(ProductProvider provider) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = provider.categories[i];
          final active = cat == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _purple : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(cat, style: TextStyle(color: active ? Colors.white : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}
