import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101522)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/signup'),
        ),
        title: const Text(
          'Sélectionner votre type',
          style: TextStyle(color: Color(0xFF101522), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quel est votre\ntype de compte?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF101522)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez le type de compte qui vous convient le mieux.',
                style: TextStyle(color: Color(0xFFA0A7B0), fontSize: 16),
              ),
              const SizedBox(height: 32),
              _TypeCard(
                icon: Icons.shopping_cart,
                title: 'Acheteur',
                description: 'Parcourez et achetez des produits et services',
                onTap: () => context.go('/complete-profile', extra: 'utilisateur'),
              ),
              const SizedBox(height: 16),
              _TypeCard(
                icon: Icons.store,
                title: 'Vendeur',
                description: 'Vendez vos produits et services',
                onTap: () => context.go('/complete-profile', extra: 'vendeur'),
              ),
              const SizedBox(height: 16),
              _TypeCard(
                icon: Icons.edit,
                title: 'Créateur de contenu',
                description: 'Partagez votre expertise et créez du contenu',
                onTap: () => context.go('/complete-profile', extra: 'createur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF101522),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFA0A7B0),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
