import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/delivery_models.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';

class FulfillmentPage extends StatefulWidget {
  const FulfillmentPage({super.key});
  @override
  State<FulfillmentPage> createState() => _FulfillmentPageState();
}

class _FulfillmentPageState extends State<FulfillmentPage>
    with SingleTickerProviderStateMixin {
  static const _bg    = Color(0xFF07080F);
  static const _card  = Color(0xFF0D0F1E);
  static const _bord  = Color(0xFF1C1F35);
  static const _acc   = Color(0xFF4F8EFF);
  static const _green = Color(0xFF10E8B0);
  static const _gold  = Color(0xFFFFB800);
  static const _red   = Color(0xFFF04040);

  late TabController _tabs;
  List<FulfillmentInventoryItem> _items = [];
  bool _loading = true;
  String _search = '';

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
    final sellerId = UserSession.instance.current.id;
    final list = await DeliveryService.instance.myInventory(sellerId);
    if (mounted) setState(() { _items = list; _loading = false; });
  }

  List<FulfillmentInventoryItem> get _filtered {
    final q = _search.toLowerCase();
    return _items.where((i) =>
        q.isEmpty || i.productName.toLowerCase().contains(q)).toList();
  }

  List<FulfillmentInventoryItem> get _lowStock =>
      _filtered.where((i) => i.quantityAvailable <= 3 && i.quantityAvailable > 0).toList();

  List<FulfillmentInventoryItem> get _outOfStock =>
      _filtered.where((i) => i.quantityAvailable == 0).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(child: Column(children: [
      _topBar(),
      _searchBar(),
      _summaryRow(),
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
          tabs: [
            Tab(text: 'Tous (${_filtered.length})'),
            Tab(text: 'Stock bas (${_lowStock.length})'),
            Tab(text: 'Épuisé (${_outOfStock.length})'),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
          : TabBarView(controller: _tabs, children: [
              _itemList(_filtered),
              _itemList(_lowStock),
              _itemList(_outOfStock),
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
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Fulfillment Center', style: GoogleFonts.montserrat(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        Text('Gestion des stocks Lincoo', style: GoogleFonts.montserrat(
            color: Colors.white38, fontSize: 11)),
      ])),
      GestureDetector(
        onTap: _load,
        child: Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: _bord, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
      ),
    ]),
  );

  Widget _searchBar() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: TextField(
      onChanged: (v) => setState(() => _search = v),
      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Rechercher un produit...',
        hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _bord)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _bord)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _acc)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        isDense: true,
      ),
    ),
  );

  Widget _summaryRow() {
    final totalStored   = _filtered.fold(0, (s, i) => s + i.quantityStored);
    final totalAvail    = _filtered.fold(0, (s, i) => s + i.quantityAvailable);
    final totalReserved = _filtered.fold(0, (s, i) => s + i.quantityReserved);
    final totalShipped  = _filtered.fold(0, (s, i) => s + i.quantityShipped);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      color: _card,
      child: Row(children: [
        _sumChip('Stocké', '$totalStored', Colors.white54),
        const SizedBox(width: 8),
        _sumChip('Dispo', '$totalAvail', _green),
        const SizedBox(width: 8),
        _sumChip('Réservé', '$totalReserved', _gold),
        const SizedBox(width: 8),
        _sumChip('Expédié', '$totalShipped', _acc),
      ]),
    );
  }

  Widget _sumChip(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(children: [
      Text(value, style: GoogleFonts.montserrat(
          color: color, fontSize: 15, fontWeight: FontWeight.w900)),
      Text(label, style: GoogleFonts.montserrat(color: color.withValues(alpha: 0.6), fontSize: 9)),
    ]),
  ));

  Widget _itemList(List<FulfillmentInventoryItem> items) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 52),
        const SizedBox(height: 12),
        Text('Aucun produit', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load, color: _acc, backgroundColor: _card,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _itemCard(items[i]),
      ),
    );
  }

  Widget _itemCard(FulfillmentInventoryItem item) {
    final stockColor = item.quantityAvailable == 0 ? _red
        : item.quantityAvailable <= 3 ? _gold
        : _green;

    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(15),
        border: Border.all(color: stockColor.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: stockColor.withValues(alpha: 0.2)),
              ),
              child: Center(child: Text(
                  item.productName.isNotEmpty ? item.productName[0].toUpperCase() : '?',
                  style: GoogleFonts.montserrat(
                      color: stockColor, fontSize: 20, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.productName, style: GoogleFonts.montserrat(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (item.sku != null)
                Text('SKU: ${item.sku}', style: GoogleFonts.montserrat(
                    color: Colors.white38, fontSize: 10)),
              if (item.weightKg != null)
                Text('${item.weightKg!.toStringAsFixed(1)} kg', style: GoogleFonts.montserrat(
                    color: Colors.white24, fontSize: 10)),
              const SizedBox(height: 2),
              Text('Entrée le ${_fmtDate(item.enteredAt)}',
                  style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${item.quantityAvailable}', style: GoogleFonts.montserrat(
                  color: stockColor, fontSize: 22, fontWeight: FontWeight.w900)),
              Text('disponible(s)', style: GoogleFonts.montserrat(
                  color: Colors.white24, fontSize: 9)),
            ]),
          ]),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: _bord.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
          child: Column(children: [
            Row(children: [
              _qtyCol('Stocké', item.quantityStored, Colors.white54),
              _qtyCol('Dispo', item.quantityAvailable, _green),
              _qtyCol('Réservé', item.quantityReserved, _gold),
              _qtyCol('Expédié', item.quantityShipped, _acc),
            ]),
            const SizedBox(height: 10),
            _progressBar(item),
          ]),
        ),
      ]),
    );
  }

  Widget _qtyCol(String label, int qty, Color color) => Expanded(child: Column(children: [
    Text('$qty', style: GoogleFonts.montserrat(
        color: color, fontSize: 14, fontWeight: FontWeight.w900)),
    Text(label, style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 9)),
  ]));

  Widget _progressBar(FulfillmentInventoryItem item) {
    final total = item.quantityStored;
    if (total == 0) return const SizedBox();
    final availFrac    = (item.quantityAvailable / total).clamp(0.0, 1.0);
    final reservedFrac = (item.quantityReserved / total).clamp(0.0, 1.0);
    final shippedFrac  = (item.quantityShipped / total).clamp(0.0, 1.0);
    final restFrac     = (1 - availFrac - reservedFrac - shippedFrac).clamp(0.0, 1.0);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Répartition du stock', style: GoogleFonts.montserrat(
          color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(height: 8, child: Row(children: [
          if (availFrac > 0) Expanded(flex: (availFrac * 100).round(),
              child: Container(color: _green)),
          if (reservedFrac > 0) Expanded(flex: (reservedFrac * 100).round(),
              child: Container(color: _gold)),
          if (shippedFrac > 0) Expanded(flex: (shippedFrac * 100).round(),
              child: Container(color: _acc)),
          if (restFrac > 0) Expanded(flex: (restFrac * 100).round(),
              child: Container(color: _bord)),
        ])),
      ),
      const SizedBox(height: 4),
      Row(children: [
        _legend('Dispo', _green), const SizedBox(width: 10),
        _legend('Réservé', _gold), const SizedBox(width: 10),
        _legend('Expédié', _acc),
      ]),
    ]);
  }

  Widget _legend(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 3),
    Text(label, style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 9)),
  ]);

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
