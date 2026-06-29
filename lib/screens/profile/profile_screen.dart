import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                const CircleAvatar(radius: 32, backgroundColor: AppColors.secondary, child: Icon(Icons.person, color: AppColors.primary, size: 32)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Utilisateur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(user?.email ?? '', style: const TextStyle(color: AppColors.lightGray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: const Text('Se déconnecter', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
