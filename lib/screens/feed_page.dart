import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../models/ad_campaign.dart';
import '../models/app_user.dart';
import '../services/user_session.dart';
import '../services/app_cache.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../services/likes_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/comment_sheet.dart';


class _StoreCardData {
  final String  name;
  final String  category;
  final Color   color;
  final String  initials;
  final bool    isFollowing;
  final String? storeId;
  final String? logoUrl;
  const _StoreCardData(this.name, this.category, this.color, this.initials,
      {this.isFollowing = false, this.storeId, this.logoUrl});
}

class _AdSlide {
  final String title;
  final String subtitle;
  final String desc;
  final List<Color> colors;
  final String badge;
  const _AdSlide(
      this.title, this.subtitle, this.desc, this.colors, this.badge);
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedPage
// ─────────────────────────────────────────────────────────────────────────────

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PageController _adCtrl = PageController();
  int _adPage = 0;
  Timer? _adTimer;
  StreamSubscription?       _campaignsSubscription;
  List<AdCampaign>          _liveCampaigns  = [];
  List<_StoreCardData>      _liveStores     = [];
  List<Map<String, dynamic>> _feedProducts  = [];
  bool                      _feedLoading    = false;

  static const List<_AdSlide> _adSlides = [
    _AdSlide('Djezzy APP', 'أريح وقتك',
        'عبئوا أو سددوا الفاتورة باستعمال البطاقة البنكية',
        [Color(0xFFBB0000), Color(0xFFEE2222)], 'DJEZZY'),
    _AdSlide('Summer Sale', 'Jusqu\'à −50%',
        'Sur toute la collection femme été 2026',
        [Color(0xFF1B5E20), Color(0xFF43A047)], 'PROMO'),
    _AdSlide('Smart Delivery', 'Économisez 400 DA',
        'Livraison groupée pour 2 produits ou plus',
        [Color(0xFF292526), Color(0xFF6E1128)], 'LINCOO'),
  ];

  Future<void> _loadStores() async {
    // Retour immédiat depuis le cache si frais
    final cached = AppCache.instance.get<List<_StoreCardData>>(AppCache.kStores);
    if (cached != null && mounted) {
      setState(() => _liveStores = cached);
      return;
    }
    try {
      final client = Supabase.instance.client;
      final user   = UserSession.instance.current;

      final realProfiles = await client
          .from('profiles')
          .select('id')
          .inFilter('pro_role', ['seller', 'company', 'creator'])
          .eq('onboarding_complete', true);
      final ownerIds = (realProfiles as List)
          .map<String?>((row) => row['id'] is String ? row['id'] as String : null)
          .whereType<String>()
          .toSet()
          .toList();
      if (ownerIds.isEmpty) return;

      // 1. Boutiques
      final rows = await client
          .from('stores')
          .select('id, store_name, category, logo_url, is_verified, owner_id')
          .inFilter('owner_id', ownerIds)
          .order('followers_count', ascending: false)
          .limit(10);
      if ((rows as List).isEmpty) return;

      // 2. Boutiques suivies par l'utilisateur
      final Set<String> followedIds = {};
      if (!user.isGuest) {
        try {
          final follows = await client
              .from('store_follows')
              .select('store_id')
              .eq('follower_id', user.id);
          for (final f in (follows as List)) {
            final sid = f['store_id'];
            if (sid is String) followedIds.add(sid);
          }
        } catch (_) {}
      }

      // 3. Nom réel + avatar depuis profiles (source de vérité)
      final ownerIdsForProfiles = rows
          .map<String?>((s) => s['owner_id'] is String ? s['owner_id'] as String : null)
          .whereType<String>()
          .toList();
      // Map ownerId → { avatar_url, store_name }
      final Map<String, Map<String, String?>> profileByOwner = {};
      if (ownerIdsForProfiles.isNotEmpty) {
        try {
          final profiles = await client
              .from('profiles')
              .select('id, avatar_url, store_name')
              .inFilter('id', ownerIdsForProfiles);
          for (final p in (profiles as List)) {
            if (p['id'] is String) {
              profileByOwner[p['id'] as String] = {
                'avatar_url': p['avatar_url'] is String ? p['avatar_url'] as String : null,
                'store_name': p['store_name'] is String ? p['store_name'] as String : null,
              };
            }
          }
        } catch (_) {}
      }

      final colors = [
        const Color(0xFF121111), const Color(0xFF7B1FA2),
        const Color(0xFF8B2635), const Color(0xFF1976D2),
        const Color(0xFF1B5E20), const Color(0xFF5D4037),
        const Color(0xFF006064), const Color(0xFF37474F),
      ];

      final stores = rows.asMap().entries.map((e) {
        final m        = Map<String, dynamic>.from(e.value as Map);
        final ownerId  = m['owner_id'] is String ? m['owner_id'] as String : null;
        final storeId  = m['id']       is String ? m['id']       as String : null;
        final prof     = ownerId != null ? profileByOwner[ownerId] : null;
        // Priorité : profiles.store_name → stores.store_name
        final name     = (prof?['store_name']?.isNotEmpty == true
                            ? prof!['store_name']
                            : (m['store_name'] is String ? m['store_name'] as String : null))
                         ?? '';
        // Priorité : stores.logo_url → profiles.avatar_url
        final logoUrl  = (m['logo_url'] is String ? m['logo_url'] as String : null)
                      ?? prof?['avatar_url'];
        return _StoreCardData(
          name,
          m['category'] is String ? m['category'] as String : '',
          colors[e.key % colors.length],
          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
          storeId:     storeId,
          logoUrl:     logoUrl,
          isFollowing: storeId != null && followedIds.contains(storeId),
        );
      }).toList();

      AppCache.instance.set(AppCache.kStores, stores);
      if (mounted) setState(() => _liveStores = stores);
    } catch (_) {}
  }

