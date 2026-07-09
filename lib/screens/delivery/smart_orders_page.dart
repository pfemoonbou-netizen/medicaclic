import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/delivery_models.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';

class SmartOrdersPage extends StatefulWidget {
  const SmartOrdersPage({super.key});
  @override
  State<SmartOrdersPage> createState() => _SmartOrdersPageState();
}

class _SmartOrdersPageState extends State<SmartOrdersPage>
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
  List<SmartDeliveryItem> _allItems = [];
  bool _loading = true;
  late String _sellerId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _sellerId = UserSession.instance.current.id;
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await DeliveryService.instance.mySmartItems(_sellerId);
    if (mounted) setState(() { _allItems = items; _loading = false; });
  }

  List<SmartDeliveryItem> _filtered(SmartItemStatus? status) => status == null
      ? _allItems
      : _allItems.where((i) => i.status == status).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(child: Column(children: [
      _topBar(),
      Container(
        color: _card,
        child: TabBar(
          controller: _tabs,
          labelColor: _acc,
          unselectedLabelColor: Colors.white38,
          indicatorColor: _acc,
          indicatorWeight: 2,
          dividerColor: _bord,
          labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
          tabs: const [
            Tab(text: 'Tout'),
            Tab(text: 'En attente'),
            Tab(text: 'Confirmé'),
            Tab(text: 'Prêt'),
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
            : TabBarView(controller: _tabs, children: [
                _list(null),
                _list(SmartItemStatus.pending),
                _list(SmartItemStatus.confirmed),
                _list(SmartItemStatus.prepared),
              ]),
      ),
    ])),
  );

  Widget _topBar() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Smart Orders', style: GoogleFonts.montserrat(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        Text('${_allItems.length} commandes Smart Delivery',
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
      ])),
      GestureDetector(
        onTap: _load,
        child: Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: _bord, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
      ),
    ]),
  );

  Widget _list(SmartItemStatus? status) {
    final items = _filtered(status);
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.inbox_rounded, color: Colors.white24, size: 52),
        const SizedBox(height: 12),
        Text('Aucune commande', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load, color: _acc, backgroundColor: _card,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _itemCard(items[i]),
      ),
    );
  }

  Widget _itemCard(SmartDeliveryItem item) {
    final statusCfg = _statusConfig(item.status);
    final timeLeft  = _timeLeft(item);

    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (statusCfg['color'] as Color).withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: (statusCfg['color'] as Color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(statusCfg['icon'] as IconData,
                  color: statusCfg['color'] as Color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Groupe #${item.groupId.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w800)),
              Text(item.storeName ?? 'Votre boutique',
                  style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (statusCfg['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (statusCfg['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Text(statusCfg['label'] as String,
                  style: GoogleFonts.montserrat(
                      color: statusCfg['color'] as Color, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),

        // ── Products ─────────────────────────────────────────────────────────
        if (item.products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              children: item.products.take(3).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 5, color: Colors.white24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${p['name'] ?? 'Produit'} × ${p['qty'] ?? 1}',
                    style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 11),
                  )),
                  Text('${p['price'] ?? 0} DA',
                      style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11)),
                ]),
              )).toList(),
            ),
          ),

        // ── Info chips ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            _chip('💰 ${item.subtotalDzd} DA', _acc),
            if (item.weightKg != null) _chip('⚖️ ${item.weightKg!.toStringAsFixed(1)} kg', Colors.white38),
            if (timeLeft != null) _chip('⏱ $timeLeft', _gold),
            _chip('📅 ${_fmtDate(item.createdAt)}', Colors.white24),
          ]),
        ),

        // ── Rejection reason ─────────────────────────────────────────────────
        if (item.rejectionReason != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _red.withValues(alpha: 0.2))),
              child: Text('Raison: ${item.rejectionReason}',
                  style: GoogleFonts.montserrat(color: _red, fontSize: 11))),
          ),

        // ── Actions ──────────────────────────────────────────────────────────
        if (item.status == SmartItemStatus.pending)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(child: _actionBtn('✕ Refuser', _red,
                  () => _showRejectDialog(item))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('✓ Confirmer', _green,
                  () => _confirm(item))),
            ]),
          ),

        if (item.status == SmartItemStatus.confirmed)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _actionBtn('📦 Marquer Prêt', _purp, () => _markPrepared(item)),
          ),
      ]),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Text(label, style: GoogleFonts.montserrat(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    ),
  );

  Future<void> _confirm(SmartDeliveryItem item) async {
    await DeliveryService.instance.confirmItem(item.id);
    _snack('✅ Commande confirmée');
    _load();
  }

  Future<void> _markPrepared(SmartDeliveryItem item) async {
    await DeliveryService.instance.markPrepared(item.id);
    _snack('📦 Commande marquée comme prête');
    _load();
  }

  void _showRejectDialog(SmartDeliveryItem item) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Refuser la commande', style: GoogleFonts.montserrat(
          color: Colors.white, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Indiquez la raison du refus (optionnel)',
            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ex: Stock insuffisant...',
            hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12),
            filled: true, fillColor: _bord,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
          maxLines: 2,
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.montserrat(color: Colors.white54))),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await DeliveryService.instance.rejectItem(item.id, ctrl.text.trim());
            _snack('Commande refusée');
            _load();
          },
          child: Text('Refuser', style: GoogleFonts.montserrat(color: _red, fontWeight: FontWeight.w800)),
        ),
      ],
    ));
  }

  Map<String, dynamic> _statusConfig(SmartItemStatus s) => {
    SmartItemStatus.pending:   {'icon': Icons.hourglass_top_rounded,    'color': _gold,  'label': 'En attente'},
    SmartItemStatus.confirmed: {'icon': Icons.check_circle_rounded,      'color': _green, 'label': 'Confirmé'},
    SmartItemStatus.rejected:  {'icon': Icons.cancel_rounded,            'color': _red,   'label': 'Refusé'},
    SmartItemStatus.prepared:  {'icon': Icons.inventory_2_rounded,       'color': _purp,  'label': 'Prêt'},
    SmartItemStatus.pickedUp:  {'icon': Icons.local_shipping_rounded,    'color': _acc,   'label': 'Récupéré'},
    SmartItemStatus.cancelled: {'icon': Icons.block_rounded,             'color': Colors.white38, 'label': 'Annulé'},
  }[s]!;

  String? _timeLeft(SmartDeliveryItem item) {
    if (item.status != SmartItemStatus.pending) return null;
    final deadline = item.createdAt.add(const Duration(hours: 6));
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Expiré';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
    return '${diff.inMinutes}min';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
        backgroundColor: _card, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12)));
}
