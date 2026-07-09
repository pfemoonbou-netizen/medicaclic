import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/cart_service.dart';
import '../widgets/primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartService.instance.notifier,
      builder: (context, items, _) => _CartView(items: items),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CartView extends StatelessWidget {
  final List<CartItem> items;
  const _CartView({required this.items});

  int get _subtotal =>
      items.fold(0, (s, i) => s + (i.unitPrice * i.qty).round());

  String _fmt(int p) =>
      p >= 1000 ? '${p ~/ 1000} ${(p % 1000).toString().padLeft(3, '0')}' : '$p';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/feed');
            }
          },
        ),
        title: Text('Panier (${items.length})',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => CartService.instance.clear(),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: Text('Vider',
                  style: GoogleFonts.montserrat(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          size: 46, color: AppColors.lightGray),
                    ),
                    const SizedBox(height: 20),
                    Text('Votre panier est vide',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Ajoutez des articles pour commencer',
                        style: GoogleFonts.montserrat(
                            color: AppColors.grayLight, fontSize: 13)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) =>
                      _ItemCard(item: items[i], fmtFn: _fmt),
                ),
        ),
        if (items.isNotEmpty) _buildSummary(context),
      ]),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Text(
              'Sous-total (${items.length} article${items.length > 1 ? 's' : ''})',
              style:
                  GoogleFonts.montserrat(color: AppColors.gray, fontSize: 13)),
          const Spacer(),
          Text('${_fmt(_subtotal)} DA',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.local_shipping_outlined,
              size: 13, color: AppColors.gray),
          const SizedBox(width: 4),
          Text('Livraison calculée à la commande',
              style:
                  GoogleFonts.montserrat(color: AppColors.gray, fontSize: 11)),
        ]),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: AppColors.lightGray),
        ),
        Row(children: [
          Text('Total',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('${_fmt(_subtotal)} DA',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Passer la commande',
          onPressed: () => Navigator.pushNamed(context, '/checkout'),
        ),
      ]),
    );
  }
}

