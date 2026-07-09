import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/delivery_service.dart';

class DeliveryAnalyticsPage extends StatefulWidget {
  const DeliveryAnalyticsPage({super.key});
  @override
  State<DeliveryAnalyticsPage> createState() => _DeliveryAnalyticsPageState();
}

class _DeliveryAnalyticsPageState extends State<DeliveryAnalyticsPage>
    with SingleTickerProviderStateMixin {
  static const _bg    = Color(0xFF07080F);
  static const _card  = Color(0xFF0D0F1E);
  static const _bord  = Color(0xFF1C1F35);
  static const _acc   = Color(0xFF4F8EFF);
  static const _green = Color(0xFF10E8B0);
  static const _gold  = Color(0xFFFFB800);
  static const _red   = Color(0xFFF04040);
  static const _purp  = Color(0xFF9B6CF7);

  late TabController _tabs;
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String _period = '7d';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await DeliveryService.instance.adminDeliveryStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(child: Column(children: [
      _topBar(),
      _periodSelector(),
      Container(
        color: _card,
        child: TabBar(
          controller: _tabs,
          labelColor: _acc,
          unselectedLabelColor: Colors.white38,
          indicatorColor: _acc, indicatorWeight: 2,
          dividerColor: _bord,
          labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
          tabs: const [Tab(text: 'Aperçu'), Tab(text: 'Délais'), Tab(text: 'Taux')],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
          : TabBarView(controller: _tabs, children: [
              _overviewTab(),
              _delaysTab(),
              _ratesTab(),
            ])),
    ])),
  );

  Widget _topBar() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text('Analytiques Livraison', style: GoogleFonts.montserrat(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
      GestureDetector(
        onTap: _load,
        child: Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: _bord, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
      ),
    ]),
  );

  Widget _periodSelector() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(children: [
      for (final p in [('7d', '7 jours'), ('30d', '30 jours'), ('90d', '3 mois')])
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() { _period = p.$1; _load(); }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _period == p.$1 ? _acc.withValues(alpha: 0.15) : _bord.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _period == p.$1 ? _acc : _bord),
              ),
              child: Text(p.$2, style: GoogleFonts.montserrat(
                  color: _period == p.$1 ? _acc : Colors.white38,
                  fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
    ]),
  );

  Widget _overviewTab() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
    _sectionLabel('📦 Volume de colis'),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _statCard('Colis total', '${_stats['total_parcels'] ?? 0}', _acc, Icons.inventory_2_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Livrés', '${_stats['delivered'] ?? 0}', _green, Icons.done_all_rounded)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _statCard('En cours', '${_stats['in_progress'] ?? 0}', _gold, Icons.local_shipping_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Retournés', '${_stats['returned'] ?? 0}', _red, Icons.keyboard_return_rounded)),
    ]),
    const SizedBox(height: 24),
    _sectionLabel('💰 Revenus'),
    const SizedBox(height: 12),
    _wideStatCard('Économies réalisées (Smart)',
        '${_stats['smart_savings_dzd'] ?? 0} DA', _purp, Icons.savings_rounded),
    const SizedBox(height: 10),
    _wideStatCard('Frais totaux payés', '${_stats['total_fees_dzd'] ?? 0} DA', _acc, Icons.receipt_long_rounded),
    const SizedBox(height: 24),
    _sectionLabel('📊 Smart Delivery'),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _statCard('Groupes', '${_stats['smart_groups'] ?? 0}', _acc, Icons.group_work_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Items Smart', '${_stats['smart_items'] ?? 0}', _purp, Icons.bolt_rounded)),
    ]),
    const SizedBox(height: 24),
    _barChart(),
  ]);

  Widget _delaysTab() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
    _sectionLabel('⏱ Temps moyens'),
    const SizedBox(height: 12),
    _delayRow('Préparation', _stats['avg_prep_hours']?.toString() ?? '—', 'heures', _gold, 0.6),
    const SizedBox(height: 10),
    _delayRow('Ramassage → Dépôt', _stats['avg_pickup_hours']?.toString() ?? '—', 'heures', _acc, 0.4),
    const SizedBox(height: 10),
    _delayRow('Transit', _stats['avg_transit_hours']?.toString() ?? '—', 'heures', _purp, 0.7),
    const SizedBox(height: 10),
    _delayRow('Livraison finale', _stats['avg_delivery_hours']?.toString() ?? '—', 'heures', _green, 0.85),
    const SizedBox(height: 24),
    _sectionLabel('⚠️ Retards détectés'),
    const SizedBox(height: 12),
    ...[
      ('Confirmation Smart expirée', '${_stats['expired_confirmations'] ?? 0}', _gold),
      ('Ramassage manqué', '${_stats['missed_pickups'] ?? 0}', _red),
      ('Livraison échouée', '${_stats['failed_deliveries'] ?? 0}', _red),
    ].map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _alertRow(e.$1, e.$2, e.$3),
    )),
  ]);

  Widget _ratesTab() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
    _sectionLabel('📈 Taux de performance'),
    const SizedBox(height: 16),
    _rateGauge('Taux de confirmation Smart', _stats['confirmation_rate'] ?? 0.0, _green),
    const SizedBox(height: 16),
    _rateGauge('Taux de livraison réussie', _stats['delivery_success_rate'] ?? 0.0, _acc),
    const SizedBox(height: 16),
    _rateGauge('Taux de satisfaction', _stats['satisfaction_rate'] ?? 0.0, _purp),
    const SizedBox(height: 16),
    _rateGauge('Taux de retour', _stats['return_rate'] ?? 0.0, _red),
    const SizedBox(height: 24),
    _sectionLabel('🏆 Performance globale'),
    const SizedBox(height: 12),
    _scoreCard(),
  ]);

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.montserrat(
      color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4));

  Widget _statCard(String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bord)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 12),
      Text(value, style: GoogleFonts.montserrat(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
    ]),
  );

  Widget _wideStatCard(String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ])),
    ]),
  );

  Widget _delayRow(String label, String value, String unit, Color color, double fraction) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(13), border: Border.all(color: _bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12))),
          Text('$value $unit', style: GoogleFonts.montserrat(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: _bord,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ]),
    );

  Widget _alertRow(String label, String count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.15))),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12))),
      Text(count, style: GoogleFonts.montserrat(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
    ]),
  );

  Widget _rateGauge(String label, double rate, Color color) {
    final pct = (rate * 100).clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700))),
          Text('${pct.toStringAsFixed(1)}%',
              style: GoogleFonts.montserrat(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          Container(height: 8, decoration: BoxDecoration(color: _bord, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(
            widthFactor: pct / 100,
            child: Container(height: 8, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
              borderRadius: BorderRadius.circular(4),
            )),
          ),
        ]),
      ]),
    );
  }

  Widget _scoreCard() {
    final score = (_stats['global_score'] as num?)?.toDouble() ?? 0.0;
    final (label, color) = score >= 80
        ? ('Excellent', _green) : score >= 60
        ? ('Bon', _acc) : score >= 40
        ? ('Moyen', _gold)
        : ('À améliorer', _red);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.08), _card],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(width: 64, height: 64,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Center(child: Text(score.toStringAsFixed(0),
              style: GoogleFonts.montserrat(color: color, fontSize: 20, fontWeight: FontWeight.w900)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Score global', style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11)),
          Text(label, style: GoogleFonts.montserrat(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          Text('Sur 100 points', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _barChart() {
    final days = _stats['daily_parcels'] as List<dynamic>? ?? [];
    if (days.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _bord)),
        child: Center(child: Text('Pas de données graphique', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12))),
      );
    }
    final maxVal = days.map((e) => (e['count'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Colis par jour', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 80, child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.take(7).map((e) {
            final cnt = (e['count'] as num?)?.toDouble() ?? 0.0;
            final h = maxVal > 0 ? (cnt / maxVal) : 0.0;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(height: 70 * h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [_acc, _acc.withValues(alpha: 0.5)]),
                      borderRadius: BorderRadius.circular(4),
                    )),
                const SizedBox(height: 4),
                Text('${e['day'] ?? ''}', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 8)),
              ]),
            ));
          }).toList(),
        )),
      ]),
    );
  }
}