  Future<void> _loadFeedProducts() async {
    final user = UserSession.instance.current;

    final cached = AppCache.instance.get<List<Map<String, dynamic>>>(AppCache.kFeedProducts);
    if (cached != null && mounted) {
      setState(() { _feedProducts = cached; _feedLoading = false; });
      return;
    }

    if (mounted) setState(() => _feedLoading = true);
    try {
      final client = Supabase.instance.client;

      // Boutiques suivies par l'utilisateur (optionnel — priorisation)
      List<String> followedIds = [];
      if (!user.isGuest) {
        final follows = await client
            .from('store_follows')
            .select('store_id')
            .eq('follower_id', user.id);
        followedIds = (follows as List)
            .map((f) => f['store_id'] as String)
            .toList();
      }

      const colsFull = 'id, name, description, price, promo_price, images, '
          'created_at, available, store_id, offer_tag, '
          'category, subcategory, sold_count, rating, reviews_count, '
          'size_variants, color_variants, stock_qty, '
          'stores(id, store_name, logo_url, rating, reviews_count, '
          'followers_count, is_verified, owner_id)';
      const colsBase = 'id, name, description, price, promo_price, images, '
          'created_at, available, store_id, '
          'category, subcategory, sold_count, rating, reviews_count, '
          'stores(id, store_name, logo_url, rating, reviews_count, '
          'followers_count, is_verified, owner_id)';

      Future<List<dynamic>> query(String cols) => followedIds.isNotEmpty
          ? client.from('products').select(cols).eq('available', true)
              .inFilter('store_id', followedIds)
              .order('created_at', ascending: false).limit(40)
          : client.from('products').select(cols).eq('available', true)
              .order('created_at', ascending: false).limit(40);

      // Try full columns; fall back to base if extended columns not yet migrated
      List<dynamic> rows;
      try {
        rows = await query(colsFull);
      } catch (_) {
        rows = await query(colsBase);
      }

      final list = List<Map<String, dynamic>>.from(rows);
      AppCache.instance.set(AppCache.kFeedProducts, list);
      if (mounted) setState(() { _feedProducts = list; _feedLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _feedLoading = false);
    }
  }

  void _subscribeToCampaigns() {
    try {
      _campaignsSubscription = Supabase.instance.client
          .from('ad_campaigns')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> rows) {
            final today = DateTime.now().toIso8601String().split('T').first;
            final list = rows.map((r) => AdCampaign.fromMap(r)).where((c) {
              if (c.status != AdStatus.active) return false;
              if (c.approvalStatus != AdApprovalStatus.approved) return false;

              final startStr = c.startDate?.toIso8601String().split('T').first;
              final endStr = c.endDate?.toIso8601String().split('T').first;

              return (startStr == null || startStr.compareTo(today) <= 0) &&
                     (endStr == null || endStr.compareTo(today) >= 0);
            }).toList();
            
            if (mounted) {
              setState(() {
                _liveCampaigns = list;
              });
            }
          });
    } catch (_) {
      // silently fall back
    }
  }

  @override
  void initState() {
    super.initState();
    _subscribeToCampaigns();
    _loadStores();
    _loadFeedProducts();
    _adTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_adCtrl.hasClients) return;
      final user = UserSession.instance.current;
      final isPro = user.proRole == ProRole.company;
      final baseCount = _liveCampaigns.isNotEmpty
          ? _liveCampaigns.length
          : _adSlides.length;
      final count = isPro ? baseCount + 1 : baseCount;
      final next = (_adPage + 1) % count;
      _adCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileSetup());
  }

  void _checkProfileSetup() {
    final user = UserSession.instance.current;
    if (user.isGuest) return;
    if (user.proRole == ProRole.none) {
      _showProfileSetup();
    }
  }

  void _showProfileSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ProfileSetupSheet(
        onRoleSelected: (role) async {
          Navigator.pop(context);
          await UserSession.instance.selectProRole(role);
          if (!mounted) return;
          final route = switch (role) {
            ProRole.seller  => '/complete-seller',
            ProRole.creator => '/complete-creator',
            _               => '/complete-buyer',
          };
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }

  @override
  void dispose() {
    _campaignsSubscription?.cancel();
    _adTimer?.cancel();
    _adCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                const SizedBox(height: 14),
                _buildStories(),
                const SizedBox(height: 16),
                _buildAdCarousel(),
                const SizedBox(height: 20),
                // ── Feed produits des boutiques suivies ──────────────────
                if (_feedLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2),
                    ),
                  )
                else if (_feedProducts.isNotEmpty) ...[
                  _buildSectionHeader('Nouveautés des boutiques'),
                  const SizedBox(height: 8),
                  ..._feedProducts.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _RealFeedProductCard(product: p),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(children: [
                      const Icon(Icons.storefront_outlined,
                          size: 52, color: AppColors.lightGray),
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
                ],
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: NavTab.feed),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour 👋',
              style: GoogleFonts.montserrat(
                  color: AppColors.grayLight, fontSize: 11,
                  fontWeight: FontWeight.w500)),
          Text('Bienvenue sur Lincoo',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ]),
        const Spacer(),
        _headerBtn(Icons.card_giftcard_outlined,
            onTap: () => Navigator.pushNamed(context, '/rewards')),
        const SizedBox(width: 6),
        _headerBtn(Icons.shopping_bag_outlined,
            onTap: () => Navigator.pushNamed(context, '/cart')),
        const SizedBox(width: 6),
        _headerBtn(Icons.notifications_outlined,
            onTap: () => Navigator.pushNamed(context, '/notifications')),
      ]),
    );
  }

  Widget _headerBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: AppColors.nearBlack),
        ),
      );

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(title,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        if (onMore != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onMore,
            child: Text('Voir tout',
                style: GoogleFonts.montserrat(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  // ── Stories ───────────────────────────────────────────────────────────────

  Widget _buildStories() {
    // Boutiques réelles depuis Supabase (mêmes données que _buildRecommendedStores),
    // fallback sur une liste de secours si rien n'est encore chargé.
    const fallbackStores = [
      _StoreCardData('Djezzy App',   '', Color(0xFFE31E1E), 'D'),
      _StoreCardData('Loolet store', '', Color(0xFF121111), 'LO'),
      _StoreCardData('Minyas cos',   '', Color(0xFF7B1FA2), 'M'),
      _StoreCardData('Baby powder',  '', Color(0xFF1976D2), 'B'),
      _StoreCardData('minas_sec',    '', Color(0xFF388E3C), 'mi'),
      _StoreCardData('femmedz',      '', Color(0xFF8B2635), 'F'),
      _StoreCardData('Nadia.style',  '', Color(0xFF7B1FA2), 'N'),
    ];
    final stores = _liveStores.isNotEmpty ? _liveStores : fallbackStores;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: stores.length,
          itemBuilder: (_, i) => _storyItem(stores[i]),
        ),
      ),
    );
  }

  Widget _storyItem(_StoreCardData s) {
    final hasLogo = s.logoUrl != null && s.logoUrl!.startsWith('http');
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/store',
          arguments: s.storeId != null ? {'storeId': s.storeId} : null),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 66, height: 66,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
          ),
          child: Container(
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: s.color,
              backgroundImage: hasLogo ? NetworkImage(s.logoUrl!) : null,
              child: hasLogo
                  ? null
                  : Text(s.initials,
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 66,
          child: Text(s.name,
              style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.nearBlack),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ── Ad Carousel ───────────────────────────────────────────────────────────

  List<Color> _resolveAdColors(String? imageUrl) {
    if (imageUrl == 'gradient:neon') return [const Color(0xFFB06AFF), const Color(0xFF8B5CF6)];
    if (imageUrl == 'gradient:crimson') return [const Color(0xFF292526), const Color(0xFF6E1128)];
    if (imageUrl == 'gradient:purple') return [const Color(0xFF8A2BE2), const Color(0xFF4B0082)];
    if (imageUrl == 'gradient:orange') return [const Color(0xFFFF512F), const Color(0xFFDD2476)];
    return [const Color(0xFF292526), const Color(0xFF6E1128)];
  }

  Widget _buildAdPublishPromoSlide() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/quick-ad-publish'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.nearBlack, Color(0xFF1E004F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OFFRE PARTENAIRE',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Boostez vos Ventes !',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Publiez votre publicité ici à partir de 800 DA la journée.',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white10,
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publier',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(int i, int baseCount, bool isPro) {
    if (isPro && i == baseCount) {
      return _buildAdPublishPromoSlide();
    }
    if (_liveCampaigns.isNotEmpty) {
      return _campaignSlide(_liveCampaigns[i]);
    } else {
      return _mockSlide(_adSlides[i]);
    }
  }

  // ── Ad Carousel ───────────────────────────────────────────────────────────

  Widget _buildAdCarousel() {
    final user = UserSession.instance.current;
    final isPro = user.proRole == ProRole.seller || user.proRole == ProRole.company;
    
    final baseCount = _liveCampaigns.isNotEmpty
        ? _liveCampaigns.length
        : _adSlides.length;
        
    final count = isPro ? baseCount + 1 : baseCount;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _adCtrl,
                onPageChanged: (i) => setState(() => _adPage = i),
                itemCount: count,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSlideContent(i, baseCount, isPro),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == _adPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.lightGray,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    ]);
  }

  Widget _mockSlide(_AdSlide s) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: s.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Stack(children: [
            Positioned(
              right: -30, top: -30,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            Positioned(
              left: -20, bottom: -40,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
          ]),
        ),
      );

  Widget _campaignSlide(AdCampaign c) {
    final previewColors = _resolveAdColors(c.imageUrl);
    final hasRealImage = c.imageUrl != null && !c.imageUrl!.startsWith('gradient:');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context, '/company-page',
        arguments: c.companyId,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: !hasRealImage
                ? LinearGradient(
                    colors: previewColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Stack(
            children: [
              if (hasRealImage)
                Positioned.fill(
                  child: Image.network(
                    c.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.dark,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Shared image carousel
// ─────────────────────────────────────────────────────────────────────────────

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  const _ImageCarousel({required this.imageUrls, required this.height});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _page = 0;
  final PageController _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _prev() {
    if (_page > 0) {
      _ctrl.previousPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    }
  }

  void _next() {
    if (_page < widget.imageUrls.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    }
  }

  Widget _buildImage(String url) {
    final placeholder = Container(
      height: widget.height,
      color: AppColors.surfaceAlt,
      child: const Icon(Icons.image_outlined,
          color: AppColors.lightGray, size: 40),
    );
    if (url.startsWith('http')) {
      return Image.network(url,
          width: double.infinity, height: widget.height, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder);
    }
    return Image.asset(url,
        width: double.infinity, height: widget.height, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    return Stack(children: [
      SizedBox(
        height: widget.height,
        child: PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: total,
          itemBuilder: (_, i) => _buildImage(widget.imageUrls[i]),
        ),
      ),
      // Left arrow
      if (total > 1 && _page > 0)
        Positioned(
          left: 8, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _prev,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      // Right arrow
      if (total > 1 && _page < total - 1)
        Positioned(
          right: 8, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _next,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      // Page indicator dots
      if (total > 1)
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width:  i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ),
    ]);
  }
}

// ── Post options sheet ────────────────────────────────────────────────────────

void _showPostOptions(BuildContext context, {bool hasProduct = false}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2))),
        if (hasProduct)
          _sheetTile(Icons.star_border_rounded, 'Noter le produit',
              const Color(0xFFFFC107), () {
            Navigator.pop(context);
            _showRatingDialog(context);
          }),
        _sheetTile(Icons.flag_outlined, 'Signaler ce post', AppColors.error,
            () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Signalement envoyé. Merci !'),
              behavior: SnackBarBehavior.floating));
        }),
        _sheetTile(Icons.close_rounded, 'Annuler', AppColors.gray,
            () => Navigator.pop(context)),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

Widget _sheetTile(
    IconData icon, String label, Color color, VoidCallback onTap) {
  return ListTile(
    leading: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, color: color, size: 18),
    ),
    title: Text(label,
        style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: label == 'Annuler' ? AppColors.gray : AppColors.nearBlack)),
    onTap: onTap,
  );
}

