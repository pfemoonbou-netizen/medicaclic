import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/product_card.dart';
import 'add_banner_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  static const _purple = Color(0xFF5F55D7);
  static const _dark = Color(0xFF101522);
  static const _bg = Color(0xFFF7F8FA);

  String _category = 'Tout';
  String _name = '';
  String _role = '';
  final PageController _bannerController = PageController();
  int _bannerPage = 0;
  // Produits dont l'image n'a pas charge : retires de l'affichage pour
  // eviter un emplacement vide dans la grille/liste.
  final Set<String> _hiddenProductIds = {};

  bool get _isAdmin => _role == 'admin';

  static const List<_Ad> _ads = [
    _Ad('Offre spéciale', '-20% Orthopédie', 'Genouillères, attelles & ceintures', Color(0xFF6C5FE0), Color(0xFF5147C4), Icons.local_offer),
    _Ad('Livraison', 'Gratuite dès 5000 DA', 'Partout en Algérie · 48h', Color(0xFF1AA88F), Color(0xFF128273), Icons.local_shipping),
    _Ad('Nouveautés', 'Matériel de diagnostic', 'Tensiomètres · Oxymètres · Glucomètres', Color(0xFFF2994A), Color(0xFFE07B2E), Icons.monitor_heart),
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final row = await supabase.from('profiles').select('name, role').eq('id', uid).maybeSingle();
      if (!mounted) return;
      final n = (row?['name'] as String?)?.trim();
      final r = (row?['role'] as String?)?.trim();
      setState(() {
        if (n != null && n.isNotEmpty) _name = n;
        if (r != null) _role = r;
      });
    } catch (_) {}
  }

  Future<void> _openAddBanner() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddBannerScreen()),
    );
    if (created == true && mounted) {
      await context.read<ProductProvider>().fetchAll();
    }
  }

  void _add(Product p) {
    context.read<CartProvider>().addToCart(CartItem(id: p.id, name: p.name, price: p.price, image: p.image));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} ajouté au panier'), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.byCategory(_category).where((p) => !_hiddenProductIds.contains(p.id)).toList();
    final featured = provider.featured.where((p) => !_hiddenProductIds.contains(p.id)).toList();

    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _searchBar(),
                  const SizedBox(height: 18),
                  _adCarousel(provider),
                  if (_isAdmin) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openAddBanner,
                        icon: const Icon(Icons.add, color: _purple, size: 18),
                        label: const Text('Ajouter une pub', style: TextStyle(color: _purple, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _purple), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (featured.isNotEmpty) ...[
                    _sectionHeader('En vedette'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => SizedBox(width: 165, child: ProductCard(product: featured[i], onAddToCart: () => _add(featured[i]), onImageError: () => setState(() => _hiddenProductIds.add(featured[i].id)))),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _categoryChips(provider),
                  const SizedBox(height: 16),
                  _sectionHeader('Tous les produits'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.66, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: products.length,
                    itemBuilder: (context, i) => ProductCard(product: products[i], onAddToCart: () => _add(products[i]), onImageError: () => setState(() => _hiddenProductIds.add(products[i].id))),
                  ),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('Aucun produit dans cette catégorie.', style: TextStyle(color: Colors.grey))),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    final display = _name.isEmpty ? 'Bienvenue' : _name;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: _purple.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.person, color: _purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bonjour 👋', style: TextStyle(color: Color(0xFF9B9999), fontSize: 13)),
              Text(display, style: const TextStyle(color: _dark, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/cart'),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart_outlined, color: _dark, size: 22),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Consumer<CartProvider>(
                builder: (context, cart, _) => cart.itemCount == 0
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.search, size: 20, color: Color(0xFF9B9999)),
          SizedBox(width: 10),
          Text('Rechercher un produit...', style: TextStyle(color: Color(0xFF9B9999), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _adCarousel(ProductProvider provider) {
    // Bannières de l'admin (base) si présentes, sinon bannières par défaut.
    final dbBanners = provider.banners;
    final int count = dbBanners.isNotEmpty ? dbBanners.length : _ads.length;
    // Format carré : hauteur = largeur (plafonnée pour les grands écrans).
    final double size = (MediaQuery.of(context).size.width - 32).clamp(200, 380).toDouble();
    return Column(
      children: [
        SizedBox(
          height: size,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: count,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (context, i) => dbBanners.isNotEmpty ? _dbSlide(dbBanners[i]) : _adSlide(_ads[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _bannerPage ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _bannerPage ? _purple : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _adSlide(_Ad ad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ad.c1, ad.c2]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad.title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(ad.big, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(ad.sub, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(ad.icon, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  // Bannière créée par l'admin (image optionnelle en fond + texte).
  Widget _dbSlide(AdBanner b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (b.isVideo)
            _BannerVideo(url: b.imageUrl!)
          else if (b.imageUrl != null)
            Image.network(b.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox.shrink()),
          if (b.imageUrl != null) Container(color: Colors.black.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.title.isNotEmpty)
                  Text(b.title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (b.title.isNotEmpty) const SizedBox(height: 6),
                if (b.subtitle.isNotEmpty)
                  Text(b.subtitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.bold)),
        const Text('Voir tout', style: TextStyle(color: _purple, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _categoryChips(ProductProvider provider) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = provider.categories[i];
          final active = cat == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _purple : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(cat, style: TextStyle(color: active ? Colors.white : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

class _Ad {
  final String title;
  final String big;
  final String sub;
  final Color c1;
  final Color c2;
  final IconData icon;
  const _Ad(this.title, this.big, this.sub, this.c1, this.c2, this.icon);
}

/// Lecture d'une vidéo de bannière (auto, en boucle, sans son).
class _BannerVideo extends StatefulWidget {
  final String url;
  const _BannerVideo({required this.url});

  @override
  State<_BannerVideo> createState() => _BannerVideoState();
}

class _BannerVideoState extends State<_BannerVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      c.setLooping(true);
      c.setVolume(0);
      c.play();
      if (mounted) {
        setState(() {
          _controller = c;
          _ready = true;
        });
      }
    } catch (_) {
      // En cas d'échec, on laisse la couleur de fond de la bannière.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
