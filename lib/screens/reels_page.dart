import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../main.dart' show routeObserver;
import '../widgets/app_bottom_nav.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/web_video_player_stub.dart'
    if (dart.library.html) '../widgets/web_video_player_web.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage>
    with RouteAware {
  List<Map<String, dynamic>> _reels = [];
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when a route on top of this one was popped (e.g. create page closed).
  @override
  void didPopNext() => _load();

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    const baseSelect = 'id, caption, media_urls, cover_url, product_id, '
        'likes_count, comments_count, views_count, created_at, '
        'stores(id, store_name, logo_url, is_verified), '
        'products(id, name, price, promo_price, images, description, '
        'category, subcategory, available, sold_count, rating, '
        'reviews_count, created_at, store_id, '
        'stores(id, store_name, logo_url, rating, reviews_count, '
        'followers_count, is_verified, owner_id))';

    const fullSelect = 'id, caption, media_urls, cover_url, product_id, '
        'likes_count, comments_count, views_count, created_at, '
        'stores(id, store_name, logo_url, is_verified), '
        'products(id, name, price, promo_price, images, description, '
        'category, subcategory, size_variants, color_variants, '
        'stock_qty, offer_tag, available, sold_count, rating, '
        'reviews_count, created_at, store_id, '
        'stores(id, store_name, logo_url, rating, reviews_count, '
        'followers_count, is_verified, owner_id))';

    try {
      List<dynamic> rows;
      try {
        rows = await Supabase.instance.client
            .from('store_posts')
            .select(fullSelect)
            .eq('post_type', 'reel')
            .order('created_at', ascending: false)
            .limit(30);
      } catch (_) {
        rows = await Supabase.instance.client
            .from('store_posts')
            .select(baseSelect)
            .eq('post_type', 'reel')
            .order('created_at', ascending: false)
            .limit(30);
      }

      if (mounted) {
        setState(() {
          _reels   = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        if (_loading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.montserrat(
                        color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Réessayer',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ]),
            ),
          )
        else if (_reels.isEmpty)
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const Icon(Icons.videocam_off_outlined,
                  color: Colors.white38, size: 52),
              const SizedBox(height: 12),
              Text('Aucun reel pour le moment',
                  style: GoogleFonts.montserrat(
                      color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _load,
                child: Text('Actualiser',
                    style: GoogleFonts.montserrat(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          )
        else
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            itemBuilder: (_, i) => _ReelItem(reel: _reels[i]),
          ),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Text('Reels',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 24),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create'),
                ),
              ]),
            ),
          ),
        ),

        // Bottom nav
        const Positioned(
          bottom: 0, left: 0, right: 0,
          child: AppBottomNav(activeTab: NavTab.reels),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single reel item
// ─────────────────────────────────────────────────────────────────────────────

class _ReelItem extends StatefulWidget {
  final Map<String, dynamic> reel;
  const _ReelItem({required this.reel});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  bool _liked    = false;
  bool _saved    = false;
  bool _likeLoading = false;
  late int _likes;
  late int _comments;

  static T? _s<T>(dynamic v) => v is T ? v : null;

  @override
  void initState() {
    super.initState();
    _likes    = _s<int>(widget.reel['likes_count'])    ?? 0;
    _comments = _s<int>(widget.reel['comments_count']) ?? 0;
    _loadLikedStatus();
  }

  Future<void> _loadLikedStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final reelId = widget.reel['id'] as String? ?? '';
    if (reelId.isEmpty) return;
    try {
      final rows = await Supabase.instance.client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', reelId)
          .eq('user_id', user.id)
          .limit(1);
      if (mounted) setState(() => _liked = (rows as List).isNotEmpty);
    } catch (_) {}
  }

  Map<String, dynamic>? get _store {
    final raw = widget.reel['stores'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    return null;
  }

  Map<String, dynamic>? get _product {
    final raw = widget.reel['products'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    return null;
  }

  String get _storeName => _s<String>(_store?['store_name']) ?? '';
  String? get _storeLogo => _s<String>(_store?['logo_url']);
  bool   get _verified   => _store?['is_verified'] == true;

  static bool _urlIsVideo(String url) {
    final u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp4') || u.endsWith('.webm') ||
           u.endsWith('.mov') || u.endsWith('.ogg') ||
           u.endsWith('.avi') || u.endsWith('.mkv');
  }

  // Returns the video URL if the reel has one, null otherwise.
  String? get _videoUrl {
    final media = widget.reel['media_urls'];
    if (media is List && media.isNotEmpty && media.first is String) {
      final url = media.first as String;
      if (_urlIsVideo(url)) return url;
    }
    return null;
  }

  // Returns a static image URL (cover or product thumb) for non-video reels.
  String? get _coverUrl {
    final cover = _s<String>(widget.reel['cover_url']);
    if (cover != null && cover.isNotEmpty && !_urlIsVideo(cover)) return cover;
    // first media_url that is an image
    final media = widget.reel['media_urls'];
    if (media is List && media.isNotEmpty && media.first is String) {
      final url = media.first as String;
      if (!_urlIsVideo(url)) return url;
    }
    // fallback: first product image
    final prod = _product;
    if (prod != null) {
      final imgs = prod['images'];
      if (imgs is List && imgs.isNotEmpty && imgs.first is String) {
        return imgs.first as String;
      }
    }
    return null;
  }

  // Store-specific gradient colors derived from store name hash
  Color get _bgColor {
    final colors = [
      const Color(0xFF1A1A2E), const Color(0xFF16213E),
      const Color(0xFF0F3460), const Color(0xFF1B1B2F),
      const Color(0xFF2C003E), const Color(0xFF1A0533),
      const Color(0xFF0D0D0D), const Color(0xFF1C1C2E),
    ];
    final idx = _storeName.isNotEmpty
        ? _storeName.codeUnitAt(0) % colors.length
        : 0;
    return colors[idx];
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _likeLoading) return;
    final reelId = widget.reel['id'] as String? ?? '';
    if (reelId.isEmpty) return;

    HapticFeedback.lightImpact();
    final wasLiked = _liked;
    setState(() {
      _likeLoading = true;
      _liked  = !wasLiked;
      _likes += _liked ? 1 : -1;
    });

    try {
      final client = Supabase.instance.client;
      if (!wasLiked) {
        await client.from('post_likes').insert(
            {'post_id': reelId, 'user_id': user.id});
      } else {
        await client.from('post_likes').delete()
            .eq('post_id', reelId)
            .eq('user_id', user.id);
      }
    } catch (_) {
      // Revert on error
      if (mounted) {
        setState(() {
          _liked  = wasLiked;
          _likes += wasLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = _s<String>(widget.reel['caption']) ?? '';
    final cover   = _coverUrl;
    final prod    = _product;
    final initials = _storeName.length >= 2
        ? _storeName.substring(0, 2).toUpperCase()
        : _storeName.toUpperCase();
    final reelId = widget.reel['id'] as String? ?? '';

    String fmtCount(int n) {
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
      return '$n';
    }

    final videoUrl = _videoUrl;

    return Stack(fit: StackFit.expand, children: [
      // Background — video or image
      if (videoUrl != null)
        _WebVideoPlayer(url: videoUrl)
      else if (cover != null)
        Image.network(cover,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _bgColor))
      else
        Container(color: _bgColor),

      // Dark gradient overlay
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.15),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.75),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),

      // Play indicator (center)
      if (cover == null)
        const Center(
          child: Icon(Icons.play_circle_outline,
              color: Colors.white24, size: 72),
        ),

      // Right action column
      Positioned(
        right: 12,
        bottom: 140,
        child: Column(children: [
          _ActionBtn(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            color: _liked ? Colors.red : Colors.white,
            count: fmtCount(_likes),
            onTap: _toggleLike,
          ),
          const SizedBox(height: 22),
          _ActionBtn(
            icon: Icons.mode_comment_outlined,
            count: fmtCount(_comments),
            onTap: () => showCommentSheet(
              context,
              postId: reelId,
              onCountChanged: (n) => setState(() => _comments = n),
            ),
          ),
          const SizedBox(height: 22),
          _ActionBtn(
            icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border,
            color: _saved ? AppColors.accent : Colors.white,
            onTap: () => setState(() => _saved = !_saved),
          ),
          const SizedBox(height: 22),
          _ActionBtn(
            icon: Icons.send_outlined,
            onTap: () {},
          ),
        ]),
      ),

      // Bottom info
      Positioned(
        left: 16,
        right: 80,
        bottom: 100,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Store row
          Row(children: [
            // Logo
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _storeLogo != null
                    ? Image.network(_storeLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsBox(initials))
                    : _initialsBox(initials),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(children: [
                Flexible(
                  child: Text(_storeName,
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (_verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded,
                      color: AppColors.blue, size: 14),
                ],
              ]),
            ),
          ]),

          // Caption
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(caption,
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],

          // Product badge
          if (prod != null) ...[
            const SizedBox(height: 12),
            _ProductBadge(product: prod),
          ],
        ]),
      ),
    ]);
  }

  Widget _initialsBox(String txt) => Container(
        color: AppColors.bgGray,
        child: Center(
          child: Text(txt,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProductBadge extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductBadge({required this.product});

  static T? _s<T>(dynamic v) => v is T ? v : null;

  @override
  Widget build(BuildContext context) {
    final name  = _s<String>(product['name']) ?? '';
    final price = (_s<num>(product['price'])  ?? 0).toDouble();
    final promo = _s<num>(product['promo_price'])?.toDouble();
    final display = promo ?? price;
    final fmt = display.toStringAsFixed(0);
    final fmtStr = fmt.length > 3
        ? '${fmt.substring(0, fmt.length - 3)} ${fmt.substring(fmt.length - 3)}'
        : fmt;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/product', arguments: product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white30),
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shopping_bag_outlined,
              color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name.isNotEmpty
                  ? '$name · $fmtStr DA'
                  : '$fmtStr DA',
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white70, size: 11),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Web video player — wraps an HTML <video> element via platformViewRegistry
// ─────────────────────────────────────────────────────────────────────────────

class _WebVideoPlayer extends StatelessWidget {
  final String url;
  const _WebVideoPlayer({required this.url});

  @override
  Widget build(BuildContext context) => buildWebVideoPlayer(url);
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String?  count;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    this.color = Colors.white,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Icon(icon, color: color, size: 30,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 8)]),
        if (count != null) ...[
          const SizedBox(height: 4),
          Text(count!,
              style: GoogleFonts.montserrat(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [const Shadow(color: Colors.black87, blurRadius: 6)])),
        ],
      ]),
    );
  }
}
