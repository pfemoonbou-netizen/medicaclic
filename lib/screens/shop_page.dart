import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/app_cache.dart';
import '../services/cart_service.dart';
import '../widgets/app_bottom_nav.dart';

// Allows mouse-drag scrolling on Flutter Web for horizontal lists
class _WebDragScroll extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Assets
// ─────────────────────────────────────────────────────────────────────────────

const _img1 =
  'https://via.placeholder.com/400';
const _img2 =
  'https://via.placeholder.com/400';
const _img3 =
  'https://via.placeholder.com/400';
const _img4 =
  'https://via.placeholder.com/400';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _Category {
  final String name;
  final List<String> subs;
  const _Category(this.name, this.subs);
}

class _Product {
  final String name, store, imageUrl, category, subCategory;
  final int price;
  final int? oldPrice;
  final double rating;
  final int reviewCount;
  final bool isNew, isPromo;
  final List<String> sizes;
  final Map<String, dynamic>? rawData;

  const _Product({
    required this.name,
    required this.store,
    required this.price,
    this.oldPrice,
    required this.rating,
    required this.reviewCount,
    this.isNew = false,
    this.isPromo = false,
    required this.sizes,
    required this.imageUrl,
    required this.category,
    required this.subCategory,
    this.rawData,
  });

