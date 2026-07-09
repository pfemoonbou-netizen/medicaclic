import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../models/app_user.dart';
import '../services/user_session.dart';

/// Dismissible bottom sheet that lets the user choose a pro role.
///
/// - Acheteur  → immediate access, onboardingComplete = true
/// - Vendeur / Créateur / Entreprise → navigates to the completion form,
///   proStatus = incomplete until the form is submitted
///
/// Also exposes a persistent [ProOnboardingCta] banner for the feed.
class ProOnboardingSheet extends StatelessWidget {
  const ProOnboardingSheet._();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const ProOnboardingSheet._(),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Compléter mon profil',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Choisissez votre type de compte pour débloquer plus de fonctionnalités.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _RoleOption(
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFF347EFB),
              title: 'Acheteur',
              subtitle: 'Accédez à toutes les boutiques et achetez facilement',
              onTap: () => _pick(context, ProRole.buyer),
            ),
            const SizedBox(height: 10),
            _RoleOption(
              icon: Icons.storefront_outlined,
              color: AppColors.accent,
              title: 'Vendeur',
              subtitle: 'Créez votre boutique et gérez vos produits',
              onTap: () => _pick(context, ProRole.seller),
            ),
            const SizedBox(height: 10),
            _RoleOption(
              icon: Icons.videocam_outlined,
              color: const Color(0xFF7B1FA2),
              title: 'Créateur',
              subtitle: 'Publiez du contenu et développez votre audience',
              onTap: () => _pick(context, ProRole.creator),
            ),
            const SizedBox(height: 10),
            _RoleOption(
              icon: Icons.business_outlined,
              color: const Color(0xFF1B5E20),
              title: 'Entreprise',
              subtitle: 'Lancez des campagnes publicitaires et gérez votre marque',
              onTap: () => _pick(context, ProRole.company),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Pas maintenant',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ProRole role) async {
    Navigator.pop(context);
    await UserSession.instance.selectProRole(role);
    if (!context.mounted) return;

    switch (role) {
      case ProRole.buyer:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil acheteur activé — bienvenue sur LINCOO 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case ProRole.seller:
        Navigator.pushNamed(context, '/complete-seller');
      case ProRole.creator:
        Navigator.pushNamed(context, '/complete-creator');
      case ProRole.company:
        Navigator.pushNamed(context, '/complete-company');
      case ProRole.none:
        break;
    }
  }
}

// ── Persistent CTA banner (shown in feed when !onboardingComplete) ─────────────

class ProOnboardingCta extends StatelessWidget {
  const ProOnboardingCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () => ProOnboardingSheet.show(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF292526), Color(0xFF6E1128)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Compléter mon profil',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Débloquez vendeur, créateur ou entreprise',
                    style: GoogleFonts.montserrat(
                        color: Colors.white60, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Private role option tile ───────────────────────────────────────────────────

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11, height: 1.3)),
            ]),
          ),
          Icon(Icons.chevron_right, color: color, size: 20),
        ]),
      ),
    );
  }
}
