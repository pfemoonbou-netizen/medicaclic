import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/store_model.dart';
import '../services/user_session.dart';
import '../models/app_user.dart';

const _demoProducts = [
  StoreProduct(id: 'p1', storeId: 'demo', name: 'SUMMER LOOLET SCRAF',     price: 5900, promoPrice: 7500, images: ['https://via.placeholder.com/400'], rating: 4.9, soldCount: 325),
  StoreProduct(id: 'p2', storeId: 'demo', name: 'LOOLET CHEMISE ÉTÉ',       price: 4500, promoPrice: 5800, images: ['https://via.placeholder.com/400'], rating: 4.7, soldCount: 198),
  StoreProduct(id: 'p3', storeId: 'demo', name: 'LOOLET ROBE SOIRÉE',        price: 6200, promoPrice: 8000, images: ['https://via.placeholder.com/400'], rating: 4.8, soldCount: 87),
  StoreProduct(id: 'p4', storeId: 'demo', name: 'LOOLET BLOUSE FLORALE',     price: 3800,                  images: ['https://via.placeholder.com/400'], rating: 4.6, soldCount: 143),
  StoreProduct(id: 'p5', storeId: 'demo', name: 'FOULARD SATINÉ',            price: 2200,                  images: ['https://via.placeholder.com/400'], rating: 4.5, soldCount: 56),
  StoreProduct(id: 'p6', storeId: 'demo', name: 'LOOLET SET CASUAL',         price: 7400, promoPrice: 9000, images: ['https://via.placeholder.com/400'], rating: 5.0, soldCount: 212),
];

final _demoPosts = [
  StorePost(id: 'post1', storeId: 'demo', type: 'classic',    caption: 'Nouvelle collection été 🌸',         mediaUrls: const ['https://via.placeholder.com/400'], likesCount: 142, commentsCount: 38, createdAt: DateTime.now().subtract(const Duration(hours: 2))),
  StorePost(id: 'post2', storeId: 'demo', type: 'commercial', caption: 'PROMO −30% sur les foulards 🔥',     mediaUrls: const ['https://via.placeholder.com/400'], productName: 'FOULARD SATINÉ', price: 2200, promoPrice: 3200, likesCount: 312, commentsCount: 91, createdAt: DateTime.now().subtract(const Duration(hours: 8))),
  StorePost(id: 'post3', storeId: 'demo', type: 'classic',    caption: 'Arrivage : blouses printanières',   mediaUrls: const ['https://via.placeholder.com/400'], likesCount: 98,  commentsCount: 22, createdAt: DateTime.now().subtract(const Duration(days: 1))),
  StorePost(id: 'post4', storeId: 'demo', type: 'commercial', caption: 'Tenues soirée Ramadan ✨',           mediaUrls: const ['https://via.placeholder.com/400'], productName: 'LOOLET ROBE SOIRÉE', price: 6200, promoPrice: 8000, likesCount: 234, commentsCount: 67, createdAt: DateTime.now().subtract(const Duration(days: 2))),
];

final _demoReels = [
  StorePost(id: 'r1', storeId: 'demo', type: 'reel', caption: 'Look été 2026 🌸 #mode #algérie', mediaUrls: const ['https://via.placeholder.com/400'], viewsCount: 12400, likesCount: 843, createdAt: DateTime.now().subtract(const Duration(days: 3))),
  StorePost(id: 'r2', storeId: 'demo', type: 'reel', caption: 'Collection Ramadan ✨',           mediaUrls: const ['https://via.placeholder.com/400'], viewsCount: 8900,  likesCount: 612, productName: 'LOOLET ROBE SOIRÉE', price: 6200, createdAt: DateTime.now().subtract(const Duration(days: 5))),
  StorePost(id: 'r3', storeId: 'demo', type: 'reel', caption: 'Nouvelle arrivée 🎀',             mediaUrls: const ['https://via.placeholder.com/400'], viewsCount: 5300,  likesCount: 398, createdAt: DateTime.now().subtract(const Duration(days: 7))),
  StorePost(id: 'r4', storeId: 'demo', type: 'reel', caption: 'Promo foulards −30% 🔥',         mediaUrls: const ['https://via.placeholder.com/400'], viewsCount: 19800, likesCount: 1240, productName: 'FOULARD SATINÉ', price: 2200, createdAt: DateTime.now().subtract(const Duration(days: 10))),
  StorePost(id: 'r5', storeId: 'demo', type: 'reel', caption: 'Style casual chic 💫',           mediaUrls: const ['https://via.placeholder.com/400'], viewsCount: 7200,  likesCount: 520, createdAt: DateTime.now().subtract(const Duration(days: 12))),
  StorePost(id: 'r6', storeId: 'demo', type: 'reel', caption: 'Tenues de soirée 🌙',            mediaUrls: const ['https://via.placeholder.com/400'], viewsCount: 11300, likesCount: 745, createdAt: DateTime.now().subtract(const Duration(days: 15))),
];



class StoreProfilePage extends StatefulWidget {
  const StoreProfilePage({super.key});
  @override
  State<StoreProfilePage> createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends State<StoreProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _isOwner      = false;
  bool _isFollowing  = false;
  bool _loading      = true;
  String? _storeId;
  String? _sellerPackType; // 'starter' | 'pro' | 'business' | null

  // Seller's real profile data (from profiles table, overrides stores table)
  String? _sellerAvatarUrl;
  String? _sellerRealUsername;
  String? _sellerStoreName;