  int get discount =>
      oldPrice != null ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  Map<String, dynamic> toMap() => rawData ?? {
    'name': name, 'price': price, 'promo_price': oldPrice,
    'images': [imageUrl], 'category': category, 'description': '',
    'stores': {'store_name': store},
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Static data
// ─────────────────────────────────────────────────────────────────────────────

const _kCategories = [
  _Category('Femme', [
    'Vêtements', 'Chaussures & sacs', 'Cosmétique & hygiène',
    'Bons plans', 'Pyjamas', 'Lingerie', 'Sport & yoga'
  ]),
  _Category('Homme', [
    'Vêtements', 'Chaussures', 'Parfums & déo', 'Accessoires', 'Sport'
  ]),
  _Category('Enfants', [
    'Bébé 0-3 ans', 'Fille 4-14 ans', 'Garçon 4-14 ans', 'Chaussures', 'Jouets'
  ]),
  _Category('Beauté', [
    'Maquillage', 'Soin visage', 'Soin corps', 'Parfums', 'Cheveux'
  ]),
  _Category('Maison', [
    'Décoration', 'Cuisine', 'Literie', 'Salle de bain', 'Jardin'
  ]),
  _Category('Sport', [
    'Vêtements sport', 'Chaussures sport', 'Équipement', 'Nutrition'
  ]),
];

const _kProducts = [
  _Product(name: 'SUMMER LOOLET SCRAF', store: 'LOOLET STORE',
      price: 1400, oldPrice: 2000, rating: 5.0, reviewCount: 325,
      isNew: true, isPromo: true, sizes: ['XS','S','M','L','XL'],
      imageUrl: _img1, category: 'Femme', subCategory: 'Vêtements'),
  _Product(name: 'LOOLET CHEMISE ÉTÉ', store: 'LOOLET STORE',
      price: 4500, oldPrice: 5800, rating: 4.9, reviewCount: 198,
      isPromo: true, sizes: ['S','M','L','XL'],
      imageUrl: _img2, category: 'Femme', subCategory: 'Vêtements'),
  _Product(name: 'LOOLET ROBE SOIRÉE', store: 'LOOLET STORE',
      price: 6200, oldPrice: 8000, rating: 4.8, reviewCount: 87,
      isPromo: true, sizes: ['XS','S','M','L'],
      imageUrl: _img3, category: 'Femme', subCategory: 'Vêtements'),
  _Product(name: 'LOOLET BLOUSE FLORALE', store: 'LOOLET STORE',
      price: 3800, oldPrice: 4500, rating: 4.7, reviewCount: 143,
      isPromo: true, sizes: ['S','M','L','XL','XXL'],
      imageUrl: _img4, category: 'Femme', subCategory: 'Vêtements'),
  _Product(name: 'FOULARD SATINÉ', store: 'LOOLET STORE',
      price: 2200, rating: 4.5, reviewCount: 56,
      isNew: true, sizes: ['Unique'],
      imageUrl: _img1, category: 'Femme', subCategory: 'Chaussures & sacs'),
  _Product(name: 'LOOLET SET CASUAL', store: 'LOOLET STORE',
      price: 7400, oldPrice: 9000, rating: 5.0, reviewCount: 212,
      isNew: true, isPromo: true, sizes: ['XS','S','M','L','XL'],
      imageUrl: _img2, category: 'Femme', subCategory: 'Vêtements'),
  _Product(name: 'CRÈME HYDRATANTE PRO', store: 'BELLE ALGÉRIE',
      price: 1800, rating: 4.6, reviewCount: 89,
      isNew: true, sizes: ['Unique'],
      imageUrl: _img4, category: 'Beauté', subCategory: 'Soin visage'),
  _Product(name: 'PARFUM ROSE DORÉE', store: 'BELLE ALGÉRIE',
      price: 3500, rating: 4.8, reviewCount: 134,
      isNew: true, sizes: ['50ml','100ml'],
      imageUrl: _img3, category: 'Beauté', subCategory: 'Parfums'),
  _Product(name: 'JEAN SLIM FIT', store: 'HOMME STYLE DZ',
      price: 5500, oldPrice: 6500, rating: 4.7, reviewCount: 76,
      isPromo: true, sizes: ['38','40','42','44','46'],
      imageUrl: _img2, category: 'Homme', subCategory: 'Vêtements'),
  _Product(name: 'SNEAKERS PREMIUM', store: 'SPORT ZONE DZ',
      price: 4200, rating: 4.9, reviewCount: 203,
      isNew: true, sizes: ['39','40','41','42','43','44'],
      imageUrl: _img1, category: 'Homme', subCategory: 'Chaussures'),
  _Product(name: 'ROBE BÉBÉ PRINTEMPS', store: 'KIDS CORNER',
      price: 1200, rating: 4.6, reviewCount: 45,
      isNew: true, sizes: ['3m','6m','12m','18m'],
      imageUrl: _img4, category: 'Enfants', subCategory: 'Bébé 0-3 ans'),
  _Product(name: 'BALLON MATCH PRO', store: 'SPORT ZONE DZ',
      price: 2800, rating: 4.4, reviewCount: 67,
      sizes: ['Taille 4','Taille 5'],
      imageUrl: _img3, category: 'Sport', subCategory: 'Équipement'),
];

// Quick filter identifiers
const _qfBestPrice = 'best_price';
const _qfTopRated  = 'top_rated';
const _qfNew       = 'new';
const _qfPromo     = 'promo';
const _qfSellers   = 'best_sellers';

const _kQuickFilters = [
  (_qfBestPrice, 'Best Price',   Icons.sell_outlined),
  (_qfTopRated,  'Top Rated',    Icons.star_outline_rounded),
  (_qfNew,       'Nouveaux',     Icons.fiber_new_outlined),
  (_qfPromo,     'En Promo',     Icons.local_offer_outlined),
  (_qfSellers,   'Best Sellers', Icons.trending_up_rounded),
];


// ─────────────────────────────────────────────────────────────────────────────

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _searchCtrl = TextEditingController();
  String  _q              = '';
  String? _cat;
  String? _sub;
  String? _quickFilter;
  double  _maxPrice       = 20000;
  bool    _gridView       = true;

  // Supabase real data
  List<Map<String, dynamic>> _liveProducts = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _channel = Supabase.instance.client
        .channel('shop_products')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            callback: (_) {
              AppCache.instance.invalidate(AppCache.kShopProducts);
              _loadProducts();
            })
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    // Retour immédiat depuis le cache si frais
    final cached = AppCache.instance.get<List<Map<String, dynamic>>>(AppCache.kShopProducts);
    if (cached != null && mounted) {
      setState(() { _liveProducts = cached; _loading = false; });
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select('id, name, price, promo_price, images, category, description, available, offer_tag, created_at, store_id, stores(store_name, logo_url)')
          .eq('available', true)
          .order('created_at', ascending: false)
          .limit(100);
      final list = List<Map<String, dynamic>>.from(rows as List);
      AppCache.instance.set(AppCache.kShopProducts, list);
      if (mounted) setState(() { _liveProducts = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Convert Supabase row → _Product for UI reuse
  static String? _s(dynamic v) => v is String ? v : null;
  static num?    _n(dynamic v) => v is num    ? v : null;

  _Product _fromRow(Map<String, dynamic> r) {
    final images = r['images'];
    String imgUrl = 'https://via.placeholder.com/400';
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.isNotEmpty) imgUrl = first;
    }
    final storeRaw = r['stores'];
    String storeName = '';
    if (storeRaw is Map) { storeName = _s(storeRaw['store_name']) ?? ''; }
    else if (storeRaw is List && storeRaw.isNotEmpty && storeRaw.first is Map) {
      storeName = _s(storeRaw.first['store_name']) ?? '';
    }
    final price = (_n(r['price']) ?? 0).toInt();
    final promo = _n(r['promo_price']);
    final hasPromo = promo != null && promo.toInt() < price && promo > 0;
    final createdAt = _s(r['created_at']);
    bool isNew = false;
    if (createdAt != null) {
      try {
        isNew = DateTime.now().difference(DateTime.parse(createdAt)).inDays <= 7;
      } catch (_) {}
    }
    return _Product(
      name:         _s(r['name']) ?? '',
      store:        storeName,
      price:        hasPromo ? promo.toInt() : price,
      oldPrice:     hasPromo ? price : null,
      rating:       4.5,
      reviewCount:  0,
      isPromo:      hasPromo,
      isNew:        isNew,
      sizes:        [],
      imageUrl:     imgUrl,
      category:     _mapCat(_s(r['category']) ?? ''),
      subCategory:  '',
      rawData:      r,
    );
  }

  static String _mapCat(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('femme') || c.contains('women') || c.contains('mode') || c.contains('robe')) return 'Femme';
    if (c.contains('homme') || c.contains('men')) return 'Homme';
    if (c.contains('enfant') || c.contains('kid') || c.contains('bébé') || c.contains('bebe')) return 'Enfants';
    if (c.contains('beauté') || c.contains('beauty') || c.contains('cosm')) return 'Beauté';
    if (c.contains('maison') || c.contains('deco')) return 'Maison';
    if (c.contains('sport')) return 'Sport';
    return 'Femme'; // default
  }

