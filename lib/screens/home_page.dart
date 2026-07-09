import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';
import '../services/cart_service.dart';
import '../widgets/app_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _stores   = [];
  List<Map<String, dynamic>> _posts    = [];
  bool _loading  = true;
  String _selCat = 'Tous';
  late final RealtimeChannel _homeChannel;

  static const _cats = [
    'Tous', 'Mode', 'Beauté', 'Électronique',
    'Maison', 'Sport', 'Bijoux', 'Accessoires',
  ];

  @override
  void initState() {
    super.initState();
    _homeChannel = Supabase.instance.client.channel('home-feed-live');
    _subscribeToRealtime();
    _load();
  }

  @override
  void dispose() {
    _homeChannel.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    _homeChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'products',
      callback: (_) => _load(silent: true),
    );
    _homeChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'stores',
      callback: (_) => _load(silent: true),
    );
    _homeChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'store_posts',
      callback: (_) => _load(silent: true),
    );
    _homeChannel.subscribe();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final client = Supabase.instance.client;
    try {
      // Fetch products, stores, posts in parallel — no intermediate lookup
      const prodColsFull = 'id, name, price, promo_price, images, category, '
          'available, sold_count, rating, offer_tag, '
          'description, subcategory, reviews_count, created_at, store_id, '
          'size_variants, color_variants, stock_qty, '
          'stores(id, store_name, logo_url, rating, reviews_count, '
          'followers_count, is_verified, owner_id)';
      const prodColsBase = 'id, name, price, promo_price, images, category, '
          'available, sold_count, rating, '
          'description, subcategory, reviews_count, created_at, store_id, '
          'stores(id, store_name, logo_url, rating, reviews_count, '
          'followers_count, is_verified, owner_id)';

      List<dynamic> prodRows;
      try {
        prodRows = await client.from('products').select(prodColsFull)
            .eq('available', true).order('created_at', ascending: false).limit(60);
      } catch (_) {
        prodRows = await client.from('products').select(prodColsBase)
            .eq('available', true).order('created_at', ascending: false).limit(60);
      }

      final results = await Future.wait([
        Future.value(prodRows),
        client
            .from('stores')
            .select('id, owner_id, store_name, logo_url, rating, '
                'followers_count, is_verified, products_count, category')
            .order('followers_count', ascending: false)
            .limit(30),
        client
            .from('store_posts')
            .select('id, store_id, post_type, caption, media_urls, cover_url, '
                'created_at, product_name, price, promo_price, '
                'likes_count, comments_count, views_count')
            .order('created_at', ascending: false)
            .limit(20),
      ]);

      if (mounted) {
        setState(() {
          _products = results[0].map((r) => Map<String, dynamic>.from(r as Map)).toList();
          _stores   = results[1].map((r) => Map<String, dynamic>.from(r as Map)).toList();
          _posts    = results[2].map((r) => Map<String, dynamic>.from(r as Map)).toList();
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selCat == 'Tous') return _products;
    return _products.where((p) {
      final cat = (p['category'] as String? ?? '').toLowerCase();
      return cat.contains(_selCat.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.current;
    final name = user.displayName.isNotEmpty
        ? user.displayName.split(' ').first
        : 'Lincoo';

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Bonjour 👋',
                            style: GoogleFonts.montserrat(
                                color: AppColors.grayLight, fontSize: 12)),
                        Text(name,
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/cart'),
                      child: Stack(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.bgGray,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: AppColors.nearBlack, size: 22),
                        ),
                        ValueListenableBuilder<List<CartItem>>(
                          valueListenable: CartService.instance.notifier,
                          builder: (_, items, __) => items.isEmpty
                              ? const SizedBox.shrink()
                              : Positioned(
                                  top: 0, right: 0,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${items.length}',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  )),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.bgGray,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.grayLight, size: 20),
                      const SizedBox(width: 10),
                      Text('Rechercher des produits...',
                          style: GoogleFonts.montserrat(
                              color: AppColors.grayLight, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Category chips ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  itemCount: _cats.length,
                  itemBuilder: (_, i) {
                    final cat = _cats[i];
                    final sel = cat == _selCat;
                    return GestureDetector(
                      onTap: () => setState(() => _selCat = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.nearBlack
                              : AppColors.bgGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat,
                            style: GoogleFonts.montserrat(
                                color: sel ? Colors.white : AppColors.gray,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Loader ───────────────────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent)),
                ),
              )
            else ...[
              // ── Nouveautés ─────────────────────────────────────────────────
              if (_filtered.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(children: [
                      Text('Nouveautés',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/feed'),
                        child: Text('Voir tout',
                            style: GoogleFonts.montserrat(
                                color: AppColors.blue, fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: _filtered.take(12).length,
                      itemBuilder: (_, i) =>
                          _ProductCard(product: _filtered[i]),
                    ),
                  ),
                ),
              ],

              // ── Boutiques populaires ────────────────────────────────────────
              if (_stores.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Boutiques populaires',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 108,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: _stores.length,
                      itemBuilder: (_, i) => _StoreChip(store: _stores[i]),
                    ),
                  ),
                ),
              ],

              // ── Pour vous (grid) ───────────────────────────────────────────
              if (_filtered.length > 4) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Pour vous',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final prods = _filtered.skip(4).toList();
                        if (i >= prods.length) return null;
                        return _ProductGridCard(product: prods[i]);
                      },
                      childCount: (_filtered.length - 4).clamp(0, 20),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                  ),
                ),
              ],

              if (_posts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Posts récents',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: _posts.length,
                      itemBuilder: (_, i) => _PostCard(post: _posts[i]),
                    ),
                  ),
                ),
              ],

              // ── Empty state ────────────────────────────────────────────────
              if (_filtered.isEmpty && _stores.isEmpty && _posts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Column(children: [
                      const Icon(Icons.store_outlined,
                          color: AppColors.lightGray, size: 52),
                      const SizedBox(height: 12),
                      Text('Aucun produit pour le moment',
                          style: GoogleFonts.montserrat(
                              color: AppColors.gray, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('Revenez bientôt !',
                          style: GoogleFonts.montserrat(
                              color: AppColors.grayLight, fontSize: 12)),
                    ]),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: NavTab.feed),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal product card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  static T? _s<T>(dynamic v) => v is T ? v : null;

  @override
  Widget build(BuildContext context) {
    final name  = _s<String>(product['name'])  ?? '';
    final price = (_s<num>(product['price'])   ?? 0).toDouble();
    final promo = _s<num>(product['promo_price'])?.toDouble();
    final tag   = _s<String>(product['offer_tag']);
    final imgs  = product['images'];
    String? img;
    if (imgs is List && imgs.isNotEmpty && imgs.first is String) {
      img = imgs.first as String;
    }
    final fmt = (promo ?? price).toStringAsFixed(0);
    final fmtStr = fmt.length > 3
        ? '${fmt.substring(0, fmt.length - 3)} ${fmt.substring(fmt.length - 3)}'
        : fmt;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/product', arguments: product),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: img != null
                  ? Image.network(img,
                      width: 150, height: 150, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback())
                  : _imgFallback(),
            ),
            if (tag != null)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag,
                      style: GoogleFonts.montserrat(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: AppColors.nearBlack)),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text(name,
              style: GoogleFonts.montserrat(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Text('$fmtStr DA',
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack)),
            if (promo != null && price > promo) ...[
              const SizedBox(width: 5),
              Text('${price.toStringAsFixed(0)} DA',
                  style: GoogleFonts.montserrat(
                      fontSize: 10, color: AppColors.grayLight,
                      decoration: TextDecoration.lineThrough)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 150, height: 150,
        decoration: BoxDecoration(
            color: AppColors.bgGray,
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.image_outlined,
            color: AppColors.lightGray, size: 36),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid product card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductGridCard({required this.product});

  static T? _s<T>(dynamic v) => v is T ? v : null;

  @override
  Widget build(BuildContext context) {
    final name  = _s<String>(product['name'])  ?? '';
    final price = (_s<num>(product['price'])   ?? 0).toDouble();
    final promo = _s<num>(product['promo_price'])?.toDouble();
    final tag   = _s<String>(product['offer_tag']);
    final storeRaw = product['stores'];
    String storeName = '';
    if (storeRaw is Map) storeName = storeRaw['store_name'] as String? ?? '';
    final imgs  = product['images'];
    String? img;
    if (imgs is List && imgs.isNotEmpty && imgs.first is String) {
      img = imgs.first as String;
    }
    final display = promo ?? price;
    final fmt = display.toStringAsFixed(0);
    final fmtStr = fmt.length > 3
        ? '${fmt.substring(0, fmt.length - 3)} ${fmt.substring(fmt.length - 3)}'
        : fmt;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/product', arguments: product),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: img != null
                  ? Image.network(img,
                      width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: AppColors.bgGray,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.lightGray, size: 36)))
                  : Container(
                      color: AppColors.bgGray,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.lightGray, size: 36)),
            ),
            if (tag != null)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag,
                      style: GoogleFonts.montserrat(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: AppColors.nearBlack)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        if (storeName.isNotEmpty)
          Text(storeName,
              style: GoogleFonts.montserrat(
                  fontSize: 10, color: AppColors.grayLight),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(name,
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.nearBlack),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('$fmtStr DA',
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: AppColors.nearBlack)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post card
// ─────────────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final caption = post['caption'] as String? ?? '';
    final media = post['media_urls'];
    String? imageUrl;
    if (media is List && media.isNotEmpty && media.first is String) {
      imageUrl = media.first as String;
    }
    final cover = post['cover_url'] as String? ?? imageUrl;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: cover != null
              ? Image.network(cover,
                  width: 180,
                  height: 95,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 180,
                      height: 95,
                      color: AppColors.bgGray,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.lightGray, size: 28)))
              : Container(
                  width: 180,
                  height: 95,
                  color: AppColors.bgGray,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.lightGray, size: 28)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(caption.isNotEmpty ? caption : 'Publication récente',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text((post['post_type'] as String? ?? 'post').toUpperCase(),
                style: GoogleFonts.montserrat(
                    color: AppColors.grayLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Store chip
// ─────────────────────────────────────────────────────────────────────────────

class _StoreChip extends StatelessWidget {
  final Map<String, dynamic> store;
  const _StoreChip({required this.store});

  @override
  Widget build(BuildContext context) {
    final name     = store['store_name'] as String? ?? '';
    final logo     = store['logo_url']   as String?;
    final verified = store['is_verified'] == true;
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    final storeId = store['id'] as String?;

    return GestureDetector(
      onTap: storeId == null
          ? null
          : () => Navigator.pushNamed(context, '/store',
              arguments: storeId),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: logo != null
                  ? Image.network(logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _initials(initials))
                  : _initials(initials),
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text(name,
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ),
            if (verified) ...[
              const SizedBox(width: 2),
              const Icon(Icons.verified_rounded,
                  color: AppColors.blue, size: 10),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _initials(String txt) => Container(
        color: AppColors.bgGray,
        child: Center(
          child: Text(txt,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ),
      );
}