  StoreData          _store    = StoreData.demo;
  List<StoreProduct> _products = [];
  List<StorePost>    _posts    = [];
  List<StorePost>    _reels    = [];
  double _storeAverageRating = 0;
  int _storeReviewsCount = 0;
  List<Map<String, dynamic>> _storeReviews = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) return; // already loaded
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) {
      _storeId = arg;
    } else if (arg is Map) {
      _storeId = arg['storeId'] as String?;
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Map<String, dynamic> _productArgsFor(StoreProduct p) => {
        'id': p.id,
        'name': p.name,
        'description': 'Produit disponible dans cette boutique',
        'price': p.price,
        'promo_price': p.promoPrice,
        'images': p.images.isEmpty ? ['https://via.placeholder.com/400'] : p.images,
        'category': _store.category ?? 'Mode',
        'rating': p.rating,
        'reviews_count': 24,
        'sold_count': p.soldCount,
        // IMPORTANT: product page needs variants/stock.
        // If your DB has size_variants / color_variants, they are sent from store_profile_page
        // through StoreProduct model (if implemented). Otherwise, they remain empty.
        'stock_qty': p.available ? 10 : 0,
        // Variants from products table (size_variants / color_variants)
        'size_variants': p.sizeVariants,
        'color_variants': p.colorVariants,


        'stores': {
          'id': _store.id,
          'store_name': _store.storeName,
          'logo_url': _store.logoUrl,
          'rating': 4.8,
          'followers_count': _store.followersCount,
          'is_verified': _store.isVerified,
        },
      };


  Map<String, dynamic> _productArgsForPost(StorePost post) => {
        'id': post.productId ?? post.id,
        'name': post.productName ?? 'Produit',
        'description': post.caption ?? 'Produit disponible dans cette boutique',
        'price': post.price ?? 0,
        'promo_price': post.promoPrice,
        'images': post.mediaUrls.isEmpty ? ['https://via.placeholder.com/400'] : post.mediaUrls,
        'category': _store.category ?? 'Mode',
        'rating': 4.7,
        'reviews_count': 24,
        'sold_count': 120,
        'stock_qty': 10,
        // Variants from product table would be required here if you want
        // the same size/color selector for posts that open the /product route.
        // For now keep empty unless you extend StorePost/ProductDetails pipeline.
        'size_variants': const [],
        'color_variants': const [],


        'stores': {
          'id': _store.id,
          'store_name': _store.storeName,
          'logo_url': _store.logoUrl,
          'rating': 4.8,
          'followers_count': _store.followersCount,
          'is_verified': _store.isVerified,
        },
      };


  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final user = UserSession.instance.current;
    try {
      final client = Supabase.instance.client;
      Map<String, dynamic>? storeMap;

      if (_storeId != null) {
        storeMap = await client
            .from('stores')
            .select()
            .eq('id', _storeId!)
            .maybeSingle();
      } else {
        storeMap = await client
            .from('stores')
            .select()
            .eq('owner_id', user.id)
            .maybeSingle();
      }

      if (storeMap != null) {
        final store = StoreData.fromMap(storeMap);
        final isOwner = store.ownerId == user.id;

        // Load products
        final prodMaps = await client
            .from('products')
            .select()
            .eq('store_id', store.id)
            .order('created_at', ascending: false);
        final products = (prodMaps as List)
            .map((m) => StoreProduct.fromMap(m as Map<String, dynamic>))
            .toList();

        // Load posts (classic + commercial)
        final postMaps = await client
            .from('store_posts')
            .select()
            .eq('store_id', store.id)
            .inFilter('post_type', ['classic', 'commercial'])
            .order('created_at', ascending: false);
        final posts = (postMaps as List)
            .map((m) => StorePost.fromMap(m as Map<String, dynamic>))
            .toList();

        // Load reels
        final reelMaps = await client
            .from('store_posts')
            .select()
            .eq('store_id', store.id)
            .eq('post_type', 'reel')
            .order('created_at', ascending: false);
        final reels = (reelMaps as List)
            .map((m) => StorePost.fromMap(m as Map<String, dynamic>))
            .toList();

        // Check if following
        bool following = false;
        if (!isOwner && !user.isGuest) {
          final f = await client
              .from('store_follows')
              .select()
              .eq('follower_id', user.id)
              .eq('store_id', store.id)
              .maybeSingle();
          following = f != null;
        }

        // Load store reviews summary and recent comments
        double averageRating = 0;
        int reviewCount = 0;
        List<Map<String, dynamic>> recentReviews = [];
        try {
          final reviewMaps = await client
              .from('store_reviews')
              .select('id, reviewer_id, rating, comment, created_at')
              .eq('store_id', store.id)
              .order('created_at', ascending: false);

          final reviews = (reviewMaps as List)
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList();

          if (reviews.isNotEmpty) {
            final ratings = reviews
                .map((review) => (review['rating'] as num?)?.toDouble() ?? 0)
                .toList();
            averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }

          reviewCount = reviews.length;
          for (final review in reviews.take(3)) {
            String reviewerName = 'Client';
            String? reviewerAvatar;
            try {
              final profileData = await client
                  .from('profiles')
                  .select('full_name, username, avatar_url')
                  .eq('id', review['reviewer_id'])
                  .maybeSingle();
              if (profileData != null) {
                reviewerName = (profileData['full_name'] as String?) ??
                    (profileData['username'] as String?) ??
                    reviewerName;
                reviewerAvatar = profileData['avatar_url'] as String?;
              }
            } catch (_) {}

            recentReviews.add({
              ...review,
              'reviewer_name': reviewerName,
              'reviewer_avatar_url': reviewerAvatar,
            });
          }
        } catch (_) {}

        // Load seller profile snapshot (AVATAR/USERNAME/ADDRESS/BIO) from profiles only.
        // Important: never use current session user data here, otherwise buyers will see their own details.
        String? sellerAvatar;
        String? sellerRealUsername;
        String? sellerStoreName;

        try {
          final profileData = await client
              .from('profiles')
              .select(
                'avatar_url, store_name, full_name, nom_complet, username, handle, address, wilaya, bio, store_bio'
              )
              .eq('id', store.ownerId)
              .maybeSingle();

          if (profileData != null) {
            sellerAvatar       = profileData['avatar_url'] as String?;
            sellerStoreName    = (profileData['store_name'] as String?) ?? (profileData['full_name'] as String?);

            // Username/handle: try multiple possible columns
            sellerRealUsername =
                (profileData['username'] as String?) ??
                (profileData['handle'] as String?) ??
                (profileData['full_name'] as String?);

          }
        } catch (_) {}

        // Load seller's active pack to show the right badge
        String? packType;
        try {
          final packRow = await client
              .from('seller_packs')
              .select('pack_type')
              .eq('seller_id', store.ownerId)
              .eq('status', 'active')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          packType = packRow?['pack_type'] as String?;
        } catch (_) {}

        if (mounted) {
          setState(() {
            _store              = store;
            _isOwner            = isOwner;
            _sellerPackType     = packType;
            _isFollowing        = following;
            _products           = products;
            _posts              = posts;
            _reels              = reels;
            _sellerAvatarUrl    = sellerAvatar;
            _sellerRealUsername = sellerRealUsername;
            _sellerStoreName    = sellerStoreName;
            _storeAverageRating = averageRating;
            _storeReviewsCount  = reviewCount;
            _storeReviews       = recentReviews;

            _loading            = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback to demo data
    if (mounted) {
      setState(() {
        _store              = StoreData.demo;
        _isOwner            = _storeId == null && user.proRole == ProRole.seller;
        _products           = _demoProducts;
        _posts              = _demoPosts;
        _reels              = _demoReels;
        _storeAverageRating = 0;
        _storeReviewsCount  = 0;
        _storeReviews       = [];
        _loading            = false;
      });
    }
  }

  // ─── Follow / Unfollow ────────────────────────────────────────────────────

  Future<void> _toggleFollow() async {
    final user = UserSession.instance.current;
    if (user.isGuest) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _isFollowing = !_isFollowing);
    try {
      final client = Supabase.instance.client;
      if (_isFollowing) {
        await client.rpc('follow_store', params: {'p_store_id': _store.id});
      } else {
        await client.rpc('unfollow_store', params: {'p_store_id': _store.id});
      }
    } catch (_) {}
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                _buildCoverSliver(),
                _buildInfoSliver(),
                _buildTabBarSliver(),
              ],
              body: TabBarView(
                controller: _tabs,
                children: [
                  _buildProductsTab(),
                  _buildPublicationsTab(),
                  _buildReelsTab(),
                ],
              ),
            ),
      floatingActionButton: _isOwner ? _buildOwnerFab() : null,
    );
  }

  // ─── App Bar Sliver (no cover) ────────────────────────────────────────────

  SliverAppBar _buildCoverSliver() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.nearBlack, size: 18),
      ),
      title: Text(_sellerStoreName ?? _store.storeName,
          style: GoogleFonts.montserrat(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: AppColors.nearBlack)),
      centerTitle: true,
      actions: [
        if (_isOwner)
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.nearBlack, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        IconButton(
          icon: const Icon(Icons.share_outlined,
              color: AppColors.nearBlack, size: 22),
          onPressed: _shareProfile,
        ),
        if (!_isOwner)
          IconButton(
            icon: const Icon(Icons.more_horiz,
                color: AppColors.nearBlack, size: 22),
            onPressed: _showMoreSheet,
          ),
        if (_isOwner)
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.nearBlack, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
      ],
    );
  }

  // ─── Info Sliver ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildInfoSliver() {
    final storeName = _sellerStoreName ?? _store.storeName;
    final username  = (_sellerRealUsername ?? _store.username);
    final photoUrl  = _sellerAvatarUrl ?? _store.logoUrl;
    final rating    = _storeAverageRating;

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Logo + Name + Username ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar / Logo
              Container(
                width: 82, height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.nearBlack,
                  border: Border.all(
                      color: _packBorderColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: _packBorderColor.withValues(alpha: 0.25),
                        blurRadius: 14, offset: const Offset(0, 4))
                  ],
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.startsWith('http')
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarInitials())
                      : _avatarInitials(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Store name + verified
                  Row(children: [
                    Flexible(
                      child: Text(storeName,
                          style: GoogleFonts.montserrat(
                              fontSize: 18, fontWeight: FontWeight.w900,
                              color: AppColors.nearBlack),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (_store.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified,
                          color: AppColors.blue, size: 18),
                    ],
                  ]),
                  // Username
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('@$username',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: AppColors.gray)),
                  ],
                  const SizedBox(height: 8),
                  // Badge row: Vendeur tag + pack badge + category
                  Wrap(runSpacing: 4, spacing: 6, children: [
                    _badge('Vendeur', AppColors.nearBlack, Colors.white),
                    if (_sellerPackType == 'business')
                      _badge('Lincoo+ 💎', const Color(0xFFFFB800),
                          AppColors.nearBlack),
                    if (_sellerPackType == 'pro')
                      _badge('Pro ⭐', const Color(0xFF8B5CF6), Colors.white),
                    if (_store.category != null && _store.category!.isNotEmpty)
                      _badge(_store.category!, AppColors.bgGray,
                          AppColors.nearBlack),
                  ]),
                  // Location
                  if ((_store.wilaya ?? _store.address) != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.gray),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                            _store.address ?? _store.wilaya ?? '',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: AppColors.gray),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ]),
              ),
            ]),
          ),

          // ── Bio ───────────────────────────────────────────────────────────
          if (_store.bio != null && _store.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(_store.bio!,
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: AppColors.nearBlack, height: 1.5)),
            ),

          // ── Website link ──────────────────────────────────────────────────
          if (_store.website != null && _store.website!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                const Icon(Icons.link, size: 13, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(_store.website!,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: AppColors.accent,
                        fontWeight: FontWeight.w600)),
              ]),
            ),

          // ── Stats row: Abonnés | Produits | Note /5 ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IntrinsicHeight(
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showFollowers,
                      child: _statCol(
                          _fmt(_store.followersCount), 'Abonnés',
                          tapHint: true),
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                      child: _statCol(
                          _fmt(_store.productsCount), 'Produits')),
                  _vDivider(),
                  Expanded(
                    child: _statCol(
                      rating > 0
                          ? '${rating.toStringAsFixed(1)}/5'
                          : '—',
                      'Note',
                      icon: rating > 0
                          ? const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14)
                          : null,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _isOwner ? _ownerActions() : _visitorActions(),
          ),

          // ── Reviews summary (collapsible) ─────────────────────────────────
          if (_storeReviews.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _reviewsSummary(),
            ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ─── Tab bar sliver ───────────────────────────────────────────────────────

  SliverPersistentHeader _buildTabBarSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabs,
          labelColor: AppColors.nearBlack,
          unselectedLabelColor: AppColors.gray,
          labelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500, fontSize: 13),
          indicatorColor: AppColors.accent,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Produits'),
            Tab(text: 'Publications'),
            Tab(text: 'Reels'),
          ],
        ),
      ),
    );
  }

  // ─── Publications tab ─────────────────────────────────────────────────────

  Widget _buildPublicationsTab() {
    if (_posts.isEmpty) return _emptyTab(Icons.grid_view, 'Aucune publication');
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.85,
      ),
      itemCount: _posts.length,
      itemBuilder: (_, i) => _postCard(_posts[i]),
    );
  }

  Widget _postCard(StorePost p) {
    return GestureDetector(
      onTap: () => _showPostDetail(p),
      child: Stack(fit: StackFit.expand, children: [
        // Image
        p.hasMedia
            ? _img(p.mediaUrls.first,
                placeholder: Container(color: AppColors.dark))
            : Container(
                color: AppColors.dark,
                child: Center(
                  child: Text(p.caption ?? '',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
        // Gradient bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
              ),
            ),
            child: Row(children: [
              const Icon(Icons.favorite, color: Colors.white, size: 12),
              const SizedBox(width: 3),
              Text(_fmt(p.likesCount),
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        // Commercial badge
        if (p.isCommercial)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${p.promoPrice != null ? _formatPrice(p.promoPrice!) : _formatPrice(p.price!)} DA',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        // Multiple images icon
        if (p.mediaUrls.length > 1)
          const Positioned(top: 8, left: 8,
              child: Icon(Icons.collections, color: Colors.white, size: 18)),
      ]),
    );
  }

  // ─── Products tab ─────────────────────────────────────────────────────────

  Widget _buildProductsTab() {
    if (_products.isEmpty) return _emptyTab(Icons.inventory_2_outlined, 'Aucun produit');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.70,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => _productCard(_products[i]),
    );
  }

  Widget _productCard(StoreProduct p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product', arguments: _productArgsFor(p)),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(fit: StackFit.expand, children: [
                p.images.isNotEmpty
                    ? _img(p.images.first)
                    : Container(color: AppColors.bgGray,
                        child: const Icon(Icons.image_outlined, color: AppColors.lightGray, size: 40)),
                // Discount badge
                if (p.promoPrice != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('−${p.discountPercent}%',
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                // Unavailable overlay
                if (!p.available)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Text('Épuisé',
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Text('${_formatPrice(p.promoPrice ?? p.price)} DA',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: p.promoPrice != null ? Colors.red : AppColors.nearBlack)),
                if (p.promoPrice != null) ...[
                  const SizedBox(width: 5),
                  Text('${_formatPrice(p.price)} DA',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: AppColors.gray,
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, color: Color(0xFFFFC107), size: 12),
                const SizedBox(width: 3),
                Text(p.rating.toStringAsFixed(1),
                    style: GoogleFonts.montserrat(
                        fontSize: 10, color: AppColors.gray)),
                const Spacer(),
                Text('${_fmt(p.soldCount)} ventes',
                    style: GoogleFonts.montserrat(
                        fontSize: 9, color: AppColors.gray)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── Reels tab ────────────────────────────────────────────────────────────

  Widget _buildReelsTab() {
    if (_reels.isEmpty) return _emptyTab(Icons.video_collection_outlined, 'Aucun reel');
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.55,
      ),
      itemCount: _reels.length,
      itemBuilder: (_, i) => _reelCard(_reels[i]),
    );
  }

  Widget _reelCard(StorePost r) {
    return GestureDetector(
      onTap: () => _showReelDetail(r),
      child: Stack(fit: StackFit.expand, children: [
        // Thumbnail
        r.hasMedia
            ? _img(r.mediaUrls.first,
                placeholder: Container(color: AppColors.dark))
            : Container(color: AppColors.dark),
        // Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
            ),
          ),
        ),
        // Views
        Positioned(
          bottom: 6, left: 6,
          child: Row(children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 12),
            const SizedBox(width: 2),
            Text(_fmt(r.viewsCount),
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
        // Commercial bag icon
        if (r.isCommercial || r.productName != null)
          const Positioned(
            top: 6, right: 6,
            child: Icon(Icons.shopping_bag, color: Colors.white, size: 14),
          ),
      ]),
    );
  }

  // ─── FAB (owner) ──────────────────────────────────────────────────────────

  Widget _buildOwnerFab() {
    return FloatingActionButton(
      onPressed: _showAddMenu,
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.nearBlack,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );
  }

  // ─── Action rows ──────────────────────────────────────────────────────────

  Widget _ownerActions() => Row(children: [
    Expanded(
      child: _gradientBtn('Modifier le profil', Icons.edit_outlined,
          () => _showEditProfile()),
    ),
    const SizedBox(width: 10),
    _iconBtn(Icons.bar_chart_outlined, () => Navigator.pushNamed(context, '/dashboard')),
    const SizedBox(width: 8),
    _iconBtn(Icons.inventory_2_outlined, () {}),
  ]);

  Widget _visitorActions() => Row(children: [
    Expanded(
      child: _isFollowing
          ? _outlineBtn('Abonné', Icons.check, _toggleFollow)
          : _gradientBtn("S'abonner", Icons.add, _toggleFollow),
    ),
    const SizedBox(width: 8),
    _iconBtn(Icons.chat_bubble_outline_rounded,
        () => Navigator.pushNamed(context, '/messages')),
    const SizedBox(width: 8),
    _iconBtn(Icons.share_outlined, _shareProfile),
  ]);

  Widget _gradientBtn(String label, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: AppColors.nearBlack),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );

  Widget _outlineBtn(String label, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGray, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: AppColors.nearBlack),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: AppColors.nearBlack),
    ),
  );

  // ─── Followers sheet ──────────────────────────────────────────────────────

  Future<void> _showFollowers() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowersSheet(
        storeId: _store.id,
        count:   _store.followersCount,
        isOwner: _isOwner,
      ),
    );
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  // Pack-based avatar border color
  Color get _packBorderColor => switch (_sellerPackType) {
    'business' => const Color(0xFFFFB800),
    'pro'      => const Color(0xFF8B5CF6),
    _          => Colors.white,
  };

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: GoogleFonts.montserrat(
            fontSize: 10, color: fg, fontWeight: FontWeight.w700)),
  );

  Widget _reviewsSummary() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFE082)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
        const SizedBox(width: 6),
        Text('Avis clients',
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: AppColors.nearBlack)),
        const Spacer(),
        Text(
          _storeAverageRating > 0
              ? '${_storeAverageRating.toStringAsFixed(1)}/5'
              : '—',
          style: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: AppColors.nearBlack),
        ),
      ]),
      const SizedBox(height: 6),
      Text('$_storeReviewsCount avis',
          style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.gray)),
      if (_storeReviews.isNotEmpty) ...[
        const SizedBox(height: 10),
        ..._storeReviews.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.bgGray,
              backgroundImage:
                  (r['reviewer_avatar_url'] as String?)?.startsWith('http') == true
                      ? NetworkImage(r['reviewer_avatar_url'] as String)
                      : null,
              child: (r['reviewer_avatar_url'] as String?)?.startsWith('http') != true
                  ? Text(
                      (r['reviewer_name'] as String?)
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'C',
                      style: GoogleFonts.montserrat(fontSize: 11),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(r['reviewer_name'] as String? ?? 'Client',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack)),
                const SizedBox(height: 2),
                Row(children: List.generate(
                    5,
                    (i) => Icon(
                        i < ((r['rating'] as num?)?.round() ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 12,
                        color: const Color(0xFFFFC107)))),
                if ((r['comment'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(r['comment'] as String,
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: AppColors.gray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
          ]),
        )),
      ],
    ]),
  );

  Widget _statCol(String value, String label,
      {bool tapHint = false, Widget? icon}) =>
      Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(children: [
      if (icon != null) ...[icon, const SizedBox(height: 2)],
      Text(value,
          style: GoogleFonts.montserrat(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: AppColors.nearBlack)),
      const SizedBox(height: 2),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 11, color: AppColors.gray)),
        if (tapHint) ...[
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded,
              size: 13, color: AppColors.grayLight),
        ],
      ]),
    ]),
  );

  Widget _vDivider() => Container(width: 1, color: AppColors.lightGray);

  Widget _avatarInitials() {
    final name = _sellerStoreName ?? _store.storeName;
    return Container(
      color: AppColors.nearBlack,
      child: Center(
        child: Text(
          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
          style: GoogleFonts.montserrat(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _emptyTab(IconData icon, String label) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 48, color: AppColors.lightGray),
      const SizedBox(height: 12),
      Text(label,
          style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.gray)),
    ]),
  );

  // ─── Formatters ───────────────────────────────────────────────────────────

  // Affiche une image réseau ou asset selon l'URL
  Widget _img(String url, {BoxFit fit = BoxFit.cover, Widget? placeholder}) {
    final ph = placeholder ??
        Container(color: AppColors.bgGray,
            child: const Icon(Icons.image_outlined,
                color: AppColors.lightGray, size: 32));
    if (url.startsWith('http')) {
      return Image.network(url, fit: fit,
          errorBuilder: (_, __, ___) => ph);
    }
    return Image.asset(url, fit: fit,
        errorBuilder: (_, __, ___) => ph);
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}K';
    return '$n';
  }

  String _formatPrice(double p) {
    if (p >= 1000) {
      final s = p.toStringAsFixed(0);
      return s.length > 3 ? '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}' : s;
    }
    return p.toStringAsFixed(0);
  }

  // ─── Sheets ───────────────────────────────────────────────────────────────

  void _shareProfile() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Lien copié : lincoo.dz/${_store.username}',
          style: GoogleFonts.montserrat(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      backgroundColor: AppColors.dark,
    ));
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          _sheetTile(Icons.link_outlined, 'Copier le lien du profil', _shareProfile),
          _sheetTile(Icons.flag_outlined, 'Signaler la boutique', () {
            Navigator.pop(context);
          }, color: Colors.red),
        ]),
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text('Ajouter du contenu',
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack)),
          ),
          _sheetTile(Icons.auto_awesome_outlined, 'Story (24h)',
              () { Navigator.pop(context); _goCreate('story'); },
              subtitle: 'Image, vidéo, texte ou produit tagué'),
          _sheetTile(Icons.grid_on_outlined, 'Publication classique',
              () { Navigator.pop(context); _goCreate('classic'); },
              subtitle: 'Images, vidéo, hashtags, localisation'),
          _sheetTile(Icons.sell_outlined, 'Publication commerciale',
              () { Navigator.pop(context); _goCreate('commercial'); },
              subtitle: 'Promouvoir un produit avec prix et bouton Acheter',
              gradient: true),
          _sheetTile(Icons.add_box_outlined, 'Produit',
              () { Navigator.pop(context); _goCreate('product'); },
              subtitle: 'Ajouter un nouveau produit à votre catalogue'),
          _sheetTile(Icons.video_collection_outlined, 'Reel',
              () { Navigator.pop(context); _goCreate('reel'); },
              subtitle: 'Vidéo verticale, avec ou sans produit associé'),
        ]),
      ),
    );
  }

  void _goCreate(String type) {
    Navigator.pushNamed(context, '/create');
  }

  void _showPostDetail(StorePost p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => _PostDetailSheet(
          post: p,
          controller: ctrl,
          store: _store,
          productArgsBuilder: _productArgsForPost,
        ),
      ),
    );
  }

  void _showReelDetail(StorePost r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReelDetailSheet(
        reel: r,
        store: _store,
        productArgsBuilder: _productArgsForPost,
      ),
    );
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(
        store: _store,
        onSaved: (updated) {
          setState(() => _store = updated);
          _saveStoreToSupabase(updated);
        },
      ),
    );
  }

  Future<void> _saveStoreToSupabase(StoreData store) async {
    try {
      await Supabase.instance.client
          .from('stores')
          .update(store.toMap())
          .eq('id', store.id);
    } catch (_) {}
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap, {
    String? subtitle, Color? color, bool gradient = false,
  }) =>
    ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: gradient
              ? const LinearGradient(colors: [AppColors.accent, AppColors.blue])
              : null,
          color: gradient ? null : (color ?? AppColors.nearBlack).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color: gradient ? AppColors.nearBlack : (color ?? AppColors.nearBlack)),
      ),
      title: Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: color ?? AppColors.nearBlack)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.gray))
          : null,
      onTap: onTap,
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar delegate
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
    Container(
      color: Colors.white,
      child: tabBar,
    );

  @override double get maxExtent => 48;
  @override double get minExtent => 48;
  @override bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}

