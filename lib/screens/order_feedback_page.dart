import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/review_service.dart';
import '../widgets/primary_button.dart';

class _OrderProduct {
  final String? productId;
  final String name;
  final String variant;
  final String? imageUrl;
  const _OrderProduct({
    this.productId,
    required this.name,
    required this.variant,
    this.imageUrl,
  });
}

class OrderFeedbackPage extends StatefulWidget {
  const OrderFeedbackPage({super.key, this.order});

  final Map<String, dynamic>? order;

  @override
  State<OrderFeedbackPage> createState() => _OrderFeedbackPageState();
}

class _OrderFeedbackPageState extends State<OrderFeedbackPage> {
  List<_OrderProduct> _products = [];
  List<int> _productRatings = [];
  List<TextEditingController> _productComments = [];
  List<List<XFile>> _productPhotos = [];
  List<Uint8List?> _productPhotoBytes = [];

  int _sellerRating = 0;
  final _sellerCommentCtrl = TextEditingController();

  bool _submitted = false;
  bool _loading = false;
  bool _loadingOrder = true;
  String? _errorMessage;
  String _storeName = 'Boutique';
  String _orderLabel = 'Commande';
  String? _orderId;
  String? _storeId;
  late final RealtimeChannel _reviewChannel;

  bool get _canSubmit =>
      _products.isNotEmpty &&
      _productRatings.every((r) => r > 0) &&
      _sellerRating > 0 &&
      !_loading;