void _showRatingDialog(BuildContext context) {
  int stars = 0;
  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Noter le produit',
            style: GoogleFonts.montserrat(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => GestureDetector(
              onTap: () => setSt(() => stars = i + 1),
              child: Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
                size: 36,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nearBlack,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Merci ! Vous avez donné $stars ★'),
                  behavior: SnackBarBehavior.floating));
            },
            child: Text('Soumettre',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated "Ajouter au panier" button — press feedback + success bounce
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCartButton extends StatefulWidget {
  final bool inCart;
  final VoidCallback onTap;
  const _AnimatedCartButton({required this.inCart, required this.onTap});

  @override
  State<_AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<_AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant _AnimatedCartButton old) {
    super.didUpdateWidget(old);
    if (widget.inCart && !old.inCart) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounceScale = Tween(begin: 1.0, end: 1.18)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_bounce);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.inCart
                  ? const [Color(0xFF2ECC71), Color(0xFF27AE60)]
                  : const [AppColors.accent, AppColors.blue],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (widget.inCart ? const Color(0xFF27AE60) : AppColors.blue)
                    .withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: bounceScale,
              builder: (context, child) => Transform.scale(
                scale: widget.inCart ? bounceScale.value : 1.0,
                child: child,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child)),
                child: Icon(
                  widget.inCart
                      ? Icons.check_circle_rounded
                      : Icons.shopping_bag_outlined,
                  key: ValueKey(widget.inCart),
                  size: 15,
                  color: AppColors.nearBlack,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.inCart ? 'Voir le panier' : 'Ajouter au panier',
                key: ValueKey(widget.inCart),
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real Feed Product Card (from Supabase)
// ─────────────────────────────────────────────────────────────────────────────

class _RealFeedProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  const _RealFeedProductCard({required this.product});
  @override
  State<_RealFeedProductCard> createState() => _RealFeedProductCardState();
}