// ─────────────────────────────────────────────────────────────────────────────
// Post detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PostDetailSheet extends StatelessWidget {
  final StorePost post;
  final StoreData store;
  final ScrollController controller;
  final Map<String, dynamic> Function(StorePost post) productArgsBuilder;

  const _PostDetailSheet({
    required this.post,
    required this.store,
    required this.controller,
    required this.productArgsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      children: [
        const SizedBox(height: 8),
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: AppColors.lightGray, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 12),
        // Media
        if (post.hasMedia)
          AspectRatio(
            aspectRatio: 1,
            child: post.mediaUrls.first.startsWith('http')
                ? Image.network(post.mediaUrls.first, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.bgGray))
                : Image.asset(post.mediaUrls.first, fit: BoxFit.cover),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Author
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.nearBlack,
                child: Text(
                  store.storeName.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.storeName,
                    style: GoogleFonts.montserrat(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
                Text(_timeAgo(post.createdAt),
                    style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.gray)),
              ]),
            ]),
            if (post.caption != null) ...[
              const SizedBox(height: 12),
              Text(post.caption!,
                  style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.nearBlack, height: 1.5)),
            ],
            if (post.isCommercial && post.productName != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post.productName!,
                        style: GoogleFonts.montserrat(
                            fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.nearBlack)),
                    Text('${post.promoPrice ?? post.price} DA',
                        style: GoogleFonts.montserrat(
                            fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.nearBlack)),
                  ])),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/product', arguments: productArgsBuilder(post));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: AppColors.nearBlack, borderRadius: BorderRadius.circular(10)),
                      child: Text('Acheter',
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.favorite_border, size: 18, color: AppColors.gray),
              const SizedBox(width: 4),
              Text('${post.likesCount} j\'aime',
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.gray)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.gray),
              const SizedBox(width: 4),
              Text('${post.commentsCount} commentaires',
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.gray)),
            ]),
          ]),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reel detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ReelDetailSheet extends StatelessWidget {
  final StorePost reel;
  final StoreData store;
  final Map<String, dynamic> Function(StorePost post) productArgsBuilder;
  const _ReelDetailSheet({required this.reel, required this.store, required this.productArgsBuilder});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            // Video placeholder
            reel.hasMedia
                ? (reel.mediaUrls.first.startsWith('http')
                    ? Image.network(reel.mediaUrls.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.dark))
                    : Image.asset(reel.mediaUrls.first, fit: BoxFit.cover))
                : Container(color: AppColors.dark),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 12, right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            // Play button
            const Center(child: Icon(Icons.play_circle_outline,
                color: Colors.white, size: 64)),
            // Bottom info
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          store.storeName.substring(0, 2).toUpperCase(),
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(store.storeName,
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    if (reel.caption != null) ...[
                      const SizedBox(height: 8),
                      Text(reel.caption!,
                          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, height: 1.4),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (reel.productName != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/product', arguments: productArgsBuilder(reel));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.shopping_bag_outlined,
                                color: AppColors.nearBlack, size: 16),
                            const SizedBox(width: 6),
                            Text('Voir le produit',
                                style: GoogleFonts.montserrat(
                                    color: AppColors.nearBlack, fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ]),
                        ),
                      ),
                    ],
                  ])),
                  Column(children: [
                    _actionIcon(Icons.favorite_border, _fmt(reel.likesCount), Colors.white),
                    const SizedBox(height: 14),
                    _actionIcon(Icons.chat_bubble_outline, _fmt(reel.commentsCount), Colors.white),
                    const SizedBox(height: 14),
                    _actionIcon(Icons.share_outlined, 'Partager', Colors.white),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionIcon(IconData icon, String label, Color color) => Column(children: [
    Icon(icon, color: color, size: 26),
    const SizedBox(height: 3),
    Text(label, style: GoogleFonts.montserrat(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final StoreData store;
  final ValueChanged<StoreData> onSaved;
  const _EditProfileSheet({required this.store, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _instaCtrl;
  late final TextEditingController _waCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.store.storeName);
    _usernameCtrl = TextEditingController(text: widget.store.username);
    _bioCtrl      = TextEditingController(text: widget.store.bio);
    _addressCtrl  = TextEditingController(text: widget.store.address);
    _websiteCtrl  = TextEditingController(text: widget.store.website);
    _instaCtrl    = TextEditingController(text: widget.store.socialLinks['instagram'] ?? '');
    _waCtrl       = TextEditingController(text: widget.store.contactLinks['whatsapp'] ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _usernameCtrl, _bioCtrl, _addressCtrl, _websiteCtrl, _instaCtrl, _waCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updated = widget.store.copyWith(
      storeName:   _nameCtrl.text.trim(),
      username:    _usernameCtrl.text.trim(),
      bio:         _bioCtrl.text.trim(),
      address:     _addressCtrl.text.trim(),
      socialLinks: {...widget.store.socialLinks, 'instagram': _instaCtrl.text.trim()},
      contactLinks: {...widget.store.contactLinks, 'whatsapp': _waCtrl.text.trim()},
    );
    widget.onSaved(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              Text('Modifier le profil',
                  style: GoogleFonts.montserrat(
                      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.nearBlack)),
              const Spacer(),
              GestureDetector(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Enregistrer',
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _editField(_nameCtrl,     'Nom du magasin', Icons.storefront_outlined),
                _editField(_usernameCtrl, 'Nom d\'utilisateur (@handle)', Icons.alternate_email, prefix: '@'),
                _editField(_bioCtrl,      'Bio', Icons.edit_outlined, lines: 3),
                _editField(_addressCtrl,  'Adresse', Icons.location_on_outlined),
                _editField(_websiteCtrl,  'Site web', Icons.link),
                const Divider(height: 24),
                Text('Réseaux sociaux', style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 10),
                _editField(_instaCtrl, 'Instagram', Icons.photo_camera_outlined),
                const Divider(height: 24),
                Text('Contact', style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 10),
                _editField(_waCtrl, 'WhatsApp', FontAwesomeIcons.whatsapp,
                    kb: TextInputType.phone),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, IconData icon, {
    String? prefix, int lines = 1, TextInputType kb = TextInputType.text,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        keyboardType: kb,
        style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.nearBlack),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
          prefixText: prefix,
          prefixStyle: GoogleFonts.montserrat(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w700),
          prefixIcon: Icon(icon, size: 18, color: AppColors.gray),
          filled: true,
          fillColor: AppColors.bgGray,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        ),
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Followers bottom sheet — with remove / block + real-time
// ─────────────────────────────────────────────────────────────────────────────

class _FollowersSheet extends StatefulWidget {
  final String storeId;
  final int    count;
  final bool   isOwner;
  const _FollowersSheet({
    required this.storeId,
    required this.count,
    required this.isOwner,
  });

  @override
  State<_FollowersSheet> createState() => _FollowersSheetState();
}

class _FollowersSheetState extends State<_FollowersSheet> {
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _filtered  = [];
  bool               _loading  = true;
  int                _count    = 0;
  String             _q        = '';
  final              _ctrl     = TextEditingController();
  RealtimeChannel?   _channel;

  @override
  void initState() {
    super.initState();
    _count = widget.count;
    _load();
    // Real-time subscription on store_follows for this store
    _channel = Supabase.instance.client
        .channel('followers_${widget.storeId}')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'store_follows',
            callback: (payload) {
              // Only react to events for this store
              final newRow = payload.newRecord;
              final oldRow = payload.oldRecord;
              final sid = (newRow['store_id'] ?? oldRow['store_id']);
              if (sid == widget.storeId) _load();
            })
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final client = Supabase.instance.client;

      final follows = await client
          .from('store_follows')
          .select('follower_id')
          .eq('store_id', widget.storeId)
          .order('created_at', ascending: false);

      final ids = (follows as List)
          .map<String?>((f) => f['follower_id'] is String ? f['follower_id'] as String : null)
          .whereType<String>()
          .toList();

      if (ids.isEmpty) {
        if (mounted) setState(() { _followers = []; _filtered = []; _count = 0; _loading = false; });
        return;
      }

      final profiles = await client
          .from('profiles')
          .select('id, full_name, nom_complet, avatar_url, store_name, email')
          .inFilter('id', ids);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in (profiles as List)) {
        if (p['id'] is String) {
          profileMap[p['id'] as String] = Map<String, dynamic>.from(p as Map);
        }
      }
      final ordered = ids
          .map((id) => profileMap[id])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() {
          _followers = ordered;
          _count     = ordered.length;
          _loading   = false;
        });
        _applyFilter(_q);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _removeFollower(String followerId) async {
    // Optimistic remove
    setState(() {
      _followers.removeWhere((p) => p['id'] == followerId);
      _count = (_count - 1).clamp(0, 999999);
      _applyFilter(_q);
    });
    try {
      await Supabase.instance.client
          .from('store_follows')
          .delete()
          .eq('store_id', widget.storeId)
          .eq('follower_id', followerId);
    } catch (_) {
      _load(); // revert on error
    }
  }

  Future<void> _blockUser(String userId) async {
    // Optimistic remove
    setState(() {
      _followers.removeWhere((p) => p['id'] == userId);
      _count = (_count - 1).clamp(0, 999999);
      _applyFilter(_q);
    });
    try {
      final client = Supabase.instance.client;
      await client.from('store_blocks').upsert({
        'store_id':        widget.storeId,
        'blocked_user_id': userId,
      }, onConflict: 'store_id,blocked_user_id');
      // Also remove from follows
      await client.from('store_follows')
          .delete()
          .eq('store_id', widget.storeId)
          .eq('follower_id', userId);
    } catch (_) {
      _load();
    }
  }

  void _showOptions(Map<String, dynamic> p) {
    final userId = p['id'] is String ? p['id'] as String : '';
    final name   = _displayName(p);
    if (userId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(name,
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack)),
          ),
          const Divider(height: 1, color: AppColors.lightGray),

          // Retirer
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_remove_outlined,
                  color: Color(0xFFE65100), size: 20),
            ),
            title: Text('Retirer cet abonné',
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack)),
            subtitle: Text('Il ne suivra plus votre boutique',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: AppColors.gray)),
            onTap: () {
              Navigator.pop(context);
              _removeFollower(userId);
            },
          ),

          // Bloquer
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.block_outlined,
                  color: AppColors.error, size: 20),
            ),
            title: Text('Bloquer cet utilisateur',
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.error)),
            subtitle: Text('Il ne pourra plus s\'abonner ni voir vos contenus',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: AppColors.gray)),
            onTap: () {
              Navigator.pop(context);
              _confirmBlock(userId, name);
            },
          ),

          // Annuler
          ListTile(
            title: Text('Annuler',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.gray)),
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }

  void _confirmBlock(String userId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bloquer $name ?',
            style: GoogleFonts.montserrat(
                fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text(
            'Il sera retiré de vos abonnés et ne pourra plus s\'abonner à votre boutique.',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(userId);
            },
            child: Text('Bloquer',
                style: GoogleFonts.montserrat(
                    color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void _applyFilter(String q) {
    _q = q;
    if (q.trim().isEmpty) {
      _filtered = List.from(_followers);
    } else {
      final lq = q.toLowerCase();
      _filtered = _followers.where((p) {
        return _displayName(p).toLowerCase().contains(lq) ||
            ((p['email'] as String? ?? '').toLowerCase().contains(lq));
      }).toList();
    }
    if (mounted) setState(() {});
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _displayName(Map<String, dynamic> p) {
    String? pick(String key) {
      final v = p[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }
    return pick('full_name')
        ?? pick('nom_complet')
        ?? pick('store_name')
        ?? (pick('email')?.split('@').first)
        ?? 'Utilisateur';
  }

  static String? _avatarUrl(Map<String, dynamic> p) {
    final v = p['avatar_url'];
    return v is String && v.startsWith('http') ? v : null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2)),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(children: [
            Text(
              '$_count Abonné${_count != 1 ? 's' : ''}',
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, size: 20, color: AppColors.gray),
            ),
          ]),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _ctrl,
              onChanged: _applyFilter,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: AppColors.nearBlack),
              decoration: InputDecoration(
                hintText: 'Rechercher un abonné…',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 13, color: AppColors.gray),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.gray, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _q.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _ctrl.clear(); _applyFilter(''); },
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.gray),
                      )
                    : null,
              ),
            ),
          ),
        ),

        const Divider(height: 1, color: AppColors.lightGray),

        // List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.people_outline,
                            size: 52, color: AppColors.lightGray),
                        const SizedBox(height: 12),
                        Text(
                          _q.isEmpty
                              ? 'Aucun abonné pour l\'instant'
                              : 'Aucun résultat',
                          style: GoogleFonts.montserrat(
                              fontSize: 14, color: AppColors.gray),
                        ),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _tile(_filtered[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _tile(Map<String, dynamic> p) {
    final name     = _displayName(p);
    final avatar   = _avatarUrl(p);
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF292526),
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          child: avatar == null
              ? Text(initials,
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w800))
              : null,
        ),
        const SizedBox(width: 12),

        // Name + store
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (p['store_name'] is String &&
                (p['store_name'] as String).isNotEmpty)
              Text(p['store_name'] as String,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.gray),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),

        // 3-dot menu (owner only)
        if (widget.isOwner)
          GestureDetector(
            onTap: () => _showOptions(p),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert,
                  size: 20, color: AppColors.gray),
            ),
          ),
      ]),
    );
  }
}
