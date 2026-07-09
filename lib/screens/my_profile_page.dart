import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/app_user.dart';
import '../services/app_cache.dart';
import '../services/pack_service.dart';
import '../services/user_session.dart';
import '../services/rewards_service.dart';
import '../services/wishlist_service.dart';
import '../widgets/app_bottom_nav.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fade;
  late final TabController       _sellerTabs;
  late final TabController       _creatorTabs;

  String  _name      = '';
  String  _email     = '';
  String  _storeName = '';
  String  _wilaya    = '';
  String  _category  = '';
  String? _storeId;
  String? _avatarUrl;
  int    _followersCount = 0;
  int    _productsCount  = 0;
  double _rating         = 0.0;

  ProRole    _role      = ProRole.none;
  ProStatus  _status    = ProStatus.none;
  SellerPack? _activePack;
  RealtimeChannel? _packChannel;
  bool _loading = true;

  // ── Products ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _products        = [];
  bool                       _productsLoading = false;

  // ── Store posts ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _storePosts      = [];
  bool                       _postsLoading    = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fadeCtrl   = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade       = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _sellerTabs  = TabController(length: 3, vsync: this);
    _creatorTabs = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _packChannel?.unsubscribe();
    _fadeCtrl.dispose();
    _sellerTabs.dispose();
    _creatorTabs.dispose();
    super.dispose();
  }

  Future<void> _init({bool silent = false}) async {
    final user = UserSession.instance.current;
    _role   = user.proRole;
    _status = user.proStatus;
    _name   = user.displayName;
    _email  = user.email;

    if (!user.isGuest) {
      try {
        final client = Supabase.instance.client;
        final profile = await client
            .from('profiles')
            .select(
                'full_name, store_name, wilaya, category, avatar_url, contact_links')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          _name      = profile['full_name']  as String? ?? _name;
          _storeName = profile['store_name'] as String? ?? '';
          _wilaya    = profile['wilaya']     as String? ?? '';
          _category  = profile['category']  as String? ?? '';
          _avatarUrl = profile['avatar_url'] as String?;
        }

        if (_role == ProRole.seller || _role == ProRole.company) {
          final store = await UserSession.instance.ensureSellerStore(
            ownerId: user.id,
            storeName: _storeName.isNotEmpty ? _storeName : _name,
            wilaya: _wilaya.isNotEmpty ? _wilaya : null,
            category: _category.isNotEmpty ? _category : null,
            avatarUrl: _avatarUrl,
          );

          _storeId        = store?['id'] as String?;
          _followersCount = (store?['followers_count'] as int?) ?? 0;
          _productsCount  = (store?['products_count'] as int?) ?? 0;
          _rating         = (store?['rating'] as num?)?.toDouble() ?? 0.0;

          // Load active pack
          _activePack = await PackService.instance
              .load(user.id, refresh: silent);

          // Subscribe to real-time pack status changes
          _subscribeToPackUpdates(user.id);

          _loadProducts();
          _loadPosts();
        }

        if (_role == ProRole.creator) {
          final store = await Supabase.instance.client
              .from('stores')
              .select('id, followers_count')
              .eq('owner_id', user.id)
              .maybeSingle();
          if (store != null) {
            _storeId        = store['id'] as String?;
            _followersCount = (store['followers_count'] as int?) ?? 0;
          }
          _loadPosts();
        }

        // Load wishlist for all authenticated users
        WishlistService.instance.load();
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _loading = false);
      if (!silent) _fadeCtrl.forward();
    }
  }

  Future<void> _refresh() => _init(silent: true);

  void _subscribeToPackUpdates(String userId) {
    // Cancel any previous subscription first
    _packChannel?.unsubscribe();

    _packChannel = Supabase.instance.client
        .channel('pack_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'seller_packs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: userId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (newStatus == 'active' && mounted) {
              // Reload pack from DB and update UI
              PackService.instance
                  .load(userId, refresh: true)
                  .then((pack) {
                if (mounted) {
                  setState(() => _activePack = pack);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      '🎉 Pack ${pack?.label ?? ''} activé ! Toutes vos fonctionnalités sont débloquées.',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: const Color(0xFF26C860),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(12),
                    duration: const Duration(seconds: 5),
                  ));
                }
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadProducts() async {
    if (_storeId == null) return;
    if (mounted) setState(() => _productsLoading = true);
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select()
          .eq('store_id', _storeId!)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _products = List<Map<String, dynamic>>.from(rows));
      }
    } catch (_) {}
    if (mounted) setState(() => _productsLoading = false);
  }

  Future<void> _loadPosts() async {
    if (_storeId == null) return;
    if (mounted) setState(() => _postsLoading = true);
    try {
      final rows = await Supabase.instance.client
          .from('store_posts')
          .select('id, post_type, caption, cover_url, media_urls, created_at')
          .eq('store_id', _storeId!)
          .inFilter('post_type', ['classic', 'commercial', 'reel'])
          .order('created_at', ascending: false)
          .limit(60);
      if (mounted) {
        setState(() => _storePosts = List<Map<String, dynamic>>.from(rows));
      }
    } catch (_) {}
    if (mounted) setState(() => _postsLoading = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSeller  = _role == ProRole.seller || _role == ProRole.company;
    final isCreator = _role == ProRole.creator;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : FadeTransition(
                opacity: _fade,
                child: isSeller
                    ? _buildSellerBody(context)
                    : isCreator
                        ? _buildCreatorBody(context)
                        : Column(children: [
                            _buildBuyerHeader(context),
                            Expanded(child: _buildBuyerBody(context)),
                          ]),
              ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: NavTab.profile),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELLER VIEW — new layout
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSellerBody(BuildContext context) => Column(children: [
    _sellerTopBar(context),
    Expanded(
      child: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _sellerProfileCard(context)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _sellerTabs,
                  labelColor: AppColors.nearBlack,
                  unselectedLabelColor: AppColors.grayLight,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: AppColors.lightGray,
                  labelStyle: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'À Propos'),
                    Tab(text: 'Produits'),
                    Tab(text: 'Posts'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _sellerTabs,
          children: [
            _aboutTab(context),
            _productsTab(),
            _postsTab(),
          ],
        ),
      ),
    ),
  ]);

  // ── Top bar (seller) ─────────────────────────────────────────────────────

  Widget _sellerTopBar(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
    child: Row(children: [
      Text('Mon Profil',
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 18,
              fontWeight: FontWeight.w900)),
      const Spacer(),
      GestureDetector(
        onTap: () async {
          final result = await Navigator.pushNamed(context, '/create-post');
          if (result == true && mounted) _loadPosts();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.blue]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded, size: 15, color: AppColors.nearBlack),
            const SizedBox(width: 4),
            Text('Créer',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/settings'),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.settings_outlined,
              size: 18, color: AppColors.nearBlack),
        ),
      ),
    ]),
  );

  // ── Profile card (seller) ─────────────────────────────────────────────────

  Widget _sellerProfileCard(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    child: Column(children: [

      // ── Avatar row ──────────────────────────────────────────────────────
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _circleAvatarWithRing(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Name + verified
            Row(children: [
              Flexible(
                child: Text(_name,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack, fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ),
              if (_status == ProStatus.verified) ...[
                const SizedBox(width: 5),
                const Icon(Icons.verified_rounded,
                    color: AppColors.blue, size: 18),
              ],
            ]),
            // Store name
            if (_storeName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(_storeName,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
            // Wilaya · Category
            if (_wilaya.isNotEmpty || _category.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [if (_wilaya.isNotEmpty) _wilaya,
                 if (_category.isNotEmpty) _category].join(' · '),
                style: GoogleFonts.montserrat(
                    color: AppColors.grayLight, fontSize: 11),
              ),
            ],
            const SizedBox(height: 8),
            // Badges
            _roleBadge(),
          ]),
        ),
        // Options menu
        GestureDetector(
          onTap: () => _showOptionsMenu(context),
          child: const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.more_vert_rounded,
                color: AppColors.gray, size: 22),
          ),
        ),
      ]),

      // Pending notice
      if (_status == ProStatus.pending) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: Color(0xFFFFB300)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Votre compte est en cours de vérification.',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: const Color(0xFF8A6500)),
              ),
            ),
          ]),
        ),
      ],

      const SizedBox(height: 20),

      // ── Stats row ────────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Expanded(child: _statCol(_fmt(_followersCount), 'Abonnés')),
          Container(width: 1, height: 30, color: AppColors.lightGray),
          Expanded(child: _statCol(_fmt(_productsCount), 'Produits')),
          Container(width: 1, height: 30, color: AppColors.lightGray),
          Expanded(child: _statCol(_rating > 0 ? _rating.toStringAsFixed(1) : '—', 'Note ⭐')),
        ]),
      ),

      const SizedBox(height: 14),

      // ── Pack status banner ────────────────────────────────────────────────
      _packBanner(context),

      const SizedBox(height: 14),

      // ── Lincoo+ ──────────────────────────────────────────────────────────
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/seller-packs'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFFFB800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('L+',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Lincoo+',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w900, letterSpacing: .5)),
                Text('Tableau de bord pro · Stats · Coach IA',
                    style: GoogleFonts.montserrat(
                        color: Colors.white70, fontSize: 10)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 14),
          ]),
        ),
      ),

      // ── Campagne publicitaire (company only) ────────────────────────────────
      if (_role == ProRole.company) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/campaigns'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.nearBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Lancer une campagne',
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack, fontSize: 13,
                          fontWeight: FontWeight.w800)),
                  Text('Bannière publicitaire · Accueil',
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack.withValues(alpha: 0.6), fontSize: 10)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.nearBlack.withValues(alpha: 0.6)),
            ]),
          ),
        ),
      ],
    ]),
  );

  // ── Tab content ───────────────────────────────────────────────────────────

  Widget _aboutTab(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
    children: [
      // Store info
      _aboutSection(
        icon: Icons.storefront_outlined,
        title: 'Boutique',
        color: const Color(0xFF6C63FF),
        children: [
          if (_storeName.isNotEmpty)
            _aboutInfoRow(Icons.store_outlined, 'Nom', _storeName),
          if (_wilaya.isNotEmpty)
            _aboutInfoRow(Icons.location_on_outlined, 'Wilaya', _wilaya),
          if (_category.isNotEmpty)
            _aboutInfoRow(Icons.category_outlined, 'Catégorie', _category),
          if (_storeName.isEmpty && _wilaya.isEmpty && _category.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('Informations non renseignées.',
                  style: GoogleFonts.montserrat(
                      color: AppColors.grayLight, fontSize: 12)),
            ),
        ],
      ),
      const SizedBox(height: 8),

      // Account
      _aboutSection(
        icon: Icons.manage_accounts_outlined,
        title: 'Mon compte',
        color: AppColors.blue,
        children: [
          _aboutInfoRow(Icons.email_outlined, 'Email', _email),
          InkWell(
            onTap: () => _logout(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(children: [
                const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 14),
                Text('Se déconnecter',
                    style: GoogleFonts.montserrat(
                        color: AppColors.error, fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ],
  );

  Widget _productsTab() {
    if (_productsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    return Stack(children: [
      _products.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.blue, size: 28),
                ),
                const SizedBox(height: 14),
                Text('Aucun produit',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Ajoutez votre premier produit',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 12)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _showAddProductSheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.blue]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded,
                          color: AppColors.nearBlack, size: 18),
                      const SizedBox(width: 6),
                      Text('Ajouter un produit',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ]),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              color: AppColors.accent,
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _products.length,
                itemBuilder: (_, i) => _productCard(_products[i]),
              ),
            ),

      // FAB — add product
      Positioned(
        bottom: 16,
        right: 16,
        child: GestureDetector(
          onTap: () => _showAddProductSheet(),
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.blue]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.add_rounded,
                color: AppColors.nearBlack, size: 26),
          ),
        ),
      ),
    ]);
  }

  // ── Product card ────────────────────────────────────────────────────────────

  Widget _productCard(Map<String, dynamic> p) {
    final images  = (p['images'] as List?)?.cast<String>() ?? [];
    final price   = (p['price'] as num?)?.toDouble() ?? 0;
    final promo   = (p['promo_price'] as num?)?.toDouble();
    final avail   = p['available'] as bool? ?? true;
    final name    = p['name'] as String? ?? '';
    final hasPromo = promo != null && promo < price;
    final discount = hasPromo
        ? ((1 - promo / price) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
        Stack(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 1,
              child: images.isNotEmpty
                  ? Image.network(images.first, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: AppColors.bgGray,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.lightGray, size: 32)))
                  : Container(
                      color: AppColors.bgGray,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.lightGray, size: 32)),
            ),
          ),
          // Discount badge
          if (hasPromo)
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('−$discount%',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          // Unavailable overlay
          if (!avail)
            Positioned.fill(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Indisponible',
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ),
          // Options
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () => _showProductOptions(p),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.more_vert,
                    size: 16, color: AppColors.nearBlack),
              ),
            ),
          ),
        ]),

        // Info
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack, height: 1.3)),
            const SizedBox(height: 4),
            if (hasPromo) ...[
              Text('${promo.toInt()} DA',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: AppColors.error)),
              Text('${price.toInt()} DA',
                  style: GoogleFonts.montserrat(
                      fontSize: 10, color: AppColors.gray,
                      decoration: TextDecoration.lineThrough)),
            ] else
              Text('${price.toInt()} DA',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: AppColors.nearBlack)),
          ]),
        ),
      ]),
    );
  }

  void _showProductOptions(Map<String, dynamic> p) {
    final avail = p['available'] as bool? ?? true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined,
                color: AppColors.nearBlack),
            title: Text('Modifier le produit',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showAddProductSheet(existing: p);
            },
          ),
          ListTile(
            leading: Icon(
              avail
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.nearBlack,
            ),
            title: Text(
              avail ? 'Marquer indisponible' : 'Marquer disponible',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _toggleAvailability(p['id'] as String, !avail);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: AppColors.error),
            title: Text('Supprimer',
                style: GoogleFonts.montserrat(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await _deleteProduct(p['id'] as String);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _toggleAvailability(String id, bool available) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'available': available})
          .eq('id', id);
      await _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le produit',
            style: GoogleFonts.montserrat(
                fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text(
            'Cette action est irréversible. Le produit sera définitivement supprimé.',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', id);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Produit supprimé',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Add / Edit product sheet ────────────────────────────────────────────────

  void _showAddProductSheet({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductSheet(
        storeId:  _storeId ?? '',
        existing: existing,
        onSaved:  _loadProducts,
        picker:   _picker,
      ),
    );
  }

  Widget _postsTab() {
    if (_postsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_storePosts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 12),
          Text('Aucune publication',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Créez votre premier post pour attirer des clients.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 12)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final result =
                  await Navigator.pushNamed(context, '/create');
              if (result == true && mounted) _loadPosts();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Créer un post',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AppColors.accent,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _storePosts.length,
        itemBuilder: (_, i) {
          final post = _storePosts[i];
          final cover  = post['cover_url'] as String?;
          final media  = post['media_urls'];
          final thumb  = cover?.isNotEmpty == true
              ? cover
              : (media is List && media.isNotEmpty ? media.first as String? : null);
          final isReel = post['post_type'] == 'reel';

          return Stack(fit: StackFit.expand, children: [
            thumb != null
                ? Image.network(thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.bgGray,
                            child: const Icon(Icons.broken_image_outlined,
                                color: AppColors.lightGray, size: 24)))
                : Container(color: AppColors.bgGray,
                    child: const Icon(Icons.article_outlined,
                        color: AppColors.lightGray, size: 24)),
            if (isReel)
              const Positioned(
                top: 4, right: 4,
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 18),
              ),
          ]);
        },
      ),
    );
  }

  // ── About tab helpers ─────────────────────────────────────────────────────

  Widget _aboutSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) =>
      Container(
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20,
              color: AppColors.lightGray),
          ...children,
          const SizedBox(height: 4),
        ]),
      );

  Widget _aboutInfoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.gray),
      const SizedBox(width: 12),
      Text('$label : ',
          style: GoogleFonts.montserrat(
              color: AppColors.gray, fontSize: 13)),
      Expanded(
        child: Text(value,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack, fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  // ── Seller helpers ────────────────────────────────────────────────────────

  Widget _circleAvatarWithRing() {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Container(
      width: 84, height: 84,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.blue],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Colors.white),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: _avatarUrl != null
              ? Image.network(_avatarUrl!,
                  width: 74, height: 74, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarInitFill(initial))
              : _avatarInitFill(initial),
        ),
      ),
    );
  }

  Widget _avatarInitFill(String initial) => Container(
    width: 74, height: 74,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(initial,
          style: GoogleFonts.montserrat(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
    ),
  );

  Widget _statCol(String value, String label) => Column(children: [
    Text(value,
        style: GoogleFonts.montserrat(
            color: AppColors.nearBlack, fontSize: 17,
            fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label,
        style: GoogleFonts.montserrat(
            color: AppColors.grayLight, fontSize: 10,
            fontWeight: FontWeight.w500)),
  ]);

  // ── Pack banner ───────────────────────────────────────────────────────────

  Widget _packBanner(BuildContext context) {
    final pack = _activePack;

    if (pack == null) {
      // No pack — prompt to subscribe
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/seller-packs'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF07080F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('L+',
                    style: GoogleFonts.montserrat(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 13, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Activez votre boutique',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Choisissez un pack pour commencer à vendre',
                    style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 10)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Choisir',
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );
    }

    // Has a pack — show its status
    final isPending = pack.isPendingPayment || pack.isPaid;
    final packColor = switch (pack.type) {
      PackType.business => const Color(0xFFFFB800),
      PackType.pro      => const Color(0xFF8B5CF6),
      PackType.essentiel=> const Color(0xFFFFB800),
      PackType.lincooPlus=> const Color(0xFF8B5CF6),
      PackType.starter  => const Color(0xFF7C3AED),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: packColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: packColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Text(pack.emoji,
            style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Pack ${pack.label}',
                style: GoogleFonts.montserrat(
                    color: packColor, fontSize: 13,
                    fontWeight: FontWeight.w900)),
            Text(
              isPending
                  ? 'En attente de vérification (24–48h)'
                  : pack.isActive
                      ? 'Actif · Toutes les fonctionnalités débloquées'
                      : 'Expiré',
              style: GoogleFonts.montserrat(
                  color: Colors.black54, fontSize: 10),
            ),
          ]),
        ),
        if (isPending)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('En attente',
                style: GoogleFonts.montserrat(
                    color: const Color(0xFFFFB300),
                    fontSize: 10, fontWeight: FontWeight.w700)),
          )
        else if (pack.isActive)
          Icon(Icons.check_circle_rounded,
              color: packColor, size: 22),
      ]),
    );
  }

  // ── Open boutique (requires active pack) ─────────────────────────────────

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.nearBlack),
            title: Text('Modifier le profil',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/edit-profile')
                  .then((_) => _refresh());
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.nearBlack),
            title: Text('Paramètres',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Déconnecter',
                style: GoogleFonts.montserrat(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _logout(context);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }


  // ignore: unused_element
  void _showLincooPacksSheetOld(BuildContext context) {
    int? selected;
    final packs = [
      {'name': 'Starter',  'price': 'Gratuit',    'color': 0xFF6B7080, 'sub': '10 produits · Tableau de bord basique'},
      {'name': 'Pro',      'price': '1 500 DA/mois','color': 0xFF7C3AED, 'sub': '50 produits · Coach IA · Statistiques'},
      {'name': 'Business', 'price': '3 500 DA/mois','color': 0xFF8B5CF6, 'sub': '200 produits · Automatisations · CRM'},
      {'name': 'Elite',    'price': '7 000 DA/mois','color': 0xFFFFB800, 'sub': 'Produits illimités · API · Account manager'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C0E1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)]).createShader(r),
            child: Text('Lincoo+', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          const SizedBox(height: 4),
          Text('Choisissez votre plan pour accéder au tableau de bord pro',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ...List.generate(packs.length, (i) {
            final p = packs[i];
            final sel = selected == i;
            return GestureDetector(
              onTap: () => ss(() => selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? Color(p['color'] as int).withValues(alpha: 0.12) : const Color(0xFF12142A),
                  border: Border.all(color: sel ? Color(p['color'] as int) : const Color(0xFF1A1D38), width: sel ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? Color(p['color'] as int) : Colors.transparent,
                      border: Border.all(color: sel ? Color(p['color'] as int) : Colors.white24, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name'] as String,
                        style: GoogleFonts.montserrat(color: Color(p['color'] as int), fontSize: 14, fontWeight: FontWeight.w900)),
                    Text(p['sub'] as String,
                        style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
                  ])),
                  Text(p['price'] as String,
                      style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                if (selected == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Choisissez un plan d\'abord'),
                    backgroundColor: Color(0xFF7C3AED),
                  ));
                  return;
                }
                Navigator.pop(ctx);
                _showLincooPaymentSheet(context, packs[selected!]);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Continuer', textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ]),
      )),
    );
  }

  void _showLincooPaymentSheet(BuildContext context, Map pack) {
    int method = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C0E1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Méthode de paiement',
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Plan ${pack['name']} · ${pack['price']}',
                style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 20),
            ...['Carte CIB / Edahabia', 'Virement bancaire', 'Paiement en agence'].asMap().entries.map((e) =>
              GestureDetector(
                onTap: () => ss(() => method = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: method == e.key ? const Color(0xFF7C3AED).withValues(alpha: 0.12) : const Color(0xFF12142A),
                    border: Border.all(color: method == e.key ? const Color(0xFF7C3AED) : const Color(0xFF1A1D38)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(width: 9, height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: method == e.key ? const Color(0xFF7C3AED) : Colors.transparent,
                        border: Border.all(color: method == e.key ? const Color(0xFF7C3AED) : Colors.white24, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(e.value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  if (kIsWeb) {
                    launchUrl(Uri.parse('/lincoo-plus/'), webOnlyWindowName: '_blank');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFFFB800)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Accéder à Lincoo+', textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREATOR VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCreatorBody(BuildContext context) {
    final reelsList  = _storePosts.where((p) => p['post_type'] == 'reel').toList();
    final postsList  = _storePosts.where((p) => p['post_type'] != 'reel').toList();

    return Column(children: [
      // ── Top bar ──────────────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
        child: Row(children: [
          Text('Mon Profil',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          _iconBtn(Icons.notifications_outlined,
              () => Navigator.pushNamed(context, '/notifications')),
          _iconBtn(Icons.settings_outlined,
              () => Navigator.pushNamed(context, '/settings')),
        ]),
      ),

      Expanded(
        child: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            // ── Creator hero card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Stack(children: [
                      _avatarCircle(size: 80, radius: 24, fontSize: 30, accentGradient: true),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/edit-profile').then((_) => _refresh()),
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 12, color: AppColors.nearBlack),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(
                            child: Text(_name,
                                style: GoogleFonts.montserrat(
                                    color: AppColors.nearBlack, fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                          ),
                          if (_status == ProStatus.verified) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.verified_rounded, color: AppColors.blue, size: 18),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        ShaderMask(
                          shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                          child: Text('Lincoo Creator',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<int>(
                          valueListenable: RewardsService.instance.xp,
                          builder: (_, xp, __) => Text(
                            '${RewardsService.instance.level.value.label} · $xp XP',
                            style: GoogleFonts.montserrat(color: AppColors.grayLight, fontSize: 11),
                          ),
                        ),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/edit-profile').then((_) => _refresh()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightGray),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Modifier',
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack, fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // ── Stats row: Reels · Posts · Abonnés ───────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Expanded(child: _statCol('${reelsList.length}', 'Reels')),
                      Container(width: 1, height: 30, color: AppColors.lightGray),
                      Expanded(child: _statCol('${postsList.length}', 'Posts')),
                      Container(width: 1, height: 30, color: AppColors.lightGray),
                      Expanded(child: _statCol(_fmt(_followersCount), 'Abonnés')),
                    ]),
                  ),

                  const SizedBox(height: 14),

                  // ── Lincoo Creator Space banner ───────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/creator-space'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF020024), Color(0xFF0A0F2C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ShaderMask(
                            shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                            child: Text('Lincoo Creator Space',
                                style: GoogleFonts.montserrat(
                                    color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(height: 2),
                          Text('Missions · XP · Coins · Campagnes',
                              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
                        ])),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Tab bar ───────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _creatorTabs,
                    labelColor: AppColors.nearBlack,
                    unselectedLabelColor: AppColors.grayLight,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: AppColors.lightGray,
                    labelStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800),
                    unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [Tab(text: 'Reels'), Tab(text: 'Posts')],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _creatorTabs,
            children: [
              _creatorGrid(reelsList, isReel: true),
              _creatorGrid(postsList, isReel: false),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _creatorGrid(List<Map<String, dynamic>> items, {required bool isReel}) {
    if (_postsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isReel ? Icons.videocam_outlined : Icons.photo_outlined,
              size: 44, color: AppColors.lightGray),
          const SizedBox(height: 10),
          Text(isReel ? 'Aucun reel publié' : 'Aucun post publié',
              style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/create-post');
              if (result == true && mounted) _loadPosts();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isReel ? '+ Créer un Reel' : '+ Créer un Post',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p       = items[i];
        final urls    = (p['media_urls'] as List?)?.cast<String>() ?? [];
        final cover   = p['cover_url'] as String?;
        final imgUrl  = cover ?? (urls.isNotEmpty ? urls.first : null);
        return Stack(fit: StackFit.expand, children: [
          imgUrl != null
              ? Image.network(imgUrl, fit: BoxFit.cover)
              : Container(color: AppColors.surfaceAlt,
                  child: Icon(isReel ? Icons.videocam_outlined : Icons.photo_outlined,
                      color: AppColors.lightGray, size: 28)),
          if (isReel)
            const Positioned(
              bottom: 5, left: 5,
              child: Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
            ),
        ]);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUYER VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBuyerHeader(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
    child: Row(children: [
      Text('Mon Profil',
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 18,
              fontWeight: FontWeight.w900)),
      const Spacer(),
      _iconBtn(Icons.notifications_outlined,
          () => Navigator.pushNamed(context, '/notifications')),
      _iconBtn(Icons.settings_outlined,
          () => Navigator.pushNamed(context, '/settings')),
    ]),
  );

  Widget _buildBuyerBody(BuildContext context) {
    final tabs = TabController(length: 2, vsync: this);
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buyerHero(context),
        const SizedBox(height: 12),
        _buyerStats(),
        const SizedBox(height: 12),
        _creatorCard(context),
        const SizedBox(height: 12),
        _buyerQuickActions(context),
        const SizedBox(height: 12),
        Container(
          color: Colors.white,
          child: Column(children: [
            TabBar(
              controller: tabs,
              labelColor: AppColors.nearBlack,
              unselectedLabelColor: AppColors.grayLight,
              indicatorColor: AppColors.nearBlack,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AppColors.lightGray,
              labelStyle: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w800),
              unselectedLabelStyle: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [Tab(text: 'Favoris'), Tab(text: 'Commandes')],
            ),
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: tabs,
                children: [
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: WishlistService.instance.items,
                    builder: (_, prods, __) => prods.isEmpty
                        ? _emptyState(Icons.favorite_outline, 'Aucun favori')
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            itemCount: prods.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            itemBuilder: (_, i) => _wishlistTile(prods[i]),
                          ),
                  ),
                  _emptyState(Icons.receipt_long_outlined, 'Aucune commande'),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buyerHero(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    child: Row(children: [
      Stack(children: [
        _avatarCircle(size: 80, radius: 24, fontSize: 30, accentGradient: false),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/edit-profile')
                .then((_) => _refresh()),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 12, color: AppColors.nearBlack),
            ),
          ),
        ),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_name,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(_email,
              style: GoogleFonts.montserrat(
                  color: AppColors.grayLight, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          _roleBadge(),
        ]),
      ),
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/edit-profile')
            .then((_) => _refresh()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGray),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Modifier',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );

  Widget _buyerStats() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _stat('0', 'Commandes'),
      _vDivider(),
      ValueListenableBuilder<Set<String>>(
        valueListenable: WishlistService.instance.ids,
        builder: (_, ids, __) => _stat('${ids.length}', 'Favoris'),
      ),
      _vDivider(),
      _stat('0', 'Avis'),
      _vDivider(),
      _stat('0 DA', 'Wallet'),
    ]),
  );

  Widget _creatorCard(BuildContext context) {
    // Sellers and companies cannot be creators
    if (_role == ProRole.seller || _role == ProRole.company) {
      return const SizedBox.shrink();
    }

    final isPending = _status == ProStatus.pending && _role == ProRole.creator;
    final isCreator = _role == ProRole.creator && _status == ProStatus.verified;

    if (isCreator) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/creator-space'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF020024), Color(0xFF0A0F2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                ShaderMask(
                  shaderCallback: (r) =>
                      AppColors.brandGradient.createShader(r),
                  child: Text('Lincoo Creator',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: RewardsService.instance.xp,
                  builder: (_, xp, __) => Text(
                    '${RewardsService.instance.level.value.label}  ·  $xp XP',
                    style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 11),
                  ),
                ),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ]),
        ),
      );
    }

    if (isPending) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.hourglass_top_rounded,
              color: AppColors.gold, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Demande en cours',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text('L\'équipe Lincoo valide votre profil creator.',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
            ]),
          ),
        ]),
      );
    }

    // Not a creator yet — invite card
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/creator-apply'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF020024), Color(0xFF0A0F2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              ShaderMask(
                shaderCallback: (r) =>
                    AppColors.brandGradient.createShader(r),
                child: Text('Devenir Lincoo Creator',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ),
              Text('XP · Coins · Niveaux · Campagnes',
                  style: GoogleFonts.montserrat(
                      color: Colors.white38, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.blue]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Rejoindre',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _buyerQuickActions(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _actionItem(Icons.shopping_bag_outlined, 'Commandes', AppColors.blue,
          () => Navigator.pushNamed(context, '/my-orders')),
      _actionItem(Icons.favorite_outline, 'Favoris', AppColors.error,
          () => Navigator.pushNamed(context, '/favorites')),
      _actionItem(Icons.account_balance_wallet_outlined, 'Wallet',
          AppColors.success,
          () => Navigator.pushNamed(context, '/wallet')),
      _actionItem(Icons.star_outline, 'Récompenses', const Color(0xFFFFB300),
          () => Navigator.pushNamed(context, '/rewards')),
    ]),
  );

  Widget _emptyState(IconData icon, String label) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 36, color: AppColors.lightGray),
      const SizedBox(height: 8),
      Text(label,
          style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 13)),
    ]),
  );

  Widget _wishlistTile(Map<String, dynamic> prod) {
    final name  = prod['name']  as String? ?? '';
    final price = (prod['price']  as num?)?.toDouble() ?? 0;
    final promo = (prod['promo_price'] as num?)?.toDouble();
    final images = prod['images'];
    String? imgUrl;
    if (images is List && images.isNotEmpty && images.first is String) {
      imgUrl = images.first as String;
    }
    final storeRaw = prod['stores'];
    String storeName = '';
    if (storeRaw is Map) storeName = storeRaw['store_name'] as String? ?? '';

    final displayPrice = promo ?? price;
    final fmt = displayPrice.toStringAsFixed(0);
    final fmtStr = fmt.length > 3
        ? '${fmt.substring(0, fmt.length - 3)} ${fmt.substring(fmt.length - 3)}'
        : fmt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imgUrl != null
              ? Image.network(imgUrl,
                  width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56, color: AppColors.bgGray,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.lightGray, size: 24)))
              : Container(width: 56, height: 56, color: AppColors.bgGray,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.lightGray, size: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (storeName.isNotEmpty)
              Text(storeName,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: AppColors.grayLight),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$fmtStr DA',
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
          if (promo != null && price > promo)
            Text('${price.toStringAsFixed(0)} DA',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: AppColors.grayLight,
                    decoration: TextDecoration.lineThrough)),
        ]),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            final pid = prod['id'] as String?;
            if (pid != null) WishlistService.instance.remove(pid);
          },
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.favorite_rounded, color: AppColors.error, size: 20),
          ),
        ),
      ]),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _avatarCircle({
    required double size,
    required double radius,
    required double fontSize,
    required bool accentGradient,
  }) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    if (_avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(_avatarUrl!,
            width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _avatarInitialBox(size, radius, fontSize, initial, accentGradient)),
      );
    }
    return _avatarInitialBox(size, radius, fontSize, initial, accentGradient);
  }

  Widget _avatarInitialBox(double size, double radius, double fontSize,
      String initial, bool accentGradient) =>
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: accentGradient
                ? [AppColors.accent, AppColors.blue]
                : [AppColors.nearBlack, AppColors.dark],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Text(initial,
              style: GoogleFonts.montserrat(
                  color: accentGradient ? AppColors.nearBlack : Colors.white,
                  fontSize: fontSize, fontWeight: FontWeight.w900)),
        ),
      );

  Widget _roleBadge() {
    final label = switch (_role) {
      ProRole.seller  => 'Vendeur',
      ProRole.company => 'Entreprise',
      ProRole.creator => 'Créateur',
      ProRole.buyer   => 'Acheteur',
      _               => 'Utilisateur',
    };
    final color = switch (_role) {
      ProRole.seller  => AppColors.accent,
      ProRole.company => AppColors.blue,
      ProRole.creator => AppColors.purple,
      _               => AppColors.gray,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.montserrat(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38, margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, size: 19, color: AppColors.nearBlack),
    ),
  );

  Widget _actionItem(IconData icon, String label, Color color,
      VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _stat(String value, String label) => Column(children: [
    Text(value,
        style: GoogleFonts.montserrat(
            color: AppColors.nearBlack, fontSize: 17,
            fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label,
        style: GoogleFonts.montserrat(
            color: AppColors.grayLight, fontSize: 10,
            fontWeight: FontWeight.w500)),
  ]);

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: AppColors.lightGray);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Se déconnecter',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnecter',
                style: GoogleFonts.montserrat(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      UserSession.instance.update(AppUser.demo());
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }
}