// ── Item card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatefulWidget {
  final CartItem item;
  final String Function(int) fmtFn;
  const _ItemCard({required this.item, required this.fmtFn});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final fmt  = widget.fmtFn;

    return GestureDetector(
      onTap: () => _openEditSheet(context, item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          // Thumbnail
          Stack(children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: item.imageUrl != null
                  ? Image.network(item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.lightGray,
                          size: 32))
                  : const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.lightGray, size: 32),
            ),
            Positioned(
              right: 4, bottom: 4,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                    color: AppColors.nearBlack,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.edit, color: Colors.white, size: 11),
              ),
            ),
          ]),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (item.storeName.isNotEmpty)
                Text(item.storeName,
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 11)),
              const SizedBox(height: 4),
              Row(children: [
                if (item.size.isNotEmpty) ...[
                  _variantBadge(item.size),
                  const SizedBox(width: 6),
                ],
                if (item.colorHex.isNotEmpty) ...[
                  _colorDot(item.colorHex),
                  const SizedBox(width: 4),
                ],
                if (item.colorName.isNotEmpty)
                  Text(item.colorName,
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('${fmt((item.unitPrice * item.qty).round())} DA',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                if (item.qty > 1) ...[
                  const SizedBox(width: 6),
                  Text('(${item.qty} × ${fmt(item.unitPrice.round())} DA)',
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
                ],
                const Spacer(),
                _qtyBtn(Icons.remove, () {
                  if (item.qty > 1) {
                    CartService.instance.update(item.id, qty: item.qty - 1);
                  } else {
                    CartService.instance.remove(item.id);
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('${item.qty}',
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
                _qtyBtn(Icons.add, () =>
                    CartService.instance.update(item.id, qty: item.qty + 1)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _variantBadge(String size) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Text(size,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );

  Widget _colorDot(String hex) {
    Color c = AppColors.lightGray;
    try { c = Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16)); } catch (_) {}
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightGray),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.nearBlack),
        ),
      );

  void _openEditSheet(BuildContext context, CartItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditSheet(item: item),
    );
  }
}

// ── Edit sheet ────────────────────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final CartItem item;
  const _EditSheet({required this.item});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late String _size;
  late String _colorName;
  late String _colorHex;
  late int    _qty;

  // Fresh variants fetched from Supabase
  List<Map<String, dynamic>> _sizes  = [];
  List<Map<String, dynamic>> _colors = [];
  bool _loadingVariants = true;

  @override
  void initState() {
    super.initState();
    _size      = widget.item.size;
    _colorName = widget.item.colorName;
    _colorHex  = widget.item.colorHex;
    _qty       = widget.item.qty;
    // Seed with cached variants while we fetch fresh ones
    _sizes  = List.from(widget.item.sizeVariants);
    _colors = List.from(widget.item.colorVariants);
    _fetchFreshVariants();
  }

  Future<void> _fetchFreshVariants() async {
    try {
      final row = await Supabase.instance.client
          .from('products')
          .select('size_variants, color_variants, stock_qty')
          .eq('id', widget.item.id)
          .maybeSingle();
      if (row == null || !mounted) return;

      List<Map<String, dynamic>> parseSizes(dynamic raw) {
        if (raw is! List) return [];
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['size'] is String)
            .toList();
      }

      List<Map<String, dynamic>> parseColors(dynamic raw) {
        if (raw is! List) return [];
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['hex'] is String)
            .toList();
      }

      final freshSizes  = parseSizes(row['size_variants']);
      final freshColors = parseColors(row['color_variants']);

      if (!mounted) return;
      setState(() {
        _sizes  = freshSizes;
        _colors = freshColors;
        _loadingVariants = false;

        // If current selection is no longer available, reset to first available
        if (_size.isNotEmpty &&
            !_sizes.any((v) => v['size'] == _size)) {
          final first = _sizes.firstWhere(
              (v) => ((v['qty'] as int?) ?? 999) > 0,
              orElse: () => _sizes.isNotEmpty ? _sizes.first : {});
          _size = first['size'] as String? ?? '';
        }
        if (_colorHex.isNotEmpty &&
            !_colors.any((v) => v['hex'] == _colorHex)) {
          final first = _colors.firstWhere(
              (v) => ((v['qty'] as int?) ?? 999) > 0,
              orElse: () => _colors.isNotEmpty ? _colors.first : {});
          _colorHex  = first['hex']  as String? ?? '';
          _colorName = first['name'] as String? ?? '';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingVariants = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _hexToColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16)); }
    catch (_) { return AppColors.lightGray; }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasSizes  = _sizes.isNotEmpty;
    final hasColors = _colors.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(
          child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
        ),
        // Loading bar while fetching fresh variants
        if (_loadingVariants)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.accent,
            backgroundColor: AppColors.bgGray,
          ),

        const SizedBox(height: 16),

        // Header
        Row(children: [
          Expanded(
            child: Text(widget.item.name,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: AppColors.gray),
          ),
        ]),
        const Divider(color: AppColors.lightGray),
        const SizedBox(height: 8),

        // ── Tailles réelles du vendeur ────────────────────────────────────
        if (hasSizes) ...[
          Text('Taille',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: _sizes.map((v) {
              final s   = v['size'] as String? ?? '';
              final qty = (v['qty'] as int?) ?? 999;
              final oos = qty == 0;
              final sel = _size == s;
              return GestureDetector(
                onTap: oos ? null : () => setState(() => _size = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: oos
                        ? const Color(0xFFF5F5F5)
                        : sel ? AppColors.nearBlack : Colors.white,
                    border: Border.all(
                      color: oos
                          ? AppColors.lightGray
                          : sel ? AppColors.nearBlack : AppColors.lightGray,
                      width: sel ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(s,
                      style: GoogleFonts.montserrat(
                          color: oos
                              ? AppColors.grayLight
                              : sel ? Colors.white : AppColors.nearBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: oos
                              ? TextDecoration.lineThrough
                              : null)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
        ],

        // ── Couleurs réelles du vendeur ───────────────────────────────────
        if (hasColors) ...[
          Text('Couleur',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10,
            children: _colors.map((v) {
              final hex  = v['hex']  as String? ?? '';
              final name = v['name'] as String? ?? '';
              final qty  = (v['qty'] as int?)  ?? 999;
              final oos  = qty == 0;
              final sel  = _colorHex == hex;
              final c    = _hexToColor(hex);
              return Tooltip(
                message: oos ? '$name — Rupture de stock' : name,
                child: GestureDetector(
                  onTap: oos
                      ? null
                      : () => setState(() {
                            _colorHex  = hex;
                            _colorName = name;
                          }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: oos ? c.withValues(alpha: 0.35) : c,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel
                              ? AppColors.nearBlack
                              : AppColors.lightGray,
                          width: sel ? 2.5 : 1),
                      boxShadow: sel && !oos
                          ? [BoxShadow(
                              color: c.withValues(alpha: 0.4),
                              blurRadius: 6, spreadRadius: 1)]
                          : [],
                    ),
                    child: sel && !oos
                        ? Icon(Icons.check_rounded,
                            size: 16,
                            color: c.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white)
                        : oos
                            ? const Icon(Icons.close,
                                size: 14, color: Colors.white70)
                            : null,
                  ),
                ),
              );
            }).toList(),
          ),
          // Nom de la couleur sélectionnée
          if (_colorName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_colorName,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 18),
        ],

        // ── Message si aucune variante ────────────────────────────────────
        if (!hasSizes && !hasColors) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.gray),
              const SizedBox(width: 8),
              Text('Ce produit n\'a pas de variantes',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.gray)),
            ]),
          ),
          const SizedBox(height: 18),
        ],

        // ── Quantité ──────────────────────────────────────────────────────
        Row(children: [
          Text('Quantité',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          _sheetQtyBtn(Icons.remove,
              () => setState(() { if (_qty > 1) _qty--; })),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('$_qty',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          _sheetQtyBtn(Icons.add, () => setState(() => _qty++)),
        ]),
        const SizedBox(height: 24),

        // ── Appliquer ─────────────────────────────────────────────────────
        PrimaryButton(
          label: 'Appliquer les modifications',
          height: 52,
          onPressed: () {
            CartService.instance.update(
              widget.item.id,
              qty:       _qty,
              size:      _size,
              colorName: _colorName,
              colorHex:  _colorHex,
            );
            Navigator.pop(context);
          },
        ),
      ]),
    );
  }

  Widget _sheetQtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 17, color: AppColors.nearBlack),
        ),
      );
}