class _RealFeedProductCardState extends State<_RealFeedProductCard> {
  bool   _isLiked  = false;
  bool   _isSaved  = false;
  late bool _inCart;
  late int  _likes;
  int   _comments  = 0;
  String    _pid   = '';

  @override
  void initState() {
    super.initState();
    final raw = widget.product['likes_count'];
    _likes = raw is int ? raw : 0;
    final id = widget.product['id'];
    _inCart  = id is String && CartService.instance.contains(id);
    _pid     = id is String ? id : '';
    _isLiked = LikesService.instance.isLiked(_pid);
    _isSaved = WishlistService.instance.contains(_pid);
    LikesService.instance.ensureLoaded();
    WishlistService.instance.ensureLoaded();
    LikesService.instance.likedIds.addListener(_onLikesChanged);
    WishlistService.instance.ids.addListener(_onWishlistChanged);
  }

  @override
  void dispose() {
    LikesService.instance.likedIds.removeListener(_onLikesChanged);
    WishlistService.instance.ids.removeListener(_onWishlistChanged);
    super.dispose();
  }

  void _onLikesChanged() {
    if (!mounted) return;
    setState(() => _isLiked = LikesService.instance.isLiked(_pid));
  }

  void _onWishlistChanged() {
    if (!mounted) return;
    setState(() => _isSaved = WishlistService.instance.contains(_pid));
  }

