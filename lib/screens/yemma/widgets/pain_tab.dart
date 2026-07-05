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

    // Données réelles (triées par date croissante), respectent le filtre de zone.
    final entries = List<PainEntry>.from(yemma.filteredPainEntries)..sort((a, b) => a.date.compareTo(b.date));
    final hasData = entries.isNotEmpty;

    // Statistiques calculées dans l'app (gratuit, sans IA).
    final double avg = hasData ? entries.map((e) => e.severity).reduce((a, b) => a + b) / entries.length : 0;

    String trendText = 'Pas assez de données pour une tendance.';
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = YemmaColors.textFaint;
    if (entries.length >= 4) {
      final half = entries.length ~/ 2;
      final firstAvg = entries.sublist(0, half).map((e) => e.severity).reduce((a, b) => a + b) / half;
      final secondAvg = entries.sublist(half).map((e) => e.severity).reduce((a, b) => a + b) / (entries.length - half);
      final diff = secondAvg - firstAvg;
      final pct = firstAvg == 0 ? 0 : (diff.abs() / firstAvg * 100).round();
      if (diff < -0.3) {
        trendText = 'Douleurs en baisse de $pct% récemment';
        trendIcon = Icons.trending_down;
        trendColor = YemmaColors.green;
      } else if (diff > 0.3) {
        trendText = 'Douleurs en hausse de $pct% récemment';
        trendIcon = Icons.trending_up;
        trendColor = YemmaColors.orange;
      } else {
        trendText = 'Douleurs stables récemment';
        trendIcon = Icons.trending_flat;
        trendColor = YemmaColors.blue;
      }
    }

    String topZone = '—';
    if (hasData) {
      final counts = <String, int>{};
      for (final e in entries) {
        counts[e.location] = (counts[e.location] ?? 0) + 1;
      }
      topZone = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

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
                    child: const Icon(Icons.insights_outlined, color: YemmaColors.pink, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Aperçu de mes douleurs', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasData)
                _insightRow(Icons.info_outline, YemmaColors.textFaint, 'Aucune douleur enregistrée pour le moment.')
              else ...[
                _insightRow(Icons.speed, YemmaColors.severityColor(avg.round()), 'Intensité moyenne : ${avg.toStringAsFixed(1)}/10'),
                const SizedBox(height: 10),
                _insightRow(trendIcon, trendColor, trendText),
                const SizedBox(height: 10),
                _insightRow(Icons.my_location, YemmaColors.pink, 'Zone la plus fréquente : $topZone'),
              ],
              const SizedBox(height: 18),
              const Text('Recommandations', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _bullet('Notez vos douleurs régulièrement pour un meilleur suivi'),
              _bullet('Buvez suffisamment d\'eau chaque jour'),
              _bullet('Consultez un médecin si les douleurs persistent'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _painChart(entries),
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
        if (!hasData)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: YemmaColors.border)),
            child: const Text('Aucune douleur enregistrée.', style: TextStyle(color: YemmaColors.textFaint, fontSize: 13)),
          ),
        ...entries.reversed.map((entry) {
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

  Widget _painChart(List<PainEntry> entries) {
    final recent = entries.length > 10 ? entries.sublist(entries.length - 10) : entries;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Intensité (10 derniers jours)', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(child: Text('Ajoutez des douleurs pour voir le graphique.', style: TextStyle(color: YemmaColors.textFaint, fontSize: 13))),
            )
          else
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: recent.map((e) {
                  final color = YemmaColors.severityColor(e.severity);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${e.severity}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            height: 8 + (e.severity / 10) * 110,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${e.date.day}/${e.date.month}', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 9)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
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
