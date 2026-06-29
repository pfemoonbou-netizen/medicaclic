import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Panier'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home'))),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.lightGray), const SizedBox(height: 20), Text('Votre panier est vide', style: AppTextStyles.heading3)]));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, i) {
                    final item = cart.items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(item.image ?? 'RX', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: AppTextStyles.heading3), Text('\$${item.price.toStringAsFixed(2)}', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold))])),
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.updateQuantity(item.id, item.quantity - 1)),
                            Text('${item.quantity}', style: AppTextStyles.body),
                            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.updateQuantity(item.id, item.quantity + 1)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: AppTextStyles.heading2), Text('\$${(cart.total * 1.1).toStringAsFixed(2)}', style: AppTextStyles.heading2.copyWith(color: AppColors.primary))]),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
                      cart.clearCart();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement reussi')));
                      context.go('/home');
                    }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('Payer', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
