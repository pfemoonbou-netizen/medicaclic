import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  late final TabController _tabs;

  bool   _loading = false;
  String _query   = '';

  List<Map<String, dynamic>> _stores   = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _tabs.dispose();
    super.dispose();
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> _search(String q) async {
    final query = q.trim();
    setState(() { _query = query; _loading = query.isNotEmpty; });
    if (query.isEmpty) {
      setState(() { _stores = []; _products = []; _loading = false; });
      return;
    }
    try {
      final client = Supabase.instance.client;
      final pattern = '%$query%';

      // Boutiques (avec owner_id pour charger l'avatar depuis profiles)
      final storeRows = await client
          .from('stores')
          .select('id, store_name, category, wilaya, logo_url, '
              'products_count, followers_count, is_verified, bio, owner_id')
          .or('store_name.ilike.$pattern,category.ilike.$pattern,'
              'wilaya.ilike.$pattern,username.ilike.$pattern')
          .order('followers_count', ascending: false)
          .limit(20);

      final stores = List<Map<String, dynamic>>.from(storeRows as List);

      // Charger avatar + store_name réel depuis profiles pour chaque boutique
      final ownerIds = stores
          .map<String?>((s) => s['owner_id'] is String ? s['owner_id'] as String : null)
          .whereType<String>()
          .toList();
      if (ownerIds.isNotEmpty) {
        try {
          final profiles = await client
              .from('profiles')
              .select('id, avatar_url, store_name')
              .inFilter('id', ownerIds);
          final Map<String, Map<String, dynamic>> byId = {};
          for (final p in (profiles as List)) {
            if (p['id'] is String) byId[p['id'] as String] = Map<String, dynamic>.from(p as Map);
          }
          for (final s in stores) {
            final ownerId = s['owner_id'] is String ? s['owner_id'] as String : null;
            if (ownerId != null && byId.containsKey(ownerId)) {
              final prof = byId[ownerId]!;
              // Priorité : nom depuis profiles si disponible
              if (prof['store_name'] is String && (prof['store_name'] as String).isNotEmpty) {
                s['store_name'] = prof['store_name'];
              }
              // Logo : logo_url de stores ou avatar_url de profiles
              if ((s['logo_url'] == null || s['logo_url'] is! String) &&
                  prof['avatar_url'] is String) {
                s['logo_url'] = prof['avatar_url'];
              }
            }
          }
        } catch (_) {}
      }

      // Produits
      final prodRows = await client
          .from('products')
          .select('id, name, price, promo_price, images, store_id, '
              'available, offer_tag, stores(store_name, logo_url, owner_id)')
          .ilike('name', pattern)
          .eq('available', true)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _stores   = stores;
          _products = List<Map<String, dynamic>>.from(prodRows as List);
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(children: [
          // ── Search bar ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 18, color: AppColors.nearBlack),
                ),
              ),
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode:  _focus,
                    onChanged:  _search,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: AppColors.nearBlack),
                    decoration: InputDecoration(
                      hintText: 'Rechercher boutiques, produits…',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13, color: AppColors.gray),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.gray, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                _search('');
                              },
                              child: const Icon(Icons.close,
                                  color: AppColors.gray, size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ]),
          ),

          // ── Tabs ────────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.nearBlack,
              unselectedLabelColor: AppColors.gray,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(text: 'Boutiques'
                    '${_stores.isNotEmpty ? " (${_stores.length})" : ""}'),
                Tab(text: 'Produits'
                    '${_products.isNotEmpty ? " (${_products.length})" : ""}'),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _query.isEmpty
                    ? _emptySearch()
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _storesTab(),
                          _productsTab(),
                        ],
                      ),
          ),
        ]),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptySearch() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.search,
                  size: 36, color: AppColors.lightGray),
            ),
          ),
          const SizedBox(height: 20),
          Text('Rechercher une boutique',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
          const SizedBox(height: 8),
          Text('Tapez le nom d\'un vendeur, une catégorie ou un produit',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: AppColors.gray, height: 1.5)),
          const SizedBox(height: 32),
          Text('SUGGESTIONS',
              style: GoogleFonts.montserrat(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.gray, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Mode', 'Beauté', 'Lifestyle', 'Enfants',
                'Chaussures', 'Accessoires', 'Tech', 'Sport']
                .map((tag) => GestureDetector(
                  onTap: () {
                    _ctrl.text = tag;
                    _search(tag);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: Text(tag,
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: AppColors.nearBlack,
                            fontWeight: FontWeight.w500)),
                  ),
                ))
                .toList(),
          ),
        ],
      );

  // ── Stores tab ─────────────────────────────────────────────────────────────

  Widget _storesTab() {
    if (_stores.isEmpty) {
      return _noResult('Aucune boutique trouvée pour "$_query"');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: _stores.length,
      itemBuilder: (_, i) => _storeCard(_stores[i]),
    );
  }

  Widget _storeCard(Map<String, dynamic> s) {
    final name       = s['store_name']      is String ? s['store_name']      as String : '';
    final category   = s['category']        is String ? s['category']        as String : '';
    final wilaya     = s['wilaya']          is String ? s['wilaya']          as String? : null;
    final logo       = s['logo_url']        is String ? s['logo_url']        as String? : null;
    final verified   = s['is_verified']     is bool   ? s['is_verified']     as bool : false;
    final followers  = s['followers_count'] is int    ? s['followers_count'] as int : 0;
    final products   = s['products_count']  is int    ? s['products_count']  as int : 0;
    final bio        = s['bio']             is String ? s['bio']             as String? : null;
    final storeId    = s['id']              is String ? s['id']              as String : '';

    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    final colors = [
      const Color(0xFF121111), const Color(0xFF7B1FA2),
      const Color(0xFF1976D2), const Color(0xFF6E1128),
      const Color(0xFF1B5E20), const Color(0xFF5D4037),
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/store',
          arguments: {'storeId': storeId}),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Logo
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: logo != null && logo.startsWith('http')
                ? Image.network(logo, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                        child: Text(initials,
                            style: GoogleFonts.montserrat(
                                color: Colors.white, fontWeight: FontWeight.w900,
                                fontSize: 18))))
                : Center(
                    child: Text(initials,
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontWeight: FontWeight.w900,
                            fontSize: 18))),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Flexible(
                child: Text(name,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppColors.nearBlack),
                    overflow: TextOverflow.ellipsis),
              ),
              if (verified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: AppColors.blue, size: 15),
              ],
            ]),
            const SizedBox(height: 3),
            Row(children: [
              if (category.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(category,
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: AppColors.accent,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
              ],
              if (wilaya != null)
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 11, color: AppColors.gray),
                  const SizedBox(width: 2),
                  Text(wilaya,
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: AppColors.gray)),
                ]),
            ]),
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(bio,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: AppColors.gray, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Row(children: [
              _statChip(Icons.inventory_2_outlined,
                  '$products produit${products != 1 ? "s" : ""}'),
              const SizedBox(width: 8),
              _statChip(Icons.people_outline, _fmt(followers)),
            ]),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              color: AppColors.lightGray, size: 20),
        ]),
      ),
    );
  }

  // ── Products tab ──────────────────────────────────────────────────────────

  Widget _productsTab() {
    if (_products.isEmpty) {
      return _noResult('Aucun produit trouvé pour "$_query"');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10,
        mainAxisSpacing: 10, childAspectRatio: 0.68,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => _productCard(_products[i]),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final name      = p['name']        as String? ?? '';
    final price     = (p['price']      as num?)?.toDouble() ?? 0;
    final promo     = (p['promo_price'] as num?)?.toDouble();
    final images    = (p['images']     as List?)?.cast<String>() ?? [];
    final storeId   = p['store_id']    as String?;
    final storeData = p['stores']      as Map<String, dynamic>?;
    final storeName = storeData?['store_name'] as String? ?? '';
    final offerTag  = p['offer_tag']   as String?;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product', arguments: p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(fit: StackFit.expand, children: [
                images.isNotEmpty
                    ? (images.first.startsWith('http')
                        ? Image.network(images.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: AppColors.bgGray,
                                child: const Icon(Icons.image_outlined,
                                    color: AppColors.lightGray, size: 32)))
                        : Image.asset(images.first, fit: BoxFit.cover))
                    : Container(
                        color: AppColors.bgGray,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.lightGray, size: 32)),
                // Discount badge
                if (promo != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          '−${((1 - promo / price) * 100).round()}%',
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                // Offer tag
                if (offerTag != null)
                  Positioned(
                    top: promo != null ? 30 : 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.blue]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(offerTag,
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack, fontSize: 8,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                // Store name tap
                if (storeId != null)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/store',
                          arguments: {'storeId': storeId}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent,
                              Colors.black.withValues(alpha: 0.55)],
                          ),
                        ),
                        child: Row(children: [
                          const Icon(Icons.storefront_outlined,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(storeName,
                                style: GoogleFonts.montserrat(
                                    color: Colors.white, fontSize: 9,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(name,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Text('${_fmtPrice(promo ?? price)} DA',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: promo != null
                            ? Colors.red : AppColors.nearBlack)),
                if (promo != null) ...[
                  const SizedBox(width: 4),
                  Text('${_fmtPrice(price)} DA',
                      style: GoogleFonts.montserrat(
                          fontSize: 9, color: AppColors.gray,
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _noResult(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_outlined,
            size: 52, color: AppColors.lightGray),
        const SizedBox(height: 14),
        Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 13, color: AppColors.gray, height: 1.5)),
      ]),
    ),
  );

  Widget _statChip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColors.gray),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 10, color: AppColors.gray)),
    ],
  );

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _fmtPrice(double p) {
    final s = p.toStringAsFixed(0);
    return s.length > 3
        ? '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}'
        : s;
  }
}
