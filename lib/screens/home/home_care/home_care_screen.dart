import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pharmacy/boutique_theme.dart';
import '../../../providers/home_care_provider.dart';
import 'provider_list_screen.dart';

class HomeCareScreen extends StatefulWidget {
  const HomeCareScreen({super.key});
  @override
  State<HomeCareScreen> createState() => _HomeCareScreenState();
}

class _HomeCareScreenState extends State<HomeCareScreen> {
  bool _howItWorksExpanded = false;

  static const _steps = [
    (icon: Icons.touch_app_outlined, title: 'Choisissez votre besoin', desc: 'Sélectionnez le type de soin : médecin, infirmier, kiné, garde malade...'),
    (icon: Icons.person_search_outlined, title: 'Trouvez un prestataire', desc: 'Consultez les profils disponibles avec notes, tarifs et spécialités.'),
    (icon: Icons.call_outlined, title: 'Contactez & réservez', desc: 'Appelez, envoyez un message ou réservez en ligne en quelques secondes.'),
    (icon: Icons.home_outlined, title: 'Reçu à votre adresse', desc: 'Le professionnel arrive chez vous au créneau choisi. Payez à la visite.'),
  ];

  @override
  Widget build(BuildContext context) {
    final homeCare = context.watch<HomeCareProvider>();

    return Scaffold(
      backgroundColor: BoutiqueColors.background,
      appBar: AppBar(
        backgroundColor: BoutiqueColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: BoutiqueColors.textPrimary),
        title: const Text('Services à Domicile', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 17)),
      ),
      body: homeCare.isLoading && homeCare.categories.isEmpty
          ? const Center(child: CircularProgressIndicator(color: BoutiqueColors.accent))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: BoutiqueColors.accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('3 prestataires disponibles maintenant', style: TextStyle(color: BoutiqueColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Services à Domicile', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Médecins, Infirmiers, Kinés — chez vous en 15-45 min', style: TextStyle(color: BoutiqueColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          const Text('Services', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _QuickServiceTile(icon: Icons.medical_services_outlined, label: 'Visite\nmédecin')),
              SizedBox(width: 12),
              Expanded(child: _QuickServiceTile(icon: Icons.healing_outlined, label: 'Soins\ninfirmiers')),
              SizedBox(width: 12),
              Expanded(child: _QuickServiceTile(icon: Icons.favorite_border, label: 'Garde\nmalade')),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BoutiqueColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _StatItem(value: '120+', label: 'Prestataires'),
                _StatDivider(),
                _StatItem(value: '4.8', label: 'Note moy.'),
                _StatDivider(),
                _StatItem(value: '15 min', label: 'Arrivée moy.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BoutiqueColors.border)),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _howItWorksExpanded = !_howItWorksExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: BoutiqueColors.accent, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Comment ça marche ?', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('4 étapes simples pour recevoir un soin', style: TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(_howItWorksExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: BoutiqueColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                if (_howItWorksExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(color: BoutiqueColors.border, height: 1),
                        const SizedBox(height: 12),
                        for (final step in _steps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: BoutiqueColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: Icon(step.icon, color: BoutiqueColors.accent, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(step.title, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(step.desc, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 12, height: 1.3)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('De quoi avez-vous besoin ?', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.45, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: homeCare.categories.length,
            itemBuilder: (context, i) {
              final cat = homeCare.categories[i];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderListScreen(initialCategoryId: cat.id))),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: BoutiqueColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                        child: Icon(cat.icon, color: cat.color, size: 18),
                      ),
                      const Spacer(),
                      Text(cat.name, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(cat.subtitle, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text('dès ${cat.priceFrom} DA', style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: BoutiqueColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: BoutiqueColors.border);
}

/// Tuile bleue arrondie de raccourci vers un type de service (style
/// maquette : fond bleu, icone blanche, libelle en bas).
class _QuickServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickServiceTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF3E69FE), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const Spacer(),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.1)),
        ],
      ),
    );
  }
}
