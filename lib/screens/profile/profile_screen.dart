import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_care_provider.dart';
import '../../providers/profile_provider.dart';
import '../medical/medical_record_screen.dart';
import '../premium/premium_screen.dart';
import 'add_post_sheet.dart';
import 'become_pro_sheet.dart';
import 'edit_profile_sheet.dart';
import 'profile_theme.dart';

const _bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

const _medicalCategoryLabels = {
  'allergies': 'Allergies',
  'family_history': 'Antécédents familiaux',
  'diagnoses': 'Diagnostics',
  'treatment': 'Traitement',
  'symptoms': 'Symptômes',
  'lab_tests': 'Analyses',
  'imaging': 'Scanner / Imagerie',
};

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..load(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  void _openEditProfile(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: provider, child: const EditProfileSheet()),
    );
  }

  void _openAddPost(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: provider, child: const AddPostSheet()),
    );
  }

  void _openBecomePro(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => HomeCareProvider()),
        ],
        child: const BecomeProSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    if (profile.isLoading && profile.name.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: ProfileColors.accent));
    }

    return SafeArea(
      child: RefreshIndicator(
        color: ProfileColors.accent,
        onRefresh: profile.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: ProfileColors.card,
                      backgroundImage: (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) ? NetworkImage(profile.photoUrl!) : null,
                      child: (profile.photoUrl == null || profile.photoUrl!.isEmpty) ? const Icon(Icons.person, size: 40, color: ProfileColors.textFaint) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _openEditProfile(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ProfileColors.border)),
                          child: const Icon(Icons.camera_alt_outlined, color: ProfileColors.accent, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(profile.name.isEmpty ? 'Utilisateur' : profile.name, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                ),
                _roleBadge(profile.role),
              ],
            ),
            const SizedBox(height: 6),
            Text(profile.email, style: const TextStyle(color: ProfileColors.textFaint, fontSize: 13)),
            if (profile.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(profile.bio, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 14, height: 1.4)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openEditProfile(context),
                    style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.accent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('Modifier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (profile.isPro) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openAddPost(context),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: ProfileColors.textSecondary), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: const Text('Ajouter publication', textAlign: TextAlign.center, style: TextStyle(color: ProfileColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            if (profile.role == 'prestataire') _prestataireCard(profile) else if (profile.role == 'vendeur') _vendeurCard(profile) else _patientCard(context, profile),
            const SizedBox(height: 20),
            if (profile.isPro) _publicationsSection(context, profile),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFA7474), Color(0xFFFAB474)]), borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Passer à Premium', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Analyse IA · Rappels vaccins · Pro — 300 DA/mois', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: ProfileColors.red),
                label: const Text('Se déconnecter', style: TextStyle(color: ProfileColors.red)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: ProfileColors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final labels = {'prestataire': 'Prestataire', 'vendeur': 'Vendeur', 'medecin': 'Médecin', 'admin': 'Admin'};
    final label = labels[role];
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: ProfileColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: ProfileColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ProfileColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: ProfileColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _patientCard(BuildContext context, ProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Informations médicales',
          children: [
            Row(
              children: [
                const Icon(Icons.bloodtype_outlined, color: ProfileColors.accent, size: 18),
                const SizedBox(width: 8),
                const Text('Groupe sanguin', style: TextStyle(color: ProfileColors.textSecondary, fontSize: 13)),
                const Spacer(),
                DropdownButton<String>(
                  value: profile.bloodType,
                  hint: const Text('—', style: TextStyle(color: ProfileColors.textFaint)),
                  underline: const SizedBox.shrink(),
                  items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: ProfileColors.textPrimary, fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) {
                    if (v != null) profile.updateBloodType(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (profile.medicalCounts.isEmpty)
              const Text('Aucune donnée médicale enregistrée.', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.medicalCounts.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: ProfileColors.border)),
                    child: Text('${_medicalCategoryLabels[e.key] ?? e.key} · ${e.value}', style: const TextStyle(color: ProfileColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordScreen())),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Voir mon dossier médical complet', style: TextStyle(color: ProfileColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: ProfileColors.accent, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _openBecomePro(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ProfileColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: ProfileColors.accent.withValues(alpha: 0.3))),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined, color: ProfileColors.accent, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Devenir un compte Pro', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('Proposez vos services et publiez sur votre page.', style: TextStyle(color: ProfileColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: ProfileColors.accent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _prestataireCard(ProfileProvider profile) {
    final info = profile.providerInfo;
    return _sectionCard(
      title: 'Informations prestataire',
      children: [
        _infoRow(Icons.medical_services_outlined, 'Spécialité', info?.specialty ?? '—'),
        _infoRow(Icons.call_outlined, 'Téléphone', info?.phone ?? '—'),
        _infoRow(Icons.payments_outlined, 'Tarif / visite', info != null ? '${info.pricePerVisit} DA' : '—'),
        _infoRow(Icons.star_outline, 'Note', info != null ? '${info.rating} (${info.reviewCount} avis)' : '—'),
      ],
    );
  }

  Widget _vendeurCard(ProfileProvider profile) {
    return _sectionCard(
      title: 'Informations boutique',
      children: [
        _infoRow(Icons.storefront_outlined, 'Boutique', profile.shopName ?? '—'),
        _infoRow(Icons.call_outlined, 'Téléphone', profile.shopPhone ?? '—'),
        if (profile.shopBio != null && profile.shopBio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(profile.shopBio!, style: const TextStyle(color: ProfileColors.textSecondary, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: ProfileColors.accent, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: ProfileColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _publicationsSection(BuildContext context, ProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Publications', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (profile.posts.isEmpty)
          const Text('Aucune publication. Ajoutez la première !', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12))
        else
          ...profile.posts.map((post) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: ProfileColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: ProfileColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(post.content, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 13))),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: ProfileColors.textFaint, size: 18),
                          onPressed: () => profile.deletePost(post.id),
                        ),
                      ],
                    ),
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(post.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)),
                    ],
                  ],
                ),
              )),
      ],
    );
  }
}
