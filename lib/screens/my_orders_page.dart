import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  RealtimeChannel? _channel;

  bool _loading = true;
  List<_Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _orders  = (rows as List).map((r) => _Order.fromRow(Map<String, dynamic>.from(r))).toList();
          _loading = false;
        });
      }
      _subscribe(user.id);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribe(String buyerId) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('my-orders-$buyerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'buyer_id', value: buyerId),
          callback: (_) => _load(),
        )
        .subscribe();
  }

  List<_Order> _forTab(int i) => switch (i) {
        1 => _orders.where((o) => ['pending', 'confirmed', 'shipped'].contains(o.status)).toList(),
        2 => _orders.where((o) => o.status == 'delivered').toList(),
        3 => _orders.where((o) => ['cancelled', 'refunded'].contains(o.status)).toList(),
        _ => _orders,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes Commandes',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.nearBlack,
          unselectedLabelColor: AppColors.grayLight,
          indicatorColor: AppColors.nearBlack,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.lightGray,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Tout'),
            Tab(text: 'En cours'),
            Tab(text: 'Livré'),
            Tab(text: 'Annulé'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : TabBarView(
              controller: _tabs,
              children: List.generate(4, (i) => _buildOrderList(_forTab(i))),
            ),
    );
  }

  Widget _buildOrderList(List<_Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text('Aucune commande ici.',
            style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 13)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: orders.length,
      itemBuilder: (_, i) => _orderCard(orders[i]),
    );
  }

  Widget _orderCard(_Order o) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order-tracking', arguments: o.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Commande ${o.shortId}',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: o.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o.statusLabel,
                  style: GoogleFonts.montserrat(
                      color: o.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(o.storeName,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            Text('${o.total} DA',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(o.dateLabel,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 11)),
          ]),
          if (o.status == 'delivered') ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/order-feedback',
                arguments: {
                  'orderId': o.id,
                  'storeName': o.storeName,
                  'orderLabel': 'Commande ${o.shortId}',
                },
              ),
              child: Row(children: [
                const Icon(Icons.star_border,
                    color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text('Laisser un avis',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Order {
  final String id;
  final String storeName;
  final int total;
  final String status;
  final DateTime? createdAt;

  const _Order({
    required this.id,
    required this.storeName,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory _Order.fromRow(Map<String, dynamic> row) {
    final items = (row['items'] as List?) ?? const [];
    final firstItem = items.isNotEmpty ? Map<String, dynamic>.from(items.first as Map) : null;
    return _Order(
      id:        row['id'].toString(),
      storeName: (firstItem?['store_name'] as String?) ?? 'Boutique',
      total:     (row['total'] as num?)?.toInt() ?? 0,
      status:    (row['status'] as String?) ?? 'pending',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
    );
  }

  String get shortId => '#${id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}';

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

  String get dateLabel {
    final d = createdAt;
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
