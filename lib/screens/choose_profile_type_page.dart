import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../widgets/primary_button.dart';

class ChooseProfileTypePage extends StatefulWidget {
  const ChooseProfileTypePage({super.key});

  @override
  State<ChooseProfileTypePage> createState() => _ChooseProfileTypePageState();
}

class _ChooseProfileTypePageState extends State<ChooseProfileTypePage> {
  String? _selected;

  static const _roles = [
    _Role(
      id: 'buyer',
      icon: Icons.shopping_bag_outlined,
      title: 'Acheteur',
      subtitle: 'Découvrir & acheter',
      features: ['Feed social personnalisé', 'Achats & panier', 'Favoris & suivi commande', 'Avis & notation'],
      color: Color(0xFF347EFB),
    ),
    _Role(
      id: 'seller',
      icon: Icons.storefront_outlined,
      title: 'Vendeur / Boutique',
      subtitle: 'Vendre des produits',
      features: ['Boutique en ligne', 'Posts, Stories, Reels', 'Dashboard & statistiques', 'Gestion livraisons'],
      color: Color(0xFF6E1128),
    ),
    _Role(
      id: 'company',
      icon: Icons.business_outlined,
      title: 'Entreprise',
      subtitle: 'Marque officielle',
      features: ['Tout Vendeur +', 'Badge officiel vérifié', 'Campagnes publicitaires', 'Analytics avancés'],
      color: Color(0xFF292526),
    ),
    _Role(
      id: 'creator',
      icon: Icons.videocam_outlined,
      title: 'Créateur',
      subtitle: 'Publier du contenu',
      features: ['Posts, Reels, Stories', 'Produits affiliés taggés', 'Monétisation & wallet', 'Badge créateur'],
      color: Color(0xFF7B1FA2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quel type de compte\nsouhaitez-vous ?',
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: AppColors.nearBlack,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vous pourrez ajouter ou changer de rôle plus tard.',
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: AppColors.gray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _roles.length,
                itemBuilder: (_, i) => _roleCard(_roles[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: PrimaryButton(
                label: 'Continuer',
                onPressed: _selected == null
                    ? null
                    : () {
                        final route = switch (_selected) {
                          'buyer' => '/complete-buyer',
                          'seller' => '/complete-seller',
                          'company' => '/complete-company',
                          'creator' => '/complete-creator',
                          _ => '/feed',
                        };
                        Navigator.pushNamed(context, route);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(_Role role) {
    final selected = _selected == role.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = role.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? role.color.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            color: selected ? role.color : Colors.transparent,
            width: selected ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  const BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: selected
                    ? role.color.withValues(alpha: 0.15)
                    : role.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(role.icon, color: role.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.title,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(role.subtitle,
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 12)),
                  const SizedBox(height: 10),
                  ...role.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: role.color),
                        const SizedBox(width: 6),
                        Text(f,
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: selected ? role.color : Colors.transparent,
                border: Border.all(
                    color: selected ? role.color : AppColors.lightGray,
                    width: 2),
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Role {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final Color color;
  const _Role({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.color,
  });
}
