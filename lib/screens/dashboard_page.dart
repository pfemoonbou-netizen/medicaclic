import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/pack_service.dart';
import '../widgets/app_bottom_nav.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  SellerPack? _pack;
  bool _loadingPack = true;

  List<_RecentOrder> _recentOrdersList = [];
  bool _loadingOrders = true;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _loadPack();
    _loadRecentOrders();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadPack() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { setState(() => _loadingPack = false); return; }
    final pack = await PackService.instance.load(uid);
    if (mounted) setState(() { _pack = pack; _loadingPack = false; });
  }

  Future<void> _loadRecentOrders() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loadingOrders = false);
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('seller_id', uid)
          .order('created_at', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() {
          _recentOrdersList = (rows as List)
              .map((r) => _RecentOrder.fromRow(Map<String, dynamic>.from(r)))
              .toList();
          _loadingOrders = false;
        });
      }
      _subscribeOrders(uid);
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _subscribeOrders(String sellerId) {
    _ordersChannel?.unsubscribe();
    _ordersChannel = Supabase.instance.client
        .channel('dashboard-orders-$sellerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'seller_id',
              value: sellerId),
          callback: (_) => _loadRecentOrders(),
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_loadingPack) _packBanner(),
                const SizedBox(height: 12),
                _statsRow(),
                const SizedBox(height: 16),
                _revenueCard(),
                const SizedBox(height: 16),
                _sectionTitle('Meilleures ventes'),
                const SizedBox(height: 10),
                _topProducts(),
                const SizedBox(height: 16),
                _sectionTitle('Commandes récentes'),
                const SizedBox(height: 10),
                _recentOrders(context),
                const SizedBox(height: 16),
                _deliveryStats(),
                const SizedBox(height: 16),
                if (_pack?.hasAdvancedStats == true) ...[
                  _sectionTitle('Delivery Analytics'),
                  const SizedBox(height: 10),
                  _deliveryAnalytics(),
                ] else ...[
                  _lockedSection(
                    icon: Icons.bar_chart_rounded,
                    title: 'Delivery Analytics',
                    desc: 'Disponible avec le pack Pro',
                    color: AppColors.purple,
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: NavTab.dashboard),
    );
  }

  // ── Pack banner ────────────────────────────────────────────────────────────

  Widget _packBanner() {
    if (_pack == null || !_pack!.isActive) {
      return _upgradeBanner();
    }
    final Color packColor = switch (_pack!.type) {
      PackType.essentiel  => AppColors.blue,
      PackType.pro        => AppColors.purple,
      PackType.business   => AppColors.purple,
      PackType.lincooPlus => AppColors.purple,
      PackType.starter    => AppColors.gray,
    };
    final commPct = (_pack!.commissionRate * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: packColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: packColor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(_pack!.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pack ${_pack!.label}',
                style: GoogleFonts.montserrat(
                    color: packColor, fontSize: 13, fontWeight: FontWeight.w800)),
            Text('Commission Lincoo : $commPct% sur chaque vente',
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 11)),
          ]),
        ),
        if (_pack!.expiresAt != null)
          Text(_expiryLabel(_pack!.expiresAt!),
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 10)),
      ]),
    );
  }

  Widget _upgradeBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/seller-pack'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.blue.withValues(alpha: 0.15),
                       AppColors.purple.withValues(alpha: 0.15)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Text('🚀', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Activez un pack pour débloquer toutes les fonctionnalités',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.blue, size: 20),
        ]),
      ),
    );
  }

  String _expiryLabel(DateTime exp) {
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expiré';
    if (days == 0) return 'Expire auj.';
    return 'Expire dans $days j';
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dashboard',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          Text('Tableau de bord vendeur',
              style: GoogleFonts.montserrat(
                  color: AppColors.grayLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.gray, size: 14),
            const SizedBox(width: 4),
            Text('Ce mois',
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 12)),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.gray, size: 16),
          ]),
        ),
      ]),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _statsRow() {
    // Commission info for the third stat
    String commLabel;
    Color  commColor;
    if (_pack?.isActive == true) {
      final pct = (_pack!.commissionRate * 100).toStringAsFixed(0);
      commLabel = '$pct% comm.';
      commColor = _pack!.commissionRate <= 0.03 ? Colors.green : AppColors.gold;
    } else {
      commLabel = '5% comm.';
      commColor = AppColors.gold;
    }

    return Row(children: [
      Expanded(child: _statCard('12 400 DA', 'Revenus', Icons.trending_up, Colors.green)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('37', 'Commandes', Icons.shopping_bag_outlined, AppColors.blue)),
      const SizedBox(width: 10),
      Expanded(child: _statCard(commLabel, 'Commission', Icons.percent, commColor)),
    ]);
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 10)),
      ]),
    );
  }

  // ── Revenue chart ──────────────────────────────────────────────────────────

  Widget _revenueCard() {
    const bars = [0.35, 0.55, 0.42, 0.75, 0.65, 0.88, 1.0];
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Revenus cette semaine',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('↑ 12%',
                style: GoogleFonts.montserrat(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('12 400 DA',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        if (_pack?.isActive == true) ...[
          const SizedBox(height: 2),
          Text(
            'Net vendeur : ${_netRevenue(12400)} DA · commission Lincoo : ${_commissionAmount(12400)} DA',
            style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 10),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bars.asMap().entries.map((e) {
              final isLast = e.value == 1.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 30,
                    height: 72 * e.value,
                    decoration: BoxDecoration(
                      gradient: isLast
                          ? const LinearGradient(
                              colors: [AppColors.accent, AppColors.blue],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            )
                          : null,
                      color: isLast ? null : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[e.key],
                      style: GoogleFonts.montserrat(
                          color: isLast ? AppColors.nearBlack : AppColors.grayLight,
                          fontSize: 10,
                          fontWeight: isLast ? FontWeight.w800 : FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  int _netRevenue(int total) =>
      (total * (1 - (_pack?.commissionRate ?? 0.05))).round();

  int _commissionAmount(int total) =>
      (total * (_pack?.commissionRate ?? 0.05)).round();

  // ── Section helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.montserrat(
            color: AppColors.nearBlack,
            fontSize: 15,
            fontWeight: FontWeight.w800));
  }

  // ── Top products ───────────────────────────────────────────────────────────

  Widget _topProducts() {
    // Stats basiques : Essentiel + Pro seulement
    if (_pack?.canViewAnalytics != true) {
      return _lockedSection(
        icon: Icons.leaderboard_outlined,
        title: 'Meilleures ventes',
        desc: 'Disponible à partir du pack Essentiel',
        color: AppColors.blue,
      );
    }
    const products = [
      ('SUMMER LOOLET SCRAF', '23 ventes', '32 200 DA'),
      ('LOOLET CHEMISE ETE', '8 ventes', '36 000 DA'),
      ('LOOLET ROBE SOIRÉE', '5 ventes', '31 000 DA'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: products.asMap().entries.map((e) {
          final p = e.value;
          return Column(children: [
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text('${e.key + 1}',
                        style: GoogleFonts.montserrat(
                            color: AppColors.gray,
                            fontWeight: FontWeight.w700,
                            fontSize: 14))),
              ),
              title: Text(p.$1,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              subtitle: Text(p.$2,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
              trailing: Text(p.$3,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            if (e.key < products.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.lightGray),
          ]);
        }).toList(),
      ),
    );
  }

  // ── Recent orders ──────────────────────────────────────────────────────────

  Widget _recentOrders(BuildContext context) {
    if (_loadingOrders) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.blue, strokeWidth: 2)),
      );
    }
    if (_recentOrdersList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Center(
          child: Text('Aucune commande pour le moment.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 12)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: _recentOrdersList.asMap().entries.map((e) {
          final o = e.value;
          return Column(children: [
            ListTile(
              title: Text('Commande ${o.shortId}',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: o.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(o.statusLabel,
                    style: GoogleFonts.montserrat(
                        color: o.statusColor, fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              onTap: () => Navigator.pushNamed(
                  context, '/order-details-seller',
                  arguments: {'orderId': o.id}),
            ),
            if (e.key < _recentOrdersList.length - 1)
              const Divider(height: 1, indent: 16, color: AppColors.lightGray),
          ]);
        }).toList(),
      ),
    );
  }

  // ── Delivery stats (tous les packs) ───────────────────────────────────────

  Widget _deliveryStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Logistique',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _deliveryRow('ZR Express', '18 colis', 0.72),
        const SizedBox(height: 8),
        _deliveryRow('Yalidine', '11 colis', 0.44),
        const SizedBox(height: 8),
        _deliveryRow('Maystro', '8 colis', 0.32),
      ]),
    );
  }

  Widget _deliveryRow(String name, String count, double pct) {
    return Row(children: [
      SizedBox(width: 90,
          child: Text(name, style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 12))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.lightGray,
            valueColor: const AlwaysStoppedAnimation(AppColors.dark),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(width: 50,
          child: Text(count, textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 11))),
    ]);
  }

  // ── Delivery Analytics (Pro only) ──────────────────────────────────────────

  Widget _deliveryAnalytics() {
    const stats = [
      ('Taux de livraison', '94%', Colors.green),
      ('Délai moyen', '2.4j', AppColors.blue),
      ('Retours', '3%', Colors.orange),
      ('Satisfaction', '4.8★', AppColors.gold),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📦', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text('Delivery Analytics',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Pro',
                style: GoogleFonts.montserrat(
                    color: AppColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: stats.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(s.$2,
                  style: GoogleFonts.montserrat(
                      color: s.$3, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(s.$1,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 10)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Locked section placeholder ─────────────────────────────────────────────

  Widget _lockedSection({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/seller-pack'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text(desc,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Upgrader',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _RecentOrder {
  final String id;
  final String status;

  const _RecentOrder({required this.id, required this.status});

  factory _RecentOrder.fromRow(Map<String, dynamic> row) => _RecentOrder(
        id:     row['id'].toString(),
        status: (row['status'] as String?) ?? 'pending',
      );

  String get shortId =>
      '#${id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}';

  String get statusLabel => switch (status) {
        'pending'   => 'En attente',
        'confirmed' => 'Confirmée',
        'shipped'   => 'Expédiée',
        'delivered' => 'Livré',
        'cancelled' => 'Annulée',
        'refunded'  => 'Remboursée',
        _           => status,
      };

  Color get statusColor => switch (status) {
        'delivered' => Colors.green,
        'cancelled' => AppColors.error,
        'refunded'  => AppColors.error,
        _           => AppColors.blue,
      };
}