// ── Add / Edit product sheet ──────────────────────────────────────────────────

class _AddProductSheet extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  final ImagePicker picker;

  const _AddProductSheet({
    required this.storeId,
    required this.onSaved,
    required this.picker,
    this.existing,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  // ── Basic fields ───────────────────────────────────────────────────────────
  String?      _category;
  String?      _subcategory;
  bool         _available       = true;
  bool         _saving          = false;
  String?      _errorMsg;

  // ── Images ─────────────────────────────────────────────────────────────────
  List<String>    _existingUrls = [];
  final List<Uint8List> _newBytes     = [];

  // ── Variantes (avec qty individuelle) ────────────────────────────────────
  // [{size:'M', qty:10}, ...]
  final List<Map<String, dynamic>> _sizeVariants  = [];
  // [{name:'Noir', hex:'#1A1A1A', qty:8}, ...]
  final List<Map<String, dynamic>> _colorVariants = [];

  // ── Stock global (utilisé si aucune variante) ─────────────────────────────
  bool _isLimitedStock = false;

  // ── Offre ──────────────────────────────────────────────────────────────────
  String? _offerTag;

  // ── Static data ────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _cats = {
    'Mode':         ['Femme', 'Homme', 'Enfant', 'Hijab', 'Chaussures', 'Accessoires'],
    'Beauté':       ['Maquillage', 'Soins visage', 'Parfums', 'Cheveux', 'Ongles'],
    'Électronique': ['Téléphones', 'PC & Tablettes', 'Audio', 'Gaming', 'Accessoires'],
    'Maison':       ['Décoration', 'Linge de maison', 'Cuisine', 'Jardin'],
    'Alimentation': ['Épicerie', 'Pâtisserie', 'Boissons', 'Bio'],
    'Artisanat':    ['Broderie', 'Poterie', 'Bijoux artisanaux', 'Tissage'],
    'Automobile':   ['Pièces détachées', 'Accessoires auto', 'Entretien'],
    'Sport':        ['Fitness', 'Football', 'Running', 'Arts martiaux'],
    'Services':     ['Livraison', 'Couture', 'Conseil mode', 'Photographie'],
    'Autres':       ['Livres', 'Jouets', 'Animaux', 'Fournitures'],
  };

  static const _allSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', '3XL', 'Unique',
    '36', '37', '38', '39', '40', '41', '42', '43', '44', '45',
    '1', '2', '3',
  ];

  static const _colorPalette = [
    {'name': 'Noir',       'hex': '#1A1A1A'},
    {'name': 'Blanc',      'hex': '#F5F5F5'},
    {'name': 'Gris',       'hex': '#9E9E9E'},
    {'name': 'Rouge',      'hex': '#E53935'},
    {'name': 'Rose',       'hex': '#EC407A'},
    {'name': 'Orange',     'hex': '#FF6D00'},
    {'name': 'Jaune',      'hex': '#FFC107'},
    {'name': 'Vert',       'hex': '#2E7D32'},
    {'name': 'Bleu',       'hex': '#1565C0'},
    {'name': 'Bleu ciel',  'hex': '#48AAD4'},
    {'name': 'Violet',     'hex': '#7B1FA2'},
    {'name': 'Bordeaux',   'hex': '#6E1128'},
    {'name': 'Beige',      'hex': '#D4B896'},
    {'name': 'Marron',     'hex': '#5D4037'},
    {'name': 'Kaki',       'hex': '#827717'},
    {'name': 'Camel',      'hex': '#C8A96E'},
  ];

  static const _offerTags = [
    'Nouveauté 🆕',
    'Soldes 🏷️',
    'Big Promo 🔥',
    'Summer Edition ☀️',
    'Back to School 📚',
    'Édition Limitée ⭐',
    'Collection Spéciale 💎',
    'Flash Sale ⚡',
    'Stock Limité ⏳',
    'Best Seller 🏆',
  ];

  bool get _isEdit => widget.existing != null;
  bool get _hasVariants => _sizeVariants.isNotEmpty || _colorVariants.isNotEmpty;
  int  get _totalVariantStock {
    final sTotal = _sizeVariants.fold<int>(
        0, (s, v) => s + ((v['qty'] as int?) ?? 0));
    final cTotal = _colorVariants.fold<int>(
        0, (s, v) => s + ((v['qty'] as int?) ?? 0));
    return sTotal + cTotal;
  }

  // ── Taille helpers ─────────────────────────────────────────────────────────
  bool _isSizeSelected(String s) =>
      _sizeVariants.any((v) => v['size'] == s);

  void _toggleSize(String s) {
    setState(() {
      if (_isSizeSelected(s)) {
        _sizeVariants.removeWhere((v) => v['size'] == s);
      } else {
        _sizeVariants.add({'size': s, 'qty': 0});
      }
    });
  }

  void _setSizeQty(String s, int qty) {
    setState(() {
      final i = _sizeVariants.indexWhere((v) => v['size'] == s);
      if (i >= 0) _sizeVariants[i]['qty'] = qty.clamp(0, 9999);
    });
  }

  // ── Couleur helpers ────────────────────────────────────────────────────────
  bool _isColorSelected(String hex) =>
      _colorVariants.any((v) => v['hex'] == hex);

  void _toggleColor(String name, String hex) {
    setState(() {
      if (_isColorSelected(hex)) {
        _colorVariants.removeWhere((v) => v['hex'] == hex);
      } else {
        _colorVariants.add({'name': name, 'hex': hex, 'qty': 0});
      }
    });
  }

  void _setColorQty(String hex, int qty) {
    setState(() {
      final i = _colorVariants.indexWhere((v) => v['hex'] == hex);
      if (i >= 0) _colorVariants[i]['qty'] = qty.clamp(0, 9999);
    });
  }

  // ── Variant row widget (size ou couleur avec +/−) ─────────────────────────
  Widget _variantRow({
    required String label,
    required int qty,
    required VoidCallback onDec,
    required VoidCallback onInc,
    required VoidCallback onRemove,
    Color? colorDot,
    bool isDotLight = false,
  }) {
    final isRupture = qty == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRupture
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.lightGray,
        ),
      ),
      child: Row(children: [
        if (colorDot != null)
          Container(
            width: 20, height: 20,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorDot,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDotLight ? AppColors.lightGray : Colors.transparent,
                width: 0.8,
              ),
            ),
          ),
        Expanded(
          child: Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack)),
        ),
        if (isRupture)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('Rupture',
                style: GoogleFonts.montserrat(
                    fontSize: 9, color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ),
        // − bouton
        GestureDetector(
          onTap: onDec,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.remove, size: 14, color: AppColors.nearBlack),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text('$qty',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
        ),
        // + bouton
        GestureDetector(
          onTap: onInc,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), AppColors.blue]),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, size: 14, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 16, color: AppColors.gray),
        ),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text  = e['name']        as String? ?? '';
      _descCtrl.text  = e['description'] as String? ?? '';
      _priceCtrl.text = (e['price']      as num?)?.toString() ?? '';
      _promoCtrl.text = (e['promo_price'] as num?)?.toString() ?? '';
      _category    = e['category']   as String?;
      _subcategory = e['subcategory'] as String?;
      _available   = e['available']  as bool? ?? true;
      _existingUrls = List<String>.from(e['images'] as List? ?? []);
      // Variantes tailles
      final rawSizes = e['size_variants'] as List?;
      if (rawSizes != null) {
        _sizeVariants.addAll(rawSizes.map(
            (s) => Map<String, dynamic>.from(s as Map)));
      }
      // Variantes couleurs
      final rawColors = e['color_variants'] as List?;
      if (rawColors != null) {
        _colorVariants.addAll(rawColors.map(
            (c) => Map<String, dynamic>.from(c as Map)));
      }
      // Stock global (fallback si aucune variante)
      final qty = e['stock_qty'] as int?;
      _isLimitedStock = qty != null;
      if (qty != null) _stockCtrl.text = qty.toString();
      // Offre
      _offerTag = e['offer_tag'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();  _descCtrl.dispose();
    _priceCtrl.dispose(); _promoCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final total = _existingUrls.length + _newBytes.length;
    if (total >= 4) return;
    final f = await widget.picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() => _newBytes.add(bytes));
  }

  Future<List<String>> _uploadNewImages() async {
    if (_newBytes.isEmpty) return [];
    final urls   = <String>[];
    Object? lastErr;
    for (final bytes in _newBytes) {
      try {
        final path =
            '${widget.storeId}/${DateTime.now().microsecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product-images')
            .uploadBinary(path, bytes,
                fileOptions: const FileOptions(
                    contentType: 'image/jpeg', upsert: true));
        final url = Supabase.instance.client.storage
            .from('product-images')
            .getPublicUrl(path);
        urls.add(url);
      } catch (e) {
        lastErr = e;
      }
    }
    // Si aucune image n'a été uploadée mais qu'on en avait, signaler l'erreur
    if (urls.isEmpty && lastErr != null) {
      throw Exception(
          'Upload images échoué : $lastErr\n'
          '→ Créez le bucket "product-images" (public) dans '
          'Supabase Dashboard > Storage.');
    }
    return urls;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _err('Le nom du produit est obligatoire.');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      _err('Veuillez entrer un prix valide.');
      return;
    }
    if (widget.storeId.isEmpty) {
      _err('Boutique introuvable. Rechargez la page et réessayez.');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    try {
      final uploadedUrls = await _uploadNewImages();
      final allImages = [..._existingUrls, ...uploadedUrls];
      final promo = double.tryParse(_promoCtrl.text.trim());

      // ── Étape 1 : champs de base (toujours présents en DB) ──────────────
      final coreData = {
        'store_id':    widget.storeId,
        'name':        name,
        'description': _descCtrl.text.trim().isEmpty
            ? null : _descCtrl.text.trim(),
        'price':       price,
        'promo_price': (promo != null && promo > 0 && promo < price)
            ? promo : null,
        'images':      allImages,
        'category':    _category,
        'subcategory': _subcategory,
        'available':   _available,
      };

      String productId;
      if (_isEdit) {
        productId = widget.existing!['id'] as String;
        await Supabase.instance.client
            .from('products')
            .update(coreData)
            .eq('id', productId);
      } else {
        final res = await Supabase.instance.client
            .from('products')
            .insert(coreData)
            .select('id')
            .single();
        productId = res['id'] as String;
      }

      // ── Étape 2 : champs étendus (silencieux si migration pas encore faite)
      try {
        await Supabase.instance.client.from('products').update({
          'size_variants':  _sizeVariants,
          'color_variants': _colorVariants,
          'stock_qty': _hasVariants
              ? _totalVariantStock
              : (_isLimitedStock
                  ? int.tryParse(_stockCtrl.text.trim())
                  : null),
          'offer_tag': _offerTag,
        }).eq('id', productId);
      } catch (_) {}

      // Invalidate feed cache so the new product appears immediately
      AppCache.instance.invalidate(AppCache.kFeedProducts);
      AppCache.instance.invalidate(AppCache.kShopProducts);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isEdit ? 'Produit mis à jour ✓' : 'Produit ajouté ✓',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) _err('Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _err(String msg) {
    if (mounted) {
      setState(() => _errorMsg = msg);
      // SnackBar en fallback (peut être masqué par la modale sur certaines configs)
      try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(4)),
          ),
          // Header
          Container(
            color: AppColors.nearBlack,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.blue]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.nearBlack, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                _isEdit ? 'Modifier le produit' : 'Nouveau produit',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.gray),
              ),
            ]),
          ),

          // Form
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // ── Images ──────────────────────────────────────────────
                _section('Photos du produit', Icons.photo_library_outlined,
                    AppColors.purple, [
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Existing images
                        ..._existingUrls.asMap().entries.map((e) => Stack(
                          children: [
                            Container(
                              width: 90, height: 90,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(e.value,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.bgGray,
                                        child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.lightGray))),
                              ),
                            ),
                            Positioned(
                              top: 0, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _existingUrls.removeAt(e.key)),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        )),
                        // New bytes
                        ..._newBytes.asMap().entries.map((e) => Stack(
                          children: [
                            Container(
                              width: 90, height: 90,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(e.value,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 0, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _newBytes.removeAt(e.key)),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        )),
                        // Add button
                        if (_existingUrls.length + _newBytes.length < 4)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.bgGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.lightGray,
                                    style: BorderStyle.solid),
                              ),
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    color: AppColors.gray, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '${_existingUrls.length + _newBytes.length}/4',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 10, color: AppColors.gray),
                                ),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),

                // ── Infos de base ────────────────────────────────────────
                _section('Informations', Icons.info_outline, AppColors.blue, [
                  _label('Nom du produit *'),
                  _tf(_nameCtrl, 'Ex: Robe d\'été fleurie', lines: 1),
                  _label('Description'),
                  _tf(_descCtrl,
                      'Décrivez le produit, matière, dimensions…',
                      lines: 3),
                ]),

                // ── Prix ─────────────────────────────────────────────────
                _section('Prix', Icons.sell_outlined, AppColors.accent, [
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Prix normal *'),
                        _tf(_priceCtrl, '0',
                            kb: TextInputType.number, suffix: 'DA'),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Prix promo'),
                        _tf(_promoCtrl, '0',
                            kb: TextInputType.number, suffix: 'DA'),
                      ],
                    )),
                  ]),
                  if (_priceCtrl.text.isNotEmpty &&
                      _promoCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final p = double.tryParse(_priceCtrl.text);
                      final r = double.tryParse(_promoCtrl.text);
                      if (p == null || r == null || r >= p) {
                        return const SizedBox.shrink();
                      }
                      final pct = ((1 - r / p) * 100).round();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Réduction de $pct%',
                            style: GoogleFonts.montserrat(
                                color: AppColors.error, fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      );
                    }),
                  ],
                ]),

                // ── Catégorie ─────────────────────────────────────────────
                _section('Catégorie', Icons.category_outlined,
                    AppColors.gold, [
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _cats.keys.map((cat) => GestureDetector(
                      onTap: () => setState(() {
                        _category    = cat;
                        _subcategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _category == cat
                              ? const LinearGradient(
                                  colors: [AppColors.accent, AppColors.blue])
                              : null,
                          color: _category == cat ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _category == cat
                                ? Colors.transparent : AppColors.lightGray,
                          ),
                        ),
                        child: Text(cat,
                            style: GoogleFonts.montserrat(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: _category == cat
                                    ? AppColors.nearBlack : AppColors.gray)),
                      ),
                    )).toList(),
                  ),
                  if (_category != null) ...[
                    const SizedBox(height: 12),
                    Text('Sous-catégorie',
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: AppColors.gray,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (_cats[_category] ?? []).map((sub) =>
                        GestureDetector(
                          onTap: () =>
                              setState(() => _subcategory = sub),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _subcategory == sub
                                  ? AppColors.nearBlack : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _subcategory == sub
                                    ? AppColors.nearBlack
                                    : AppColors.lightGray,
                              ),
                            ),
                            child: Text(sub,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _subcategory == sub
                                        ? Colors.white : AppColors.gray)),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ]),

                // ── Variantes ────────────────────────────────────────────
                _section('Variantes & Stock', Icons.tune_outlined,
                    const Color(0xFF7B1FA2), [

                  // ── Tailles ─────────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.straighten_outlined,
                          size: 13, color: Color(0xFF7B1FA2)),
                    ),
                    const SizedBox(width: 8),
                    Text('Tailles disponibles',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: AppColors.nearBlack)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _allSizes.map((s) {
                      final sel = _isSizeSelected(s);
                      return GestureDetector(
                        onTap: () => _toggleSize(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 52, height: 40,
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF7B1FA2) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF7B1FA2)
                                  : AppColors.lightGray,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(s,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white : AppColors.nearBlack)),
                        ),
                      );
                    }).toList(),
                  ),

                  // Quantité par taille
                  if (_sizeVariants.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: AppColors.gray),
                      const SizedBox(width: 6),
                      Text('Quantité par taille',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppColors.gray,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    ..._sizeVariants.map((v) {
                      final s   = v['size'] as String;
                      final qty = (v['qty'] as int?) ?? 0;
                      return _variantRow(
                        label: s,
                        qty: qty,
                        onDec: () => _setSizeQty(s, qty - 1),
                        onInc: () => _setSizeQty(s, qty + 1),
                        onRemove: () => _toggleSize(s),
                      );
                    }),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.summarize_outlined,
                            size: 13, color: AppColors.gray),
                        const SizedBox(width: 6),
                        Text('Total stock tailles : ',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: AppColors.gray)),
                        Text(
                          '${_sizeVariants.fold<int>(0, (s, v) => s + ((v['qty'] as int?) ?? 0))} unités',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: AppColors.nearBlack),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // ── Couleurs ─────────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.palette_outlined,
                          size: 13, color: Color(0xFF7B1FA2)),
                    ),
                    const SizedBox(width: 8),
                    Text('Couleurs disponibles',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: AppColors.nearBlack)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _colorPalette.map((c) {
                      final hex   = c['hex']!;
                      final name  = c['name']!;
                      final color = Color(int.parse(
                          hex.replaceFirst('#', 'FF'), radix: 16));
                      final isSel = _isColorSelected(hex);
                      return GestureDetector(
                        onTap: () => _toggleColor(name, hex),
                        child: Tooltip(
                          message: name,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF7B1FA2)
                                    : (hex == '#F5F5F5'
                                        ? AppColors.lightGray
                                        : Colors.transparent),
                                width: isSel ? 3 : 1,
                              ),
                              boxShadow: isSel
                                  ? [BoxShadow(
                                      color: const Color(0xFF7B1FA2)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8)]
                                  : null,
                            ),
                            child: isSel
                                ? Icon(Icons.check, size: 16,
                                    color: hex == '#F5F5F5'
                                        ? AppColors.nearBlack : Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Quantité par couleur
                  if (_colorVariants.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: AppColors.gray),
                      const SizedBox(width: 6),
                      Text('Quantité par couleur',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppColors.gray,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    ..._colorVariants.map((v) {
                      final hex  = v['hex']  as String;
                      final name = v['name'] as String;
                      final qty  = (v['qty'] as int?) ?? 0;
                      final dot  = Color(int.parse(
                          hex.replaceFirst('#', 'FF'), radix: 16));
                      return _variantRow(
                        label: name,
                        qty: qty,
                        colorDot: dot,
                        isDotLight: hex == '#F5F5F5',
                        onDec: () => _setColorQty(hex, qty - 1),
                        onInc: () => _setColorQty(hex, qty + 1),
                        onRemove: () => _toggleColor(name, hex),
                      );
                    }),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.summarize_outlined,
                            size: 13, color: AppColors.gray),
                        const SizedBox(width: 6),
                        Text('Total stock couleurs : ',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: AppColors.gray)),
                        Text(
                          '${_colorVariants.fold<int>(0, (s, v) => s + ((v['qty'] as int?) ?? 0))} unités',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: AppColors.nearBlack),
                        ),
                      ]),
                    ),
                  ],

                  // Stock global (si aucune variante)
                  if (!_hasVariants) ...[
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.inventory_outlined,
                            size: 13, color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      Text('Stock global',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: AppColors.nearBlack)),
                      const Spacer(),
                      Switch(
                        value: _isLimitedStock,
                        onChanged: (v) => setState(() {
                          _isLimitedStock = v;
                          if (!v) _stockCtrl.clear();
                        }),
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.teal,
                      ),
                    ]),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isLimitedStock
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _tf(_stockCtrl, '0',
                                  kb: TextInputType.number,
                                  suffix: 'unités'),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Text(
                      'Ajoutez des tailles ou couleurs pour gérer le stock par variante',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: AppColors.gray,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ]),

                // ── Offre promotionnelle ──────────────────────────────────
                _section('Offre / Badge', Icons.local_offer_outlined,
                    AppColors.error, [
                  Text(
                    'Affiche un badge promotionnel sur votre produit.',
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: AppColors.gray),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _offerTags.map((tag) {
                      final sel = _offerTag == tag;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _offerTag = sel ? null : tag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.nearBlack : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.nearBlack : AppColors.lightGray,
                            ),
                          ),
                          child: Text(tag,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white : AppColors.gray)),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_offerTag != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => setState(() => _offerTag = null),
                      child: Text('✕ Retirer le badge',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppColors.error,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),

                // ── Disponibilité ─────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: (_available
                            ? Colors.green : AppColors.error)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _available
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: _available ? Colors.green : AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Disponible à la vente',
                            style: GoogleFonts.montserrat(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColors.nearBlack)),
                        Text(
                          _available
                              ? 'Visible sur la boutique'
                              : 'Masqué des acheteurs',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppColors.gray),
                        ),
                      ]),
                    ),
                    Switch(
                      value: _available,
                      onChanged: (v) => setState(() => _available = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green,
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // Erreur inline (visible même quand SnackBar est masqué par la modale)
          if (_errorMsg != null)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.08),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMsg!,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _errorMsg = null),
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.error),
                ),
              ]),
            ),

          // Save button
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _saving
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.accent, AppColors.blue]),
                    color: _saving ? AppColors.lightGray : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _saving
                        ? null
                        : [BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: InkWell(
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: AppColors.nearBlack, strokeWidth: 2))
                          : Text(
                              _isEdit
                                  ? 'Mettre à jour le produit'
                                  : 'Publier le produit',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.nearBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color,
      List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: GoogleFonts.montserrat(
            fontSize: 11, color: AppColors.gray,
            fontWeight: FontWeight.w600)),
  );

  Widget _tf(TextEditingController ctrl, String hint, {
    TextInputType kb = TextInputType.text,
    int lines = 1,
    String? suffix,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: kb,
        maxLines: lines,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.montserrat(
            fontSize: 13, color: AppColors.nearBlack),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
              fontSize: 13, color: AppColors.gray),
          suffixText: suffix,
          suffixStyle: GoogleFonts.montserrat(
              fontSize: 13, color: AppColors.gray,
              fontWeight: FontWeight.w600),
          filled: true,
          fillColor: AppColors.bgGray,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.accent, width: 1.5)),
        ),
      ),
    );
}

// ── Sliver tab bar delegate ───────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _TabBarDelegate(this.child);

  @override double get minExtent => 48;
  @override double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: overlapsContent
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: child,
      );

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.child != child;
}