  List<_Product> get _allProducts =>
      _liveProducts.isNotEmpty ? _liveProducts.map(_fromRow).toList() : _kProducts;

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<_Product> get _filtered {
    var list = _allProducts.where((p) {
      if (_q.isNotEmpty &&
          !p.name.toLowerCase().contains(_q.toLowerCase()) &&
          !p.store.toLowerCase().contains(_q.toLowerCase())) {
        return false;
      }
      if (_cat != null && p.category != _cat) return false;
      if (_sub != null && p.subCategory != _sub) return false;
      if (p.price > _maxPrice) return false;
      if (_quickFilter == _qfNew && !p.isNew) return false;
      if (_quickFilter == _qfPromo && !p.isPromo) return false;
      return true;
    }).toList();

    switch (_quickFilter) {
      case _qfBestPrice: list.sort((a, b) => a.price.compareTo(b.price));
      case _qfTopRated:  list.sort((a, b) => b.rating.compareTo(a.rating));
      case _qfSellers:   list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return list;
  }

  List<_Product> get _newProducts {
    final live = _allProducts.where((p) => p.isNew).toList();
    if (live.isNotEmpty) return live;
    // fallback: show 5 most recent live products as nouveautés
    return _liveProducts.isNotEmpty
        ? _liveProducts.take(5).map(_fromRow).toList()
        : _kProducts.where((p) => p.isNew).toList();
  }

  String _fmt(int p) =>
      p >= 1000 ? '${p ~/ 1000} ${(p % 1000).toString().padLeft(3, '0')}' : '$p';

  bool get _hasActiveDetailFilter => _maxPrice < 20000;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    final showNouveautes =
        _q.isEmpty && _cat == null && _quickFilter == null && !_hasActiveDetailFilter;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      bottomNavigationBar: const AppBottomNav(activeTab: NavTab.shop),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 2),
          _buildCategories(),
          if (_cat != null) _buildSubCategories(),
          _buildQuickFilters(),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (showNouveautes) _buildNouveautes(),
                  _buildResultsBar(products.length),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    child: _gridView
                        ? _buildGrid(products)
                        : _buildList(products),
                  ),
                ],
              ),
            ),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              const Icon(Icons.search, color: AppColors.gray, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher produits, boutiques…',
                    hintStyle: GoogleFonts.montserrat(
                        color: const Color(0xFFCAC9C9), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 13),
                ),
              ),
              if (_q.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _q = '');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.close, color: AppColors.gray, size: 18),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        // Filter button — highlighted when filters active
        GestureDetector(
          onTap: _openFilterSheet,
          child: Stack(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _hasActiveDetailFilter
                    ? AppColors.nearBlack
                    : AppColors.bgGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune,
                  color: _hasActiveDetailFilter
                      ? Colors.white
                      : AppColors.nearBlack,
                  size: 20),
            ),
            if (_hasActiveDetailFilter)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return SizedBox(
      height: 36,
      child: ScrollConfiguration(
        behavior: _WebDragScroll(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: _kCategories.length,
          itemBuilder: (_, i) {
            final cat = _kCategories[i];
            final sel = _cat == cat.name;
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) { _cat = null; _sub = null; }
                else { _cat = cat.name; _sub = null; }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sel ? AppColors.nearBlack : Colors.transparent,
                  border: Border.all(
                      color: sel ? AppColors.nearBlack : AppColors.lightGray),
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.center,
                child: Text(cat.name,
                    style: GoogleFonts.montserrat(
                        color: sel ? Colors.white : AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Sub-categories ─────────────────────────────────────────────────────────

  Widget _buildSubCategories() {
    final subs = _kCategories.firstWhere((c) => c.name == _cat).subs;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 30,
        child: ScrollConfiguration(
          behavior: _WebDragScroll(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: subs.length,
            itemBuilder: (_, i) {
              final sub = subs[i];
              final sel = _sub == sub;
              return GestureDetector(
                onTap: () => setState(() => _sub = sel ? null : sub),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                        color: sel ? AppColors.accent : AppColors.lightGray),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: Text(sub,
                      style: GoogleFonts.montserrat(
                          color: sel ? AppColors.accent : AppColors.gray,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Quick filter chips ─────────────────────────────────────────────────────

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: SizedBox(
        height: 32,
        child: ScrollConfiguration(
          behavior: _WebDragScroll(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _kQuickFilters.length,
            itemBuilder: (_, i) {
              final (id, label, icon) = _kQuickFilters[i];
              final sel = _quickFilter == id;
              return GestureDetector(
                onTap: () => setState(() => _quickFilter = sel ? null : id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.nearBlack : Colors.white,
                    border: Border.all(
                        color: sel ? AppColors.nearBlack : AppColors.lightGray),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon,
                        size: 13,
                        color: sel ? Colors.white : AppColors.nearBlack),
                    const SizedBox(width: 5),
                    Text(label,
                        style: GoogleFonts.montserrat(
                            color: sel ? Colors.white : AppColors.nearBlack,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500)),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Results bar ────────────────────────────────────────────────────────────

  Widget _buildResultsBar(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
        Text('$count résultat${count != 1 ? 's' : ''}',
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 12)),
        const Spacer(),
        GestureDetector(
          onTap: _openSortSheet,
          child: Row(children: [
            const Icon(Icons.sort, size: 16, color: AppColors.nearBlack),
            const SizedBox(width: 4),
            Text('Trier',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => setState(() => _gridView = !_gridView),
          child: Icon(
              _gridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
              size: 20,
              color: AppColors.nearBlack),
        ),
      ]),
    );
  }

  // ── Nouveautés section ─────────────────────────────────────────────────────

  Widget _buildNouveautes() {
    final newProds = _newProducts;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(children: [
          Text('Nouveautés',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _quickFilter = _qfNew),
            child: Text('Voir tout',
                style: GoogleFonts.montserrat(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      SizedBox(
        height: 210,
        child: ScrollConfiguration(
          behavior: _WebDragScroll(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: newProds.length,
            itemBuilder: (_, i) {
              final p = newProds[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/product', arguments: p.toMap()),
                child: Container(
                  width: 148,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 12,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                        child: _imgWidget(p.imageUrl, width: double.infinity),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(p.name,
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${_fmt(p.price)} DA',
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 6),
      Container(height: 6, color: AppColors.bgGray),
      const SizedBox(height: 2),
    ]);
  }

  // ── Product grid ───────────────────────────────────────────────────────────

  Widget _buildGrid(List<_Product> products) {
    if (products.isEmpty) return _emptyState();
    return Column(
      children: [
        for (int i = 0; i < products.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _productCard(products[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < products.length
                      ? _productCard(products[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Product list ───────────────────────────────────────────────────────────

  Widget _buildList(List<_Product> products) {
    if (products.isEmpty) return _emptyState();
    return Column(
      children: products
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _productListTile(p),
              ))
          .toList(),
    );
  }

  // ── Product card (grid) ────────────────────────────────────────────────────

  Widget _productCard(_Product p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product', arguments: p.toMap()),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ── Image ──────────────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 0.85,
            child: Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: _imgWidget(p.imageUrl, width: double.infinity),
              ),
              // Badges
              Positioned(
                top: 8,
                left: 8,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  if (p.isPromo)
                    _badge('-${p.discount}%', AppColors.accent),
                  if (p.isNew) ...[
                    if (p.isPromo) const SizedBox(height: 4),
                    _badge('NEW', AppColors.blue),
                  ],
                ]),
              ),
              // Wishlist
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.favorite_border,
                      size: 15, color: AppColors.gray),
                ),
              ),
            ]),
          ),

          // ── Info ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(p.store,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.gold, size: 12),
                const SizedBox(width: 2),
                Text('${p.rating}',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                Text(' (${p.reviewCount})',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 10)),
              ]),
              const SizedBox(height: 5),
              Text('${_fmt(p.price)} DA',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
              if (p.oldPrice != null)
                Text('${_fmt(p.oldPrice!)} DA',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough)),
              const SizedBox(height: 8),
              // Au panier button
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: () {
                    CartService.instance.addProduct(p.toMap());
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${p.name} ajouté au panier !',
                          style: GoogleFonts.montserrat(fontSize: 12)),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.nearBlack,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(12),
                    ));
                  },
                  icon: const Icon(Icons.add_shopping_cart_outlined,
                      size: 13, color: Colors.white),
                  label: Text('Au panier',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nearBlack,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Product list tile ──────────────────────────────────────────────────────

  Widget _productListTile(_Product p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product', arguments: p.toMap()),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imgWidget(p.imageUrl, width: 100, height: 100),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (p.isPromo || p.isNew)
              Row(children: [
                if (p.isPromo) _badge('-${p.discount}%', AppColors.accent),
                if (p.isNew) ...[
                  if (p.isPromo) const SizedBox(width: 6),
                  _badge('NEW', AppColors.blue),
                ],
              ]),
            if (p.isPromo || p.isNew) const SizedBox(height: 4),
            Text(p.name,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(p.store,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 11)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
              Text(' ${p.rating} (${p.reviewCount})',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Text('${_fmt(p.price)} DA',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              if (p.oldPrice != null) ...[
                const SizedBox(width: 8),
                Text('${_fmt(p.oldPrice!)} DA',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough)),
              ],
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: () {
                  CartService.instance.addProduct(p.toMap());
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${p.name} ajouté au panier !',
                        style: GoogleFonts.montserrat(fontSize: 12)),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.nearBlack,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                },
                icon: const Icon(Icons.add_shopping_cart_outlined,
                    size: 13, color: Colors.white),
                label: Text('Au panier',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nearBlack,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Image helper (asset ou réseau) ────────────────────────────────────────

  Widget _imgWidget(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final ph = Container(
      width: width, height: height,
      color: AppColors.bgGray,
      child: const Icon(Icons.image_outlined, color: AppColors.lightGray, size: 32),
    );
    if (url.startsWith('http')) {
      return Image.network(url, width: width, height: height, fit: fit,
          errorBuilder: (_, __, ___) => ph);
    }
    return Image.asset(url, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => ph);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(5)),
        child: Text(text,
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800)),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_off_outlined,
                size: 56, color: AppColors.lightGray),
            const SizedBox(height: 12),
            Text('Aucun produit trouvé',
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 14)),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() {
                _q = '';
                _cat = null;
                _sub = null;
                _quickFilter = null;

                _maxPrice = 20000;
                _searchCtrl.clear();
              }),
              child: Text('Réinitialiser les filtres',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      );

  // ── Filter sheet ───────────────────────────────────────────────────────────

  void _openFilterSheet() {
    double tmpMax = _maxPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.74,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
              child: Row(children: [
                Text('Filtres',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                  onPressed: () => setS(() => tmpMax = 20000),
                  child: Text('Réinitialiser',
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 13)),
                ),
              ]),
            ),
            const Divider(color: AppColors.lightGray),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                children: [
                  // Prix max
                  Row(children: [
                    Text('Prix maximum',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${_fmt(tmpMax.toInt())} DA',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ]),
                  Slider(
                    value: tmpMax,
                    min: 500,
                    max: 20000,
                    divisions: 39,
                    activeColor: AppColors.nearBlack,
                    inactiveColor: AppColors.lightGray,
                    onChanged: (v) => setS(() => tmpMax = v),
                  ),
                  Row(children: [
                    Text('500 DA',
                        style: GoogleFonts.montserrat(
                            color: AppColors.gray, fontSize: 11)),
                    const Spacer(),
                    Text('20 000 DA',
                        style: GoogleFonts.montserrat(
                            color: AppColors.gray, fontSize: 11)),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() { _maxPrice = tmpMax; });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nearBlack,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Appliquer les filtres',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  // ── Sort sheet ─────────────────────────────────────────────────────────────

  void _openSortSheet() {
    const options = [
      (null,         'Pertinence'),
      (_qfBestPrice, 'Prix croissant'),
      (_qfTopRated,  'Mieux notés'),
      (_qfNew,       'Nouveautés'),
      (_qfPromo,     'En promo'),
      (_qfSellers,   'Best sellers'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Trier par',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          ...options.map((e) {
            final (id, label) = e;
            final sel = _quickFilter == id;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 14,
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.normal)),
              trailing: sel
                  ? const Icon(Icons.check_circle,
                      color: AppColors.nearBlack, size: 20)
                  : null,
              onTap: () {
                setState(() => _quickFilter = id);
                Navigator.pop(context);
              },
            );
          }),
        ]),
      ),
    );
  }
}
