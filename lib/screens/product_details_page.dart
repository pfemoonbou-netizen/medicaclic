import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../models/store_model.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../services/likes_service.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // ── Route args ─────────────────────────────────────────────────────────────
  Map<String, dynamic>? _p;

  // ── State ──────────────────────────────────────────────────────────────────
  final _ctrl    = PageController();
  int    _page   = 0;
  int    _qty    = 1;
  bool   _saved  = false;
  bool   _inCart = false;
  bool   _descExpanded = false;

  String? _selSize;
  String? _selColorHex;
  String  _pid   = '';

  // ── Derived fields ─────────────────────────────────────────────────────────
  static T? _s<T>(dynamic v) => v is T ? v : null;

  List<String> get _images {
    final raw = _p?['images'];
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }

  String  get _name     => _s<String>(_p?['name'])        ?? '';
  String  get _desc     => _s<String>(_p?['description']) ?? '';
  String  get _category => _s<String>(_p?['category'])    ?? '';
  String  get _subcat   => _s<String>(_p?['subcategory']) ?? '';
  String? get _tag      => _s<String>(_p?['offer_tag']);
  double  get _price    => (_s<num>(_p?['price'])      ?? 0).toDouble();
  double? get _promo    => _s<num>(_p?['promo_price'])?.toDouble();
  double  get _unitPrice => _promo ?? _price;
  double  get _rating   => (_s<num>(_p?['rating'])     ?? 0).toDouble();
  int     get _reviews  => _s<int>(_p?['reviews_count']) ?? 0;
  int     get _sold     => _s<int>(_p?['sold_count'])    ?? 0;
  int?    get _stock    => _s<int>(_p?['stock_qty']);

  List<Map<String, dynamic>> _parseSizes(dynamic raw) {
    if (raw is List) {
      final variants = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final size = map['size'] ?? map['name'] ?? map['label'] ?? map['value'];
          final qty = map['qty'] ?? map['stock'] ?? map['quantity'] ?? map['available'] ?? 999;
          if (size != null || map.isNotEmpty) {
            variants.add({
              'size': size?.toString() ?? '',
              'qty': int.tryParse(qty.toString()) ?? 999,
            });
          }
        } else if (item is String && item.trim().isNotEmpty) {
          variants.add({'size': item.trim(), 'qty': 999});
        }
      }
      if (variants.isNotEmpty) return variants;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return map.entries.map((entry) {
        final qty = entry.value is num
            ? entry.value as num
            : int.tryParse(entry.value.toString()) ?? 999;
        return {'size': entry.key.toString(), 'qty': qty.toInt()};
      }).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _parseColors(dynamic raw) {
    if (raw is List) {
      final variants = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final name = map['name'] ?? map['label'] ?? map['color'] ?? '';
          final hex = map['hex'] ?? map['color'] ?? map['value'] ?? '';
          final qty = map['qty'] ?? map['stock'] ?? map['quantity'] ?? map['available'] ?? 999;
          if (name != '' || hex != '' || map.isNotEmpty) {
            variants.add({
              'name': name.toString(),
              'hex': _normalizeHex(hex.toString()),
              'qty': int.tryParse(qty.toString()) ?? 999,
            });
          }
        } else if (item is String && item.trim().isNotEmpty) {
          variants.add({'name': item.trim(), 'hex': _normalizeHex(item.trim()), 'qty': 999});
        }
      }
      if (variants.isNotEmpty) return variants;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return map.entries.map((entry) {
        final qty = entry.value is num
            ? entry.value as num
            : int.tryParse(entry.value.toString()) ?? 999;
        return {
          'name': entry.key.toString(),
          'hex': _normalizeHex(entry.key.toString()),
          'qty': qty.toInt(),
        };
      }).toList();
    }
    return [];
  }

  String _normalizeHex(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '#CCCCCC';
    if (!trimmed.startsWith('#')) {
      final colors = {
        'red': '#FF0000',
        'blue': '#3B82F6',
        'green': '#10B981',
        'black': '#111111',
        'white': '#FFFFFF',
        'yellow': '#FACC15',
        'pink': '#EC4899',
        'purple': '#8B5CF6',
        'orange': '#F97316',
        'gray': '#9CA3AF',
        'grey': '#9CA3AF',
      };
      return colors[trimmed.toLowerCase()] ?? '#CCCCCC';
    }
    return trimmed;
  }

  List<Map<String, dynamic>> get _sizes {
    final candidates = [
      _p?['size_variants'],
      _p?['sizes'],
      _p?['size_options'],
      _p?['sizeVariants'],
    ];
    for (final candidate in candidates) {
      final parsed = _parseSizes(candidate);
      if (parsed.isNotEmpty) return parsed;
    }
    return [];
  }

  List<Map<String, dynamic>> get _colors {
    final candidates = [
      _p?['color_variants'],
      _p?['colors'],
      _p?['color_options'],
      _p?['colorVariants'],
    ];
    for (final candidate in candidates) {
      final parsed = _parseColors(candidate);
      if (parsed.isNotEmpty) return parsed;
    }
    return [];
  }

  // Store data from joined `stores` object
  Map<String, dynamic>? get _store {
    final raw = _p?['stores'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    return null;
  }

  String  get _storeName     => _s<String>(_store?['store_name'])  ?? '';
  String? get _storeLogo     => _s<String>(_store?['logo_url']);
  double  get _storeRating   => (_s<num>(_store?['rating'])        ?? 0).toDouble();
  int     get _storeFollowers => _s<int>(_store?['followers_count']) ?? 0;
  bool    get _storeVerified  => _store?['is_verified'] == true;
  String? get _storeId       => _s<String>(_store?['id']);

  // ── Life-cycle ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _normalizeProductArgs(dynamic args) {
    if (args == null) return {};
    if (args is Map<String, dynamic>) return Map<String, dynamic>.from(args);
    if (args is Map) {
      return args.map((key, value) => MapEntry(key.toString(), value));
    }
    if (args is StoreProduct) {
      return {
        'id': args.id,
        'name': args.name,
        'description': 'Produit disponible dans cette boutique',
        'price': args.price,
        'promo_price': args.promoPrice,
        'images': args.images.isEmpty ? ['https://via.placeholder.com/400'] : args.images,
        'category': 'Mode',
        'rating': args.rating,
        'reviews_count': 12,
        'sold_count': args.soldCount,
        'stock_qty': args.available ? 10 : 0,
        'stores': {
          'id': args.storeId,
          'store_name': 'Boutique',
          'logo_url': null,
          'rating': 4.8,
          'followers_count': 1200,
          'is_verified': true,
        },
      };
    }
    return {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_p == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final normalized = _normalizeProductArgs(args);
      if (normalized.isNotEmpty) {
        _p = normalized;
        _pid = _s<String>(_p?['id']) ?? '';
        _inCart = CartService.instance.contains(_pid);
        _saved  = WishlistService.instance.contains(_pid);
        WishlistService.instance.ensureLoaded().then((_) {
          if (mounted) setState(() => _saved = WishlistService.instance.contains(_pid));
        });
        // Pre-select first available size
        final sv = _sizes;
        if (sv.isNotEmpty) {
          final first = sv.firstWhere(
              (v) => (_s<int>(v['qty']) ?? 999) > 0,
              orElse: () => sv.first);
          _selSize = _s<String>(first['size']);
        }
        // Pre-select first available color
        final cv = _colors;
        if (cv.isNotEmpty) {
          final first = cv.firstWhere(
              (v) => (_s<int>(v['qty']) ?? 999) > 0,
              orElse: () => cv.first);
          _selColorHex = _s<String>(first['hex']);
        }
        WishlistService.instance.ids.addListener(_onWishlistChanged);
        LikesService.instance.likedIds.addListener(_onLikesChanged);
      }
    }
  }

  void _onWishlistChanged() {
    if (mounted) setState(() => _saved = WishlistService.instance.contains(_pid));
  }

  void _onLikesChanged() { /* reserved for future likes display */ }

  @override
  void dispose() {
    WishlistService.instance.ids.removeListener(_onWishlistChanged);
    LikesService.instance.likedIds.removeListener(_onLikesChanged);
    _ctrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    return s.length > 3
        ? '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}'
        : s;
  }

  String _fmtFollowers(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_p == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F6FB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.nearBlack, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
            child: Text('Produit introuvable')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildImages(),
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            if (_sizes.isNotEmpty) ...[
              _buildSizes(),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
            if (_colors.isNotEmpty) ...[
              _buildColors(),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
            if (_desc.isNotEmpty) ...[
              _buildDescription(),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
            _buildStoreCard(),
            const SizedBox(height: 110),
          ]),
        ),
        // Overlay buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              _circleBtn(Icons.arrow_back_ios_new_rounded,
                  () => Navigator.pop(context)),
              Row(children: [
                _circleBtn(Icons.share_outlined, () {
                  Clipboard.setData(ClipboardData(
                      text: 'Découvre "$_name" sur Lincoo !'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Lien copié !'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1)));
                }),
                const SizedBox(width: 8),
                _circleBtn(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  () {
                    setState(() => _saved = !_saved);
                    if (_p != null) {
                      WishlistService.instance.toggle(_pid, _p!);
                    }
                  },
                  filled: _saved,
                ),
              ]),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Image carousel ─────────────────────────────────────────────────────────

  Widget _buildImages() {
    final imgs = _images;
    if (imgs.isEmpty) {
      return Container(
        height: 300,
        color: AppColors.bgGray,
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 64, color: AppColors.lightGray),
        ),
      );
    }

    return Stack(children: [
      SizedBox(
        height: 400,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: imgs.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final url = imgs[i];
            final img = url.startsWith('http')
                ? Image.network(url, fit: BoxFit.cover,
                    width: double.infinity, height: 400,
                    errorBuilder: (_, __, ___) => _imgFallback())
                : Image.asset(url, fit: BoxFit.cover,
                    width: double.infinity, height: 400,
                    errorBuilder: (_, __, ___) => _imgFallback());
            return GestureDetector(
              onTap: () => _openViewer(imgs, i),
              child: img,
            );
          },
        ),
      ),
      // Gradient
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x44000000)],
            ),
          ),
        ),
      ),
      // Badges
      if (_tag != null)
        Positioned(
          top: 60, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFF1D4ED8), size: 13),
              const SizedBox(width: 4),
              Text(_tag!,
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF1D4ED8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      if (_stock != null && _stock! <= 5 && _stock! > 0)
        Positioned(
          top: 60, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Plus que $_stock en stock',
                style: GoogleFonts.montserrat(
                    color: Colors.orange.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      // Thumbnails strip (right side)
      if (imgs.length > 1)
        Positioned(
          right: 12, top: 100,
          child: Column(
            children: List.generate(imgs.length, (i) {
              final active = i == _page;
              final url = imgs[i];
              return GestureDetector(
                onTap: () => _ctrl.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? AppColors.nearBlack : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: url.startsWith('http')
                        ? Image.network(url, fit: BoxFit.cover)
                        : Image.asset(url, fit: BoxFit.cover),
                  ),
                ),
              );
            }),
          ),
        ),
      // Dot indicators
      if (imgs.length > 1)
        Positioned(
          bottom: 14, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imgs.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ),
    ]);
  }

  Widget _imgFallback() => Container(
        color: AppColors.bgGray,
        child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.lightGray, size: 50),
        ),
      );

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hasPromo  = _promo != null && _promo! < _price;
    final discount  = hasPromo
        ? ((1 - _promo! / _price) * 100).round()
        : 0;
    final catLine   = [_category, _subcat]
        .where((s) => s.isNotEmpty).join(' · ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Category + discount badge
        Row(children: [
          if (catLine.isNotEmpty)
            Text(catLine,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray,
                    fontSize: 11,
                    letterSpacing: 0.5)),
          const Spacer(),
          if (hasPromo)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('−$discount%',
                  style: GoogleFonts.montserrat(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
        ]),
        const SizedBox(height: 6),

        // Product name
        Text(_name,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2)),
        const SizedBox(height: 10),

        // Rating row
        if (_rating > 0 || _reviews > 0)
          Row(children: [
            Row(children: List.generate(5, (i) => Icon(
              i < _rating.round()
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: const Color(0xFFFFC107), size: 16,
            ))),
            const SizedBox(width: 6),
            Text(_rating.toStringAsFixed(1),
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('($_reviews avis)',
                style: GoogleFonts.montserrat(
                    color: AppColors.blue, fontSize: 12)),
            const Spacer(),
            if (_sold > 0)
              Text('${_fmtFollowers(_sold)} vendus',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
          ]),

        if (_rating > 0 || _reviews > 0) const SizedBox(height: 14),

        // Price row
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
          Text('${_fmt(_unitPrice)} DA',
              style: GoogleFonts.montserrat(
                  color: hasPromo ? Colors.red : AppColors.nearBlack,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          if (hasPromo) ...[
            const SizedBox(width: 10),
            Text('${_fmt(_price)} DA',
                style: GoogleFonts.montserrat(
                    color: AppColors.gray,
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough)),
          ],
          const Spacer(),
          _buildQtySelector(),
        ]),
      ]),
    );
  }

  Widget _buildQtySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _qtyBtn(Icons.remove, () => setState(() { if (_qty > 1) _qty--; })),
        SizedBox(
          width: 32,
          child: Text('$_qty',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
        _qtyBtn(Icons.add, () => setState(() => _qty++)),
      ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppColors.nearBlack,
              borderRadius: BorderRadius.circular(24)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      );

  // ── Sizes ──────────────────────────────────────────────────────────────────

  Widget _buildSizes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Taille',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 8,
          children: _sizes.map((v) {
            final s   = _s<String>(v['size']) ?? '';
            final qty = _s<int>(v['qty'])     ?? 999;
            final oos = qty == 0;
            final sel = _selSize == s;
            return GestureDetector(
              onTap: oos ? null : () => setState(() => _selSize = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52, height: 48,
                decoration: BoxDecoration(
                  color: oos
                      ? const Color(0xFFF5F5F5)
                      : (sel ? AppColors.nearBlack : Colors.white),
                  border: Border.all(
                    color: oos
                        ? AppColors.lightGray
                        : (sel ? AppColors.nearBlack : AppColors.lightGray),
                    width: sel ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: oos
                    ? Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Text(s,
                            style: GoogleFonts.montserrat(
                                color: AppColors.grayLight,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text('OOS',
                              style: GoogleFonts.montserrat(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ])
                    : Text(s,
                        style: GoogleFonts.montserrat(
                            color: sel ? Colors.white : AppColors.nearBlack,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── Colors ─────────────────────────────────────────────────────────────────

  Widget _buildColors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Couleur',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10,
          children: _colors.map((v) {
            final hex  = _s<String>(v['hex'])  ?? '#CCCCCC';
            final name = _s<String>(v['name']) ?? '';
            final qty  = _s<int>(v['qty'])     ?? 999;
            final oos  = qty == 0;
            final sel  = _selColorHex == hex;
            Color c;
            try {
              c = Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
            } catch (_) {
              c = AppColors.lightGray;
            }
            return Tooltip(
              message: oos ? '$name — Rupture de stock' : name,
              child: GestureDetector(
                onTap: oos ? null : () => setState(() => _selColorHex = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: oos ? c.withValues(alpha: 0.35) : c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? AppColors.nearBlack : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: sel && !oos
                        ? [BoxShadow(
                            color: c.withValues(alpha: 0.4),
                            blurRadius: 8, spreadRadius: 2)]
                        : [],
                  ),
                  child: sel && !oos
                      ? Icon(Icons.check_rounded,
                          color: c.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 16)
                      : oos
                          ? const Icon(Icons.close,
                              size: 14, color: Colors.white70)
                          : null,
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Description',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _descExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(_desc,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13, height: 1.6)),
          secondChild: Text(_desc,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13, height: 1.6)),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _descExpanded = !_descExpanded),
          child: Text(
            _descExpanded ? 'Voir moins' : 'Lire plus…',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  // ── Store card ─────────────────────────────────────────────────────────────

  Widget _buildStoreCard() {
    if (_storeName.isEmpty) return const SizedBox();
    final initials = _storeName.length >= 2
        ? _storeName.substring(0, 2).toUpperCase()
        : _storeName.toUpperCase();
    final logoUrl = _storeLogo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(children: [
          // Logo
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: AppColors.nearBlack,
                borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.hardEdge,
            child: logoUrl != null && logoUrl.startsWith('http')
                ? Image.network(logoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(initials,
                          style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14)),
                    ))
                : Center(
                    child: Text(initials,
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
          ),
          const SizedBox(width: 12),

          // Name + meta
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(_storeName,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (_storeVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF1976D2), size: 15),
                ],
              ]),
              const SizedBox(height: 2),
              Row(children: [
                if (_storeRating > 0) ...[
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 13),
                  const SizedBox(width: 3),
                  Text(_storeRating.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
                  const SizedBox(width: 6),
                ],
                if (_storeFollowers > 0)
                  Text('${_fmtFollowers(_storeFollowers)} abonnés',
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
              ]),
            ]),
          ),

          // Actions
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            GestureDetector(
              onTap: _storeId != null
                  ? () => Navigator.pushNamed(context, '/store',
                      arguments: {'storeId': _storeId})
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.nearBlack,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Voir boutique',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final total = _unitPrice * _qty;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(children: [
          // Add to cart / Go to cart
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_inCart) {
                  Navigator.pushNamed(context, '/cart');
                } else {
                  CartService.instance.addProduct(_p!);
                  setState(() => _inCart = true);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '$_qty article${_qty > 1 ? "s" : ""} ajouté${_qty > 1 ? "s" : ""} au panier !'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Voir',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/cart'),
                    ),
                  ));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 52,
                decoration: BoxDecoration(
                  color: _inCart ? const Color(0xFF27AE60) : null,
                  gradient: _inCart
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.accent, AppColors.blue]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (_inCart ? const Color(0xFF27AE60) : AppColors.blue)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(
                    _inCart
                        ? Icons.shopping_cart_rounded
                        : Icons.shopping_cart_outlined,
                    color: _inCart ? Colors.white : AppColors.nearBlack,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _inCart ? 'Voir le panier' : 'Ajouter au panier',
                    style: GoogleFonts.montserrat(
                        color: _inCart ? Colors.white : AppColors.nearBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  ),
                  if (!_inCart) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.nearBlack.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_fmt(total)} DA',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── HD image viewer ────────────────────────────────────────────────────────

  void _openViewer(List<String> urls, int initial) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) =>
          _FullscreenViewer(urls: urls, initialIndex: initial),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  // ── Overlay button ─────────────────────────────────────────────────────────

  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.nearBlack : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        child: Icon(icon,
            size: 18,
            color: filled ? Colors.white : AppColors.nearBlack),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen HD image viewer — pinch-to-zoom + double-tap + swipe-to-dismiss
// ─────────────────────────────────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullscreenViewer({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late int _current;

  // Per-page transform controllers (one per image)
  late final List<TransformationController> _transforms;

  // Drag-to-dismiss tracking
  double _dragY    = 0;
  bool   _dragging = false;

  // Hint animation
  late final AnimationController _hintCtrl;
  late final Animation<double>   _hintAnim;

  @override
  void initState() {
    super.initState();
    _current  = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _transforms = List.generate(
        widget.urls.length, (_) => TransformationController());

    // Fade-out the zoom hint after 1.8 s
    _hintCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _hintAnim = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _hintCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1800),
        () { if (mounted) _hintCtrl.forward(); });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final t in _transforms) { t.dispose(); }
    _hintCtrl.dispose();
    super.dispose();
  }

  // ── Double-tap: toggle 1× ↔ 3× ────────────────────────────────────────────

  void _doubleTap(TapDownDetails details, int index) {
    final ctrl   = _transforms[index];
    final isZoomed = ctrl.value != Matrix4.identity();
    if (isZoomed) {
      ctrl.value = Matrix4.identity();
    } else {
      // Zoom 3× centred on the tap position
      const s   = 3.0;
      final dx  = details.localPosition.dx;
      final dy  = details.localPosition.dy;
      // Scale matrix centred on tap: T(tx,ty) * S(s)
      final m   = Matrix4.identity();
      m.setEntry(0, 0, s);
      m.setEntry(1, 1, s);
      m.setEntry(0, 3, -dx * (s - 1));
      m.setEntry(1, 3, -dy * (s - 1));
      ctrl.value = m;
    }
  }

  // ── Swipe-down to close ────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    final ctrl = _transforms[_current];
    // Only allow dismiss drag when not zoomed in
    if (ctrl.value == Matrix4.identity()) {
      setState(() { _dragging = true; _dragY += d.delta.dy; });
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragY > 90 || d.primaryVelocity! > 600) {
      Navigator.of(context).pop();
    } else {
      setState(() { _dragY = 0; _dragging = false; });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final opacity = (_dragging ? (1 - (_dragY / 280).clamp(0.0, 1.0)) : 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      body: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd:    _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragY),
          child: Stack(children: [

            // ── Images ────────────────────────────────────────────────────
            PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.urls.length,
              onPageChanged: (i) {
                // Reset zoom when swiping to next page
                _transforms[_current].value = Matrix4.identity();
                setState(() => _current = i);
              },
              itemBuilder: (ctx, i) {
                final url = widget.urls[i];
                return GestureDetector(
                  onDoubleTapDown: (d) => _doubleTap(d, i),
                  onDoubleTap: () {},
                  child: InteractiveViewer(
                    transformationController: _transforms[i],
                    minScale: 0.8,
                    maxScale: 5.0,
                    clipBehavior: Clip.none,
                    child: Center(
                      child: url.startsWith('http')
                          ? Image.network(url,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white38, size: 64))
                          : Image.asset(url,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white38, size: 64)),
                    ),
                  ),
                );
              },
            ),

            // ── Close button ──────────────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),

            // ── Page counter (e.g. "2 / 4") ───────────────────────────────
            if (widget.urls.length > 1)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_current + 1} / ${widget.urls.length}',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Zoom hint (fades out) ──────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: FadeTransition(
                  opacity: _hintAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.zoom_in_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('Pincez pour zoomer · Double-tap',
                          style: GoogleFonts.montserrat(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Dot indicators ────────────────────────────────────────────
            if (widget.urls.length > 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.urls.length, (i) =>
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _current ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? Colors.white
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
