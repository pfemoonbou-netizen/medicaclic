import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({Key? key}) : super(key: key);

  // Dégradé vert de la maquette
  static const Color _greenTop = Color(0xFF2E7D6B);
  static const Color _greenBottom = Color(0xFF1E6B57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Vague verte en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_greenTop, _greenBottom],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Bienvenue 👋',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101522),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisissez votre type de compte',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF7A8290)),
                  ),
                  const Spacer(),
                  _TypeButton(
                    label: 'Médecin',
                    icon: Icons.medical_services_outlined,
                    onTap: () => context.go('/complete-profile', extra: 'medecin'),
                  ),
                  const SizedBox(height: 20),
                  _TypeButton(
                    label: 'Patient',
                    icon: Icons.person_outline,
                    onTap: () => context.go('/complete-profile', extra: 'patient'),
                  ),
                  const SizedBox(height: 20),
                  _TypeButton(
                    label: 'Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => context.go('/complete-profile', extra: 'admin'),
                  ),
                  const SizedBox(height: 20),
                  _TypeButton(
                    label: 'Vendeur',
                    icon: Icons.storefront_outlined,
                    onTap: () => context.go('/complete-profile', extra: 'vendeur'),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3A8C77), Color(0xFF2E7D6B)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D6B).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vague douce en haut du bloc vert du bas
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 60);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 30);
    path.quadraticBezierTo(size.width * 0.75, 60, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
