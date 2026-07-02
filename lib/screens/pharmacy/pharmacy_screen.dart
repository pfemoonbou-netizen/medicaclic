import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import 'boutique_theme.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  String _category = 'Tout';

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.byCategory(_category);

    return Container(
      color: BoutiqueColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Boutique Médicale', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Achat & location · Livraison Algérie', style: TextStyle(color: BoutiqueColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/cart'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: BoutiqueColors.accent.withValues(alpha: 0.18), shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_cart, color: BoutiqueColors.accent, size: 22),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Consumer<CartProvider>(
                          builder: (context, cart, _) => cart.itemCount == 0
                              ? const SizedBox.shrink()
                              : Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: BoutiqueColors.red, shape: BoxShape.circle),
                                  child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: BoutiqueColors.border)),
                    child: const Row(
                      children: [
                        Icon(Icons.search, size: 18, color: BoutiqueColors.textFaint),
                        SizedBox(width: 10),
                        Expanded(child: Text('Rechercher un équipement, médicament...', style: TextStyle(color: BoutiqueColors.textFaint, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.campaign, size: 16, color: BoutiqueColors.orange),
                      SizedBox(width: 6),
                      Text('Offres partenaires', style: TextStyle(color: BoutiqueColors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 168,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: productProvider.promoOffers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final offer = productProvider.promoOffers[i];
                        return Container(
                          width: 260,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: offer.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: offer.color.withValues(alpha: 0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(offer.title, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: offer.color, borderRadius: BorderRadius.circular(20)),
                                    child: const Text('★ SPONSORISÉ', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(offer.discountText, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(offer.deliveryText, style: const TextStyle(color: BoutiqueColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: offer.color, borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Voir Plus', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: productProvider.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = productProvider.categories[i];
                        final active = cat == _category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? BoutiqueColors.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: active ? BoutiqueColors.accent : BoutiqueColors.border),
                            ),
                            child: Text(cat, style: TextStyle(color: active ? Colors.white : BoutiqueColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return ProductCard(
                        product: p,
                        onAddToCart: () {
                          context.read<CartProvider>().addToCart(CartItem(id: p.id, name: p.name, price: p.price, image: p.image));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} ajouté au panier'), duration: const Duration(seconds: 1)));
                        },
                      );
                    },
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
