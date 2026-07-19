import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../premium/premium_screen.dart';
import 'add_family_member_sheet.dart';
import 'add_post_sheet.dart';
import 'add_product_sheet.dart';
import 'become_pro_sheet.dart';
import 'edit_profile_sheet.dart';
import 'profile_theme.dart';

const _bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

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

  void _openAddProduct(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: provider, child: const AddProductSheet()),
    );
  }

  void _openAddFamilyMember(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: provider, child: const AddFamilyMemberSheet()),
    );
  }

  Future<void> _editStats(BuildContext context, ProfileProvider profile) async {
    final weightController = TextEditingController(text: profile.weightKg?.toString() ?? '');
    final heightController = TextEditingController(text: profile.heightCm?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Poids & taille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Poids (kg)')),
            const SizedBox(height: 12),
            TextField(controller: heightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Taille (cm)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              profile.updateStats(weightKg: double.tryParse(weightController.text.trim()), heightCm: double.tryParse(heightController.text.trim()));
              Navigator.pop(dialogContext);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _openBecomePro(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: provider, child: const BecomeProSheet()),
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
            if (profile.role == 'prestataire')
              _prestataireCard(profile)
            else if (profile.role == 'vendeur')
              _vendeurCard(context, profile)
            else if (profile.role == 'admin')
              _adminCard()
            else
              _patientCard(context, profile),
            const SizedBox(height: 20),
            if (profile.isPro) _publicationsSection(context, profile),
            const SizedBox(height: 20),
            _settingsSection(context),
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
        Row(
          children: [
            _statBox(profile.weightKg != null ? '${_trim(profile.weightKg!)} kg' : '—', 'Poids', onTap: () => _editStats(context, profile)),
            const SizedBox(width: 10),
            _statBox(profile.heightCm != null ? '${_trim(profile.heightCm!)} cm' : '—', 'Taille', onTap: () => _editStats(context, profile)),
            const SizedBox(width: 10),
            _statBox(profile.bloodType ?? '—', 'Groupe sanguin', onTap: () => _editBloodType(context, profile)),
          ],
        ),
        const SizedBox(height: 16),
        _familyMembersSection(context, profile),
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
                      Text('Débloquez la publication de contenu sur votre page.', style: TextStyle(color: ProfileColors.textSecondary, fontSize: 11)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statBox(info != null ? '${info.pricePerVisit} DA' : '—', 'Tarif / visite'),
            const SizedBox(width: 10),
            _statBox(info != null ? '${info.rating}' : '—', 'Note'),
            const SizedBox(width: 10),
            _statBox(info != null ? '${info.yearsExperience} ans' : '—', 'Expérience'),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Informations prestataire',
          children: [
            _infoRow(Icons.medical_services_outlined, 'Spécialité', info?.specialty ?? '—'),
            _infoRow(Icons.call_outlined, 'Téléphone', info?.phone ?? '—'),
          ],
        ),
      ],
    );
  }

  Widget _adminCard() {
    return _sectionCard(
      title: 'Espace Administrateur',
      children: const [
        Text('Vous gérez les bannières publicitaires, les catégories et le contenu public de MedicaClic.', style: TextStyle(color: ProfileColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _statBox(String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 63,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: ProfileColors.accent, width: 2), borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProfileColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  String _trim(double value) => value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  Future<void> _editBloodType(BuildContext context, ProfileProvider profile) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Groupe sanguin'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bloodTypes.map((t) {
            final active = t == profile.bloodType;
            return GestureDetector(
              onTap: () {
                profile.updateBloodType(t);
                Navigator.pop(dialogContext);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? ProfileColors.accent : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? ProfileColors.accent : ProfileColors.border),
                ),
                child: Text(t, style: TextStyle(color: active ? Colors.white : ProfileColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer'))],
      ),
    );
  }

  Widget _familyMembersSection(BuildContext context, ProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Membres de la famille', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => _openAddFamilyMember(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: ProfileColors.accent, size: 16),
                  SizedBox(width: 2),
                  Text('Ajouter un membre', style: TextStyle(color: ProfileColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (profile.familyMembers.isEmpty)
          const Text('Aucun membre ajouté.', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12))
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.familyMembers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _familyMemberCard(profile, profile.familyMembers[i]),
            ),
          ),
      ],
    );
  }

  Widget _familyMemberCard(ProfileProvider profile, FamilyMember member) {
    final initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';
    return GestureDetector(
      onLongPress: () => profile.deleteFamilyMember(member.id),
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: ProfileColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: ProfileColors.border)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 20, backgroundColor: ProfileColors.accent.withValues(alpha: 0.12), child: Text(initial, style: const TextStyle(color: ProfileColors.accent, fontWeight: FontWeight.bold))),
            const SizedBox(height: 6),
            Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(member.relation, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProfileColors.textFaint, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _vendeurCard(BuildContext context, ProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Informations boutique',
          children: [
            _infoRow(Icons.storefront_outlined, 'Boutique', profile.shopName ?? '—'),
            _infoRow(Icons.call_outlined, 'Téléphone', profile.shopPhone ?? '—'),
            if (profile.shopBio != null && profile.shopBio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(profile.shopBio!, style: const TextStyle(color: ProfileColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _productsSection(context, profile),
        const SizedBox(height: 16),
        _requestsSection(profile),
      ],
    );
  }

  Widget _productsSection(BuildContext context, ProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Mes articles', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => _openAddProduct(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: ProfileColors.accent, size: 16),
                  SizedBox(width: 2),
                  Text('Ajouter un article', style: TextStyle(color: ProfileColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (profile.myProducts.isEmpty)
          const Text('Aucun article publié pour le moment.', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12))
        else
          ...profile.myProducts.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ProfileColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: ProfileColors.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${p.category} · ${p.price.toStringAsFixed(0)} DA', style: const TextStyle(color: ProfileColors.textFaint, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, color: ProfileColors.textFaint, size: 18),
                      onPressed: () => profile.deleteProduct(p.id),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _requestDetailRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: ProfileColors.textFaint),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(color: ProfileColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _requestsSection(ProfileProvider profile) {
    final pending = profile.pendingRequestsCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Demandes reçues', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: ProfileColors.red, borderRadius: BorderRadius.circular(20)),
                child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (profile.myRequests.isEmpty)
          const Text('Aucune demande pour le moment.', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12))
        else
          ...profile.myRequests.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: r.status == 'pending' ? ProfileColors.accent.withValues(alpha: 0.06) : ProfileColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: r.status == 'pending' ? ProfileColors.accent.withValues(alpha: 0.3) : ProfileColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.productName, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _requestDetailRow(Icons.person_outline, r.buyerName.isEmpty ? '—' : r.buyerName),
                    _requestDetailRow(Icons.call_outlined, r.buyerPhone.isEmpty ? '—' : r.buyerPhone),
                    if (r.buyerAddress.isNotEmpty) _requestDetailRow(Icons.location_on_outlined, r.buyerAddress),
                    if (r.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.message, style: const TextStyle(color: ProfileColors.textFaint, fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 8),
                    if (r.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => profile.respondToRequest(r.id, accept: false),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: ProfileColors.red), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: const Text('Refuser', style: TextStyle(color: ProfileColors.red, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => profile.respondToRequest(r.id, accept: true),
                              style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.accent, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: const Text('Accepter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      )
                    else if (r.status == 'declined')
                      const Text('✕ Refusée', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12, fontWeight: FontWeight.w600))
                    else
                      Row(
                        children: [
                          const Expanded(child: Text('✓ Acceptée', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600))),
                          if (r.paymentReceived)
                            const Text('💰 Paiement reçu', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600))
                          else
                            OutlinedButton(
                              onPressed: () => profile.markPaymentReceived(r.id),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: ProfileColors.accent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: const Text('Marquer payé', style: TextStyle(color: ProfileColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                  ],
                ),
              )),
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

  Widget _settingsSection(BuildContext context) {
    return _sectionCard(
      title: 'Paramètres',
      children: [
        _settingsRow(context, Icons.language_outlined, 'Langue'),
        const Divider(height: 20, color: ProfileColors.border),
        _settingsRow(context, Icons.security_outlined, 'Sécurité'),
        const Divider(height: 20, color: ProfileColors.border),
        _settingsRow(context, Icons.accessibility_new_outlined, 'Accessibilité'),
      ],
    );
  }

  Widget _settingsRow(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label — bientôt disponible'))),
      child: Row(
        children: [
          Icon(icon, color: ProfileColors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: ProfileColors.textFaint, size: 18),
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