  @override
  void initState() {
    super.initState();
    _reviewChannel = Supabase.instance.client.channel('order-feedback-${DateTime.now().millisecondsSinceEpoch}');
    _reviewChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'store_reviews',
      callback: (payload) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre avis vient d’être publié en direct.')),
        );
      },
    );
    _reviewChannel.subscribe();

    _hydrateFromRoute();
  }

  Future<void> _hydrateFromRoute() async {
    final args = widget.order ?? ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args['storeName'] is String) {
        _storeName = args['storeName'] as String;
      }
      if (args['orderLabel'] is String) {
        _orderLabel = args['orderLabel'] as String;
      }
      if (args['orderId'] != null) {
        _orderId = args['orderId'].toString();
      }
      if (args['storeId'] != null) {
        _storeId = args['storeId'].toString();
      }
    }

    try {
      final client = Supabase.instance.client;
      if (_orderId != null) {
        final row = await client
            .from('orders')
            .select('items, store_id')
            .eq('id', _orderId!)
            .maybeSingle();
        if (row != null) {
          final items = (row['items'] as List?) ?? const [];
          _storeId ??= row['store_id']?.toString();
          _products = items.map((raw) {
            final m = Map<String, dynamic>.from(raw as Map);
            final size = m['size'] as String?;
            final color = m['color_name'] as String?;
            final variantParts = [
              if (size != null && size.isNotEmpty) 'Taille $size',
              if (color != null && color.isNotEmpty) color,
            ];
            return _OrderProduct(
              productId: m['product_id']?.toString(),
              name: (m['name'] as String?) ?? 'Produit',
              variant: variantParts.join(' · '),
              imageUrl: m['image_url'] as String?,
            );
          }).toList();
        }
      }
      if (_storeId == null) {
        final storeRow = await client.from('stores').select('id').limit(1).maybeSingle();
        if (storeRow != null) {
          _storeId = storeRow['id'].toString();
        }
      }
    } catch (_) {}

    _productRatings = List.filled(_products.length, 0);
    _productComments = List.generate(_products.length, (_) => TextEditingController());
    _productPhotos = List.generate(_products.length, (_) => <XFile>[]);
    _productPhotoBytes = List.generate(_products.length, (_) => null);

    if (mounted) {
      setState(() => _loadingOrder = false);
    }
  }

  @override
  void dispose() {
    for (final c in _productComments) {
      c.dispose();
    }
    _sellerCommentCtrl.dispose();
    Supabase.instance.client.removeChannel(_reviewChannel);
    super.dispose();
  }

  Future<void> _pickProductPhoto(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _productPhotos[index] = [picked];
    });
    try {
      final bytes = await picked.readAsBytes();
      setState(() => _productPhotoBytes[index] = bytes);
    } catch (_) {}
  }

  Future<void> _submitReview() async {
    if (!_canSubmit) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      for (var i = 0; i < _products.length; i++) {
        if (_productRatings[i] <= 0) continue;
        await ReviewService.submitProductReview(
          storeId: _storeId,
          orderId: _orderId,
          productId: _products[i].productId,
          productName: _products[i].name,
          rating: _productRatings[i],
          comment: _productComments[i].text,
          photos: _productPhotos[i],
        );
      }

      await ReviewService.submitStoreReview(
        storeId: _storeId,
        orderId: _orderId,
        rating: _sellerRating,
        comment: _sellerCommentCtrl.text,
      );

      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Envoi impossible pour le moment. Vérifiez votre connexion et la configuration Supabase.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Évaluer votre commande', style: GoogleFonts.montserrat(color: AppColors.nearBlack, fontSize: 18, fontWeight: FontWeight.w900)),
      ),
      body: _loadingOrder
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: AppColors.nearBlack, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_storeName, style: GoogleFonts.montserrat(color: AppColors.nearBlack, fontSize: 13, fontWeight: FontWeight.w800)),
                            Text('$_orderLabel · Livré ✓', style: GoogleFonts.montserrat(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    if (_products.isEmpty) ...[
                      Text('Aucun produit trouvé pour cette commande.',
                          style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 12)),
                    ] else ...[
                      Text('Évaluer les produits', style: GoogleFonts.montserrat(color: AppColors.nearBlack, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Chaque produit reçu mérite sa propre note.', style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 12)),
                      const SizedBox(height: 16),
                      ...List.generate(_products.length, (i) => _productCard(i)),
                    ],
                    const SizedBox(height: 8),
                    Container(height: 6, color: AppColors.bgGray),
                    const SizedBox(height: 20),
                    Text('Évaluer la boutique', style: GoogleFonts.montserrat(color: AppColors.nearBlack, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Votre avis global sur $_storeName.', style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 12)),
                    const SizedBox(height: 16),
                    _sellerCard(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: GoogleFonts.montserrat(color: Colors.red.shade700, fontSize: 12)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(children: [
                  if (!_canSubmit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('Notez chaque produit et la boutique pour continuer.', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 12)),
                    ),
                  PrimaryButton(label: 'Publier mon évaluation', loading: _loading, onPressed: _canSubmit ? _submitReview : null),
                ]),
              ),
            ]),
    );
  }

  Widget _productCard(int index) {
    final p = _products[index];
    final rating = _productRatings[index];
    final hasPhoto = _productPhotos[index].isNotEmpty;
    final hasNetworkImage = p.imageUrl != null && p.imageUrl!.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: rating > 0 ? AppColors.nearBlack : AppColors.lightGray,
          width: rating > 0 ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasNetworkImage
                    ? Image.network(
                        p.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.bgGray,
                          child: const Icon(Icons.image_outlined, color: AppColors.lightGray),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: AppColors.bgGray,
                        child: const Icon(Icons.image_outlined, color: AppColors.lightGray),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.variant.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.variant,
                          style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '$rating/5',
                        style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _productRatings[index] = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          if (rating > 0) ...[
            const SizedBox(height: 6),
            Text(
              _ratingLabel(rating),
              style: GoogleFonts.montserrat(
                color: AppColors.gray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _productComments[index],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Votre avis sur ce produit… (optionnel)',
              hintStyle: GoogleFonts.montserrat(color: const Color(0xFFCAC9C9), fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.nearBlack),
              ),
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _pickProductPhoto(index),
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: Text(hasPhoto ? 'Changer la photo' : 'Ajouter une photo'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.lightGray),
              foregroundColor: AppColors.nearBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (hasPhoto) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _productPhotoBytes[index] != null
                  ? Image.memory(
                      _productPhotoBytes[index]!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Container(color: AppColors.bgGray),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sellerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _sellerRating > 0 ? AppColors.nearBlack : AppColors.lightGray,
          width: _sellerRating > 0 ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.nearBlack,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _storeName,
                  style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_sellerRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '$_sellerRating/5',
                        style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _sellerRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    i < _sellerRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          if (_sellerRating > 0) ...[
            const SizedBox(height: 6),
            Text(
              _ratingLabel(_sellerRating),
              style: GoogleFonts.montserrat(
                color: AppColors.gray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _sellerCommentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Votre expérience avec cette boutique… (optionnel)',
              hintStyle: GoogleFonts.montserrat(color: const Color(0xFFCAC9C9), fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.nearBlack),
              ),
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Très mauvais',
        2 => 'Décevant',
        3 => 'Correct',
        4 => 'Bien',
        _ => 'Excellent !',
      };

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 88, height: 88, decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48)),
            const SizedBox(height: 24),
            Text('Merci pour votre avis !', style: GoogleFonts.montserrat(color: AppColors.nearBlack, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Votre évaluation a été envoyée en direct vers le backend LINCOO.', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 13, height: 1.5)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.card_giftcard, color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Text('+30 points LINCOO gagnés !', style: GoogleFonts.montserrat(color: AppColors.nearBlack, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Retour à mes commandes', onPressed: () => Navigator.pushReplacementNamed(context, '/my-orders')),
          ]),
        ),
      ),
    );
  }
}
