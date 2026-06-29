import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../pharmacy/boutique_theme.dart';
import '../../../providers/home_care_provider.dart';
import 'booking_sheet.dart';

class ProviderListScreen extends StatefulWidget {
  final String initialCategoryId;
  const ProviderListScreen({super.key, required this.initialCategoryId});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  late String _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

  void _book(BuildContext context, CareProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => BookingSheet(provider: provider),
    );
  }

  void _call(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));
  void _whatsapp(String phone) => launchUrl(Uri.parse('https://wa.me/213${phone.substring(1)}'));

  @override
  Widget build(BuildContext context) {
    final homeCare = context.watch<HomeCareProvider>();
    final providers = homeCare.providersFor(_categoryId);
    final category = _categoryId == 'tous' ? null : homeCare.categoryById(_categoryId);

    return Scaffold(
      backgroundColor: BoutiqueColors.background,
      appBar: AppBar(
        backgroundColor: BoutiqueColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: BoutiqueColors.textPrimary),
        title: const Text('Services à Domicile', style: TextStyle(color: BoutiqueColors.textPrimary, fontSize: 17)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: homeCare.categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isAll = i == 0;
                final cat = isAll ? null : homeCare.categories[i - 1];
                final active = isAll ? _categoryId == 'tous' : cat!.id == _categoryId;
                final color = isAll ? BoutiqueColors.accent : cat!.color;
                return GestureDetector(
                  onTap: () => setState(() => _categoryId = isAll ? 'tous' : cat!.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? color : BoutiqueColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isAll ? Icons.apps : cat!.icon, size: 14, color: active ? color : BoutiqueColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(isAll ? 'Tous' : cat!.name, style: TextStyle(color: active ? color : BoutiqueColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: providers.isEmpty
                ? Center(child: Text('Aucun prestataire pour "${category?.name ?? 'Tous'}" pour le moment.', style: const TextStyle(color: BoutiqueColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: providers.length,
                    itemBuilder: (context, i) => _ProviderCard(provider: providers[i], onCall: _call, onWhatsapp: _whatsapp, onBook: () => _book(context, providers[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final CareProvider provider;
  final void Function(String) onCall;
  final void Function(String) onWhatsapp;
  final VoidCallback onBook;
  const _ProviderCard({required this.provider, required this.onCall, required this.onWhatsapp, required this.onBook});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: BoutiqueColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BoutiqueColors.border)),
            child: _buildCardContent(p),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    Positioned(
                      right: -32,
                      top: 12,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 120,
                          alignment: Alignment.center,
                          color: p.available ? BoutiqueColors.green : BoutiqueColors.muted,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            p.available ? 'Disponible' : 'Indisponible',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(CareProvider p) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.network(
                  p.photoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 28,
                    backgroundColor: BoutiqueColors.accent.withValues(alpha: 0.15),
                    child: Text(p.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join(), style: const TextStyle(color: BoutiqueColors.accent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: BoutiqueColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(p.specialty, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: BoutiqueColors.orange),
                        const SizedBox(width: 3),
                        Text('${p.rating} (${p.reviewCount} avis)', style: const TextStyle(color: BoutiqueColors.textSecondary, fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 13, color: BoutiqueColors.textFaint),
                        Text(' ${p.distanceKm} km', style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${p.pricePerVisit}', style: const TextStyle(color: BoutiqueColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('DA/visite', style: TextStyle(color: BoutiqueColors.textFaint, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill(Icons.access_time, p.etaRange),
              const SizedBox(width: 8),
              _pill(Icons.workspace_premium_outlined, '${p.yearsExperience} ans'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: p.available ? BoutiqueColors.green : BoutiqueColors.muted, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: p.tags.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: BoutiqueColors.border)), child: Text(t, style: const TextStyle(color: BoutiqueColors.textSecondary, fontSize: 11)))).toList()),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_expanded ? 'Voir moins' : 'Voir plus (tarifs, contacts, avis)', style: const TextStyle(color: BoutiqueColors.accent, fontSize: 12)),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: BoutiqueColors.accent),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text('Adresse : ${p.address}', style: const TextStyle(color: BoutiqueColors.textSecondary, fontSize: 12)),
            Text('Téléphone : ${p.phone}', style: const TextStyle(color: BoutiqueColors.textSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onCall(p.phone),
                  icon: const Icon(Icons.call, size: 16, color: BoutiqueColors.accent),
                  label: const Text('Appeler', style: TextStyle(color: BoutiqueColors.accent, fontSize: 12)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: BoutiqueColors.accent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onWhatsapp(p.phone),
                  icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                  label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: p.available ? widget.onBook : null,
                  style: ElevatedButton.styleFrom(backgroundColor: BoutiqueColors.accent, disabledBackgroundColor: BoutiqueColors.border, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Réserver', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: BoutiqueColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: BoutiqueColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: BoutiqueColors.textFaint),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: BoutiqueColors.textFaint, fontSize: 11)),
        ],
      ),
    );
  }
}
