import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/yemma_provider.dart';
import '../yemma_theme.dart';

const _kMonths = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
String formatFrDate(DateTime d) => '${d.day} ${_kMonths[d.month - 1]} ${d.year}';

class PainTab extends StatelessWidget {
  const PainTab({super.key});

  @override
  Widget build(BuildContext context) {
    final yemma = context.watch<YemmaProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.psychology_outlined, color: YemmaColors.pink, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Analyse IA', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: YemmaColors.pink, borderRadius: BorderRadius.circular(20)),
                    child: const Text('IA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _insightRow(Icons.trending_down, YemmaColors.green, 'Douleurs en diminution de 40% cette semaine'),
              const SizedBox(height: 10),
              _insightRow(Icons.warning_amber_rounded, YemmaColors.orange, 'Jeudi 9/10 — possible fatigue accumulée'),
              const SizedBox(height: 10),
              _insightRow(Icons.wb_sunny_outlined, YemmaColors.orange, 'Dimanche — journée la plus confortable'),
              const SizedBox(height: 18),
              const Text('Recommandations', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _bullet('Reposez-vous les jeudis'),
              _bullet('Buvez 2L d\'eau par jour'),
              _bullet('Consultez votre gynécologue'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Historique des douleurs', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: YemmaColors.pink),
              label: const Text('Exporter PDF', style: TextStyle(color: YemmaColors.pink, fontSize: 12)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: YemmaColors.pink), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: yemma.painFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final filter = yemma.painFilters[i];
              final active = filter == yemma.painFilter;
              return GestureDetector(
                onTap: () => yemma.setPainFilter(filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? YemmaColors.pink.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? YemmaColors.pink : YemmaColors.border),
                  ),
                  child: Text(filter, style: TextStyle(color: active ? YemmaColors.pink : YemmaColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ...yemma.filteredPainEntries.map((entry) {
          final color = YemmaColors.severityColor(entry.severity);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: YemmaColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatFrDate(entry.date), style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${entry.location} — ${entry.type} — ${entry.duration}', style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
                  child: Text('${entry.severity}/10', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _insightRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 13, height: 1.3))),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: YemmaColors.pink)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