  Map<String, dynamic> get p => widget.product;

  // Safe accessor — handles JS undefined (Flutter Web quirk)
  static T? _safe<T>(dynamic v) => v is T ? v : null;

  Map<String, dynamic>? get _storeMap {
    final raw = p['stores'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  String   get _storeName => _safe<String>(_storeMap?['store_name']) ?? '';
  String?  get _storeId   => _safe<String>(_storeMap?['id']);
  String?  get _logoUrl   => _safe<String>(_storeMap?['logo_url']);

  List<String> get _images {
    final raw = p['images'];
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }

  double   get _price  => (_safe<num>(p['price'])       ?? 0).toDouble();
  double?  get _promo  => _safe<num>(p['promo_price'])?.toDouble();
  String   get _name   => _safe<String>(p['name'])        ?? '';
  String?  get _desc   => _safe<String>(p['description']);
  String?  get _tag    => _safe<String>(p['offer_tag']);

  String get _timeAgo {
    try {
      final raw = p['created_at'];
      if (raw is! String) return '';
      final dt = DateTime.parse(raw);
      final d  = DateTime.now().difference(dt);
      if (d.inMinutes < 60)  return 'Il y a ${d.inMinutes}min';
      if (d.inHours   < 24)  return 'Il y a ${d.inHours}h';
      if (d.inDays    < 30)  return 'Il y a ${d.inDays}j';
      return 'Il y a ${(d.inDays / 30).floor()}mois';
    } catch (_) { return ''; }
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    return s.length > 3
        ? '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}'
        : s;
  }

  @override
  Widget build(BuildContext context) {
    final initials = _storeName.length >= 2
        ? _storeName.substring(0, 2).toUpperCase()
        : _storeName.toUpperCase();
    final colors = [
      const Color(0xFF121111), const Color(0xFF7B1FA2),
      const Color(0xFF1976D2), const Color(0xFF8B2635),
    ];
    final color = _storeName.isNotEmpty
        ? colors[_storeName.codeUnitAt(0) % colors.length]
        : colors[0];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            GestureDetector(
              onTap: _storeId != null
                  ? () => Navigator.pushNamed(context, '/store',
                      arguments: {'storeId': _storeId})
                  : null,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: color,
                backgroundImage: _logoUrl != null && _logoUrl!.startsWith('http')
                    ? NetworkImage(_logoUrl!) as ImageProvider
                    : null,
                child: (_logoUrl == null || !_logoUrl!.startsWith('http'))
                    ? Text(initials,
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11))
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                GestureDetector(
                  onTap: _storeId != null
                      ? () => Navigator.pushNamed(context, '/store',
                          arguments: {'storeId': _storeId})
                      : null,
                  child: Text(_storeName,
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.nearBlack)),
                ),
                if (_timeAgo.isNotEmpty)
                  Text(_timeAgo,
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: AppColors.gray)),
              ]),
            ),
            if (_tag != null)
              Text(_tag!,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue)),
          ]),
        ),

        // ── Images ──────────────────────────────────────────────────────
        if (_images.isNotEmpty)
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/product',
                arguments: widget.product),
            child: _ImageCarousel(imageUrls: _images, height: 380),
          )
        else
          Container(
            height: 240,
            color: AppColors.bgGray,
            child: const Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.lightGray, size: 48)),
          ),

        // ── Actions ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(children: [
            // Like + count réel
            GestureDetector(
              onTap: () {
                setState(() {
                  _isLiked = !_isLiked;
                  _likes  += _isLiked ? 1 : -1;
                });
                LikesService.instance.toggle(_pid);
              },
              child: Row(children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : AppColors.nearBlack,
                  size: 26,
                ),
                const SizedBox(width: 5),
                Text(
                  _likes >= 1000
                      ? '${(_likes / 1000).toStringAsFixed(1)}K'
                      : '$_likes',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.nearBlack),
                ),
              ]),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                setState(() => _isSaved = !_isSaved);
                WishlistService.instance.toggle(_pid, widget.product);
              },
              child: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? AppColors.accent : AppColors.nearBlack,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () => showCommentSheet(
                context,
                postId: _pid,
                onCountChanged: (n) => setState(() => _comments = n),
              ),
              child: Row(children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppColors.nearBlack, size: 22),
                if (_comments > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    _comments >= 1000
                        ? '${(_comments / 1000).toStringAsFixed(1)}K'
                        : '$_comments',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.nearBlack),
                  ),
                ],
              ]),
            ),
            const Spacer(),
            // Ajouter / Voir panier
            _AnimatedCartButton(
              inCart: _inCart,
              onTap: () {
                if (_inCart) {
                  Navigator.pushNamed(context, '/cart');
                } else {
                  HapticFeedback.lightImpact();
                  CartService.instance.addProduct(widget.product);
                  setState(() => _inCart = true);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$_name ajouté au panier',
                        style: GoogleFonts.montserrat(fontSize: 13)),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                    backgroundColor: AppColors.nearBlack,
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
            ),
          ]),
        ),

        // ── Product info ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/product',
                  arguments: widget.product),
              child: Text(_name,
                  style: GoogleFonts.montserrat(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack)),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text('${_fmt(_promo ?? _price)} DA',
                  style: GoogleFonts.montserrat(
                      fontSize: 15, fontWeight: FontWeight.w900,
                      color: _promo != null ? Colors.red : AppColors.nearBlack)),
              if (_promo != null) ...[
                const SizedBox(width: 8),
                Text('${_fmt(_price)} DA',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: AppColors.gray,
                        decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      '−${((1 - _promo! / _price) * 100).round()}%',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, fontWeight: FontWeight.w800,
                          color: Colors.red)),
                ),
              ],
            ]),
            if (_desc != null && _desc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_desc!,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.gray, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Product Post Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductPostCard extends StatefulWidget {
  final String storeName;
  final Color storeColor;
  final String storeInitials;
  final String timeAgo;
  final List<String> imageUrls;
  final double imageHeight;
  final String productName;
  final String productDesc;
  final int price;
  final int originalPrice;
  final double rating;
  final int initialLikes;

  const _ProductPostCard({
    required this.storeName,
    required this.storeColor,
    required this.storeInitials,
    required this.timeAgo,
    required this.imageUrls,
    required this.imageHeight,
    required this.productName,
    required this.productDesc,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.initialLikes,
  });

  @override
  State<_ProductPostCard> createState() => _ProductPostCardState();
}

class _ProductPostCardState extends State<_ProductPostCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _inCart = false;
  bool _isFollowing = false;
  late int _likes;

  late final AnimationController _likeCtrl;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  String get _likesLabel =>
      _likes >= 1000 ? '${(_likes / 1000).toStringAsFixed(1)}K' : '$_likes';

  void _onLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
    if (_isLiked) {
      HapticFeedback.lightImpact();
      _likeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.hardEdge,
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(context),
        _ImageCarousel(
            imageUrls: widget.imageUrls, height: widget.imageHeight),
        _buildActions(context),
        _buildProductInfo(context),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/store'),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: widget.storeColor,
              child: Text(widget.storeInitials,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.storeName,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                  Text(widget.timeAgo,
                      style: GoogleFonts.montserrat(
                          color: AppColors.grayLight, fontSize: 10)),
                ]),
          ),
          _FollowChip(
            isFollowing: _isFollowing,
            onToggle: () {
              HapticFeedback.lightImpact();
              setState(() => _isFollowing = !_isFollowing);
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showPostOptions(context, hasProduct: true),
            child: const Icon(Icons.more_vert,
                size: 20, color: AppColors.grayLight),
          ),
        ]),
      );

  Widget _buildActions(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Row(children: [
          // Like
          GestureDetector(
            onTap: _onLike,
            child: ScaleTransition(
              scale: _likeScale,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isLiked ? Icons.favorite_rounded : Icons.favorite_border,
                  key: ValueKey(_isLiked),
                  color: _isLiked
                      ? const Color(0xFFE53935)
                      : AppColors.grayLight,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(_likesLabel,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          // Share
          _ActionBtn(
            icon: Icons.share_outlined,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Lien copié !'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating)),
          ),
          const SizedBox(width: 14),
          // Save
          GestureDetector(
            onTap: () {
              setState(() => _isSaved = !_isSaved);
              if (_isSaved) HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      _isSaved ? 'Sauvegardé !' : 'Retiré des favoris'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating));
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
                key: ValueKey(_isSaved),
                size: 24,
                color: _isSaved ? AppColors.nearBlack : AppColors.grayLight,
              ),
            ),
          ),
        ]),
      );

  Widget _buildProductInfo(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/product',
                  arguments: {
                    'name': widget.productName,
                    'price': widget.price,
                    'promo_price': widget.originalPrice > widget.price ? widget.price : null,
                    'images': widget.imageUrls,
                    'description': widget.productDesc,
                    'rating': widget.rating,
                    'stores': {'store_name': widget.storeName},
                  }),
                child: Text(widget.productName,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            _CartChip(
              inCart: _inCart,
              onToggle: () {
                setState(() => _inCart = !_inCart);
                if (_inCart) HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      _inCart ? 'Ajouté au panier !' : 'Retiré du panier'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  action: _inCart
                      ? SnackBarAction(
                          label: 'Voir',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/cart'))
                      : null,
                ));
              },
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('${widget.price} DA',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text('${widget.originalPrice} DA',
                style: GoogleFonts.montserrat(
                    color: AppColors.grayLight,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.grayLight)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.gold, size: 12),
                const SizedBox(width: 2),
                Text('${widget.rating}',
                    style: GoogleFonts.montserrat(
                        color: const Color(0xFFE65100),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/product', arguments: {
                'name': widget.productName,
                'price': widget.price,
                'promo_price': widget.originalPrice > widget.price ? widget.price : null,
                'images': widget.imageUrls,
                'description': widget.productDesc,
                'rating': widget.rating,
                'stores': {'store_name': widget.storeName},
              }),
            child: Text('${widget.productDesc} → voir détails',
                style: GoogleFonts.montserrat(
                    color: AppColors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Creator Post Card
// ─────────────────────────────────────────────────────────────────────────────

class _CreatorPostCard extends StatefulWidget {
  final String creatorName;
  final Color creatorColor;
  final String creatorInitials;
  final String timeAgo;
  final List<String> imageUrls;
  final double imageHeight;
  final String caption;
  final int initialLikes;

  const _CreatorPostCard({
    required this.creatorName,
    required this.creatorColor,
    required this.creatorInitials,
    required this.timeAgo,
    required this.imageUrls,
    required this.imageHeight,
    required this.caption,
    required this.initialLikes,
  });

  @override
  State<_CreatorPostCard> createState() => _CreatorPostCardState();
}

class _CreatorPostCardState extends State<_CreatorPostCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _captionExpanded = false;
  bool _isFollowing = false;
  late int _likes;

  late final AnimationController _likeCtrl;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  String get _likesLabel =>
      _likes >= 1000 ? '${(_likes / 1000).toStringAsFixed(1)}K' : '$_likes';

  void _onLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
    if (_isLiked) {
      HapticFeedback.lightImpact();
      _likeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.hardEdge,
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: widget.creatorColor,
              child: Text(widget.creatorInitials,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(widget.creatorName,
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.creatorColor
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Créateur',
                            style: GoogleFonts.montserrat(
                                color: widget.creatorColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    Text(widget.timeAgo,
                        style: GoogleFonts.montserrat(
                            color: AppColors.grayLight, fontSize: 10)),
                  ]),
            ),
            _FollowChip(
              isFollowing: _isFollowing,
              onToggle: () {
                HapticFeedback.lightImpact();
                setState(() => _isFollowing = !_isFollowing);
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showPostOptions(context),
              child: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.grayLight),
            ),
          ]),
        ),
        // Image
        _ImageCarousel(
            imageUrls: widget.imageUrls, height: widget.imageHeight),
        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(children: [
            GestureDetector(
              onTap: _onLike,
              child: ScaleTransition(
                scale: _likeScale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border,
                    key: ValueKey(_isLiked),
                    color: _isLiked
                        ? const Color(0xFFE53935)
                        : AppColors.grayLight,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(_likesLabel,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            _ActionBtn(
              icon: Icons.chat_bubble_outline,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => const _CommentSheet(),
              ),
            ),
            const Spacer(),
            _ActionBtn(
              icon: Icons.share_outlined,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lien copié !'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating)),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                setState(() => _isSaved = !_isSaved);
                if (_isSaved) HapticFeedback.lightImpact();
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border,
                  key: ValueKey(_isSaved),
                  size: 24,
                  color: _isSaved ? AppColors.nearBlack : AppColors.grayLight,
                ),
              ),
            ),
          ]),
        ),
        // Caption
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _captionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(widget.caption,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      height: 1.6),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              secondChild: Text(widget.caption,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      height: 1.6)),
            ),
            if (!_captionExpanded)
              GestureDetector(
                onTap: () =>
                    setState(() => _captionExpanded = true),
                child: Text('voir plus...',
                    style: GoogleFonts.montserrat(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Collab Post Card
// ─────────────────────────────────────────────────────────────────────────────

class _CollabPostCard extends StatefulWidget {
  final String storeName;
  final Color storeColor;
  final String storeInitials;
  final String creatorName;
  final Color creatorColor;
  final String creatorInitials;
  final String timeAgo;
  final List<String> imageUrls;
  final double imageHeight;
  final String productName;
  final int price;
  final int originalPrice;
  final double rating;
  final String caption;
  final int initialLikes;

  const _CollabPostCard({
    required this.storeName,
    required this.storeColor,
    required this.storeInitials,
    required this.creatorName,
    required this.creatorColor,
    required this.creatorInitials,
    required this.timeAgo,
    required this.imageUrls,
    required this.imageHeight,
    required this.productName,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.caption,
    required this.initialLikes,
  });

  @override
  State<_CollabPostCard> createState() => _CollabPostCardState();
}

class _CollabPostCardState extends State<_CollabPostCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _inCart = false;
  bool _isFollowing = false;
  late int _likes;

  late final AnimationController _likeCtrl;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  String get _likesLabel =>
      _likes >= 1000 ? '${(_likes / 1000).toStringAsFixed(1)}K' : '$_likes';

  void _onLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
    if (_isLiked) {
      HapticFeedback.lightImpact();
      _likeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.hardEdge,
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Collab header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            SizedBox(
              width: 50, height: 38,
              child: Stack(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: widget.storeColor,
                  child: Text(widget.storeInitials,
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10)),
                ),
                Positioned(
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: widget.creatorColor,
                      child: Text(widget.creatorInitials,
                          style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(widget.storeName,
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                      Text(' × ',
                          style: GoogleFonts.montserrat(
                              color: AppColors.grayLight, fontSize: 12)),
                      Text(widget.creatorName,
                          style: GoogleFonts.montserrat(
                              color: widget.creatorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ]),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED)
                              .withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Collab',
                            style: GoogleFonts.montserrat(
                                color: AppColors.blue,
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 6),
                      Text(widget.timeAgo,
                          style: GoogleFonts.montserrat(
                              color: AppColors.grayLight, fontSize: 10)),
                    ]),
                  ]),
            ),
            _FollowChip(
              isFollowing: _isFollowing,
              onToggle: () {
                HapticFeedback.lightImpact();
                setState(() => _isFollowing = !_isFollowing);
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showPostOptions(context, hasProduct: true),
              child: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.grayLight),
            ),
          ]),
        ),
        _ImageCarousel(
            imageUrls: widget.imageUrls, height: widget.imageHeight),
        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(children: [
            GestureDetector(
              onTap: _onLike,
              child: ScaleTransition(
                scale: _likeScale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border,
                    key: ValueKey(_isLiked),
                    color: _isLiked
                        ? const Color(0xFFE53935)
                        : AppColors.grayLight,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(_likesLabel,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            _ActionBtn(
              icon: Icons.chat_bubble_outline,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => const _CommentSheet(),
              ),
            ),
            const Spacer(),
            _ActionBtn(
              icon: Icons.share_outlined,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lien copié !'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating)),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                setState(() => _isSaved = !_isSaved);
                if (_isSaved) HapticFeedback.lightImpact();
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border,
                  key: ValueKey(_isSaved),
                  size: 24,
                  color: _isSaved ? AppColors.nearBlack : AppColors.grayLight,
                ),
              ),
            ),
          ]),
        ),
        // Caption + product
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.caption,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 13, height: 1.55),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/product', arguments: {
                    'name': widget.productName,
                    'price': widget.price,
                    'promo_price': widget.originalPrice > widget.price ? widget.price : null,
                    'images': widget.imageUrls,
                    'rating': widget.rating,
                    'stores': {'store_name': widget.storeName},
                  }),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.productName,
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text('${widget.price} DA',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.nearBlack,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Text('${widget.originalPrice} DA',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.grayLight,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.grayLight)),
                        ]),
                      ]),
                ),
              ),
              _CartChip(
                inCart: _inCart,
                onToggle: () {
                  setState(() => _inCart = !_inCart);
                  if (_inCart) HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        _inCart ? 'Ajouté au panier !' : 'Retiré du panier'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    action: _inCart
                        ? SnackBarAction(
                            label: 'Voir',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/cart'))
                        : null,
                  ));
                },
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FollowChip extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onToggle;
  const _FollowChip({required this.isFollowing, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.nearBlack : Colors.white,
          border: Border.all(
              color: isFollowing ? AppColors.nearBlack : AppColors.lightGray),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(isFollowing ? 'Suivi' : 'Suivre',
            style: GoogleFonts.montserrat(
                color: isFollowing ? Colors.white : AppColors.nearBlack,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CartChip extends StatelessWidget {
  final bool inCart;
  final VoidCallback onToggle;
  const _CartChip({required this.inCart, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: inCart
              ? null
              : const LinearGradient(
                  colors: [AppColors.nearBlack, AppColors.dark]),
          color: inCart ? const Color(0xFF6E1128) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            inCart
                ? Icons.check_circle_outline
                : Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(inCart ? 'Ajouté ✓' : 'Au panier',
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 22, color: AppColors.grayLight),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CommentSheet extends StatelessWidget {
  const _CommentSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2))),
        Text('Commentaires',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        const Icon(Icons.chat_bubble_outline,
            size: 44, color: AppColors.lightGray),
        const SizedBox(height: 10),
        Text('Aucun commentaire pour l\'instant.',
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 13)),
        const SizedBox(height: 4),
        Text('Soyez le premier à commenter !',
            style: GoogleFonts.montserrat(
                color: AppColors.grayLight, fontSize: 12)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Écrire un commentaire...',
              hintStyle: GoogleFonts.montserrat(
                  color: AppColors.grayLight, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              suffixIcon: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.blue]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded,
                    color: AppColors.nearBlack, size: 18),
              ),
            ),
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile setup bottom sheet — shown when pro_role == 'none'
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSetupSheet extends StatelessWidget {
  final Future<void> Function(ProRole) onRoleSelected;
  const _ProfileSetupSheet({required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.blue]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        Text('Complétez votre profil',
            style: GoogleFonts.montserrat(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: AppColors.nearBlack, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text('Comment allez-vous utiliser Lincoo ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: AppColors.gray, height: 1.5)),
        const SizedBox(height: 28),
        _roleCard(
          context,
          role: ProRole.buyer,
          icon: Icons.shopping_bag_outlined,
          label: 'Acheteur',
          subtitle: 'Je découvre et achète des produits',
          gradientColors: [AppColors.deepPurple, AppColors.blue],
          iconColor: AppColors.blue,
        ),
        const SizedBox(height: 12),
        _roleCard(
          context,
          role: ProRole.seller,
          icon: Icons.storefront_outlined,
          label: 'Vendeur',
          subtitle: 'Je vends mes produits sur Lincoo',
          gradientColors: [AppColors.accent, AppColors.blue],
          iconColor: AppColors.accent,
        ),
        const SizedBox(height: 12),
        _roleCard(
          context,
          role: ProRole.creator,
          icon: Icons.movie_creation_outlined,
          label: 'Créateur de contenu',
          subtitle: 'Je crée du contenu et inspire ma communauté',
          gradientColors: [AppColors.purple, const Color(0xFF7B1FA2)],
          iconColor: AppColors.purple,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Plus tard',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required ProRole role,
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () => onRoleSelected(role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.04),
          border: Border.all(color: iconColor.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: iconColor.withValues(alpha: 0.06),
                blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.gray, height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: iconColor.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}
