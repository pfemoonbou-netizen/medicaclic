import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double price;
  final double? originalPrice;
  final String? image;
  final double rating;
  final int reviewCount;
  final String seller;
  final String phone;
  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    this.originalPrice,
    this.image,
    required this.rating,
    this.reviewCount = 0,
    required this.seller,
    required this.phone,
  });

  int? get discountPercent => originalPrice == null ? null : (((originalPrice! - price) / originalPrice!) * 100).round();

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        brand: map['brand'] as String? ?? '',
        category: map['category'] as String? ?? 'Achat',
        description: map['description'] as String? ?? '',
        price: (map['price'] as num).toDouble(),
        originalPrice: (map['original_price'] as num?)?.toDouble(),
        image: map['image'] as String?,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
        seller: map['seller'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
      );
}

class PromoOffer {
  final String title;
  final String discountText;
  final String deliveryText;
  final String promoCode;
  final Color color;
  PromoOffer({required this.title, required this.discountText, required this.deliveryText, required this.promoCode, required this.color});

  factory PromoOffer.fromMap(Map<String, dynamic> map) => PromoOffer(
        title: map['title'] as String,
        discountText: map['discount_text'] as String,
        deliveryText: map['delivery_text'] as String,
        promoCode: map['promo_code'] as String,
        color: Color(int.parse((map['color_hex'] as String).replaceFirst('#', '0xFF'))),
      );
}

/// Bannière publicitaire gérée par l'admin (table promo_banners).
class AdBanner {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String mediaType; // 'image' ou 'video'
  final Color color;
  AdBanner({required this.id, required this.title, required this.subtitle, required this.imageUrl, required this.mediaType, required this.color});

  bool get isVideo => mediaType == 'video' && imageUrl != null;

  factory AdBanner.fromMap(Map<String, dynamic> map) {
    final hex = (map['color_hex'] as String?) ?? '#6C5FE0';
    return AdBanner(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      mediaType: (map['media_type'] as String?) ?? 'image',
      color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
    );
  }
}

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<PromoOffer> promoOffers = [];
  List<AdBanner> banners = [];
  bool _isLoading = false;
  String? _error;

  /// Produits locaux toujours affichés (images dans assets/images/),
  /// meme sans connexion Supabase.
  static final List<Product> _localProducts = [
    Product(
      id: 'local_genouillere',
      name: 'Genouillère orthopédique',
      brand: 'MedicaClic',
      category: 'Orthopédie',
      description: "Genouillère de maintien et compression pour soulager les douleurs articulaires, entorses et tendinites. Tissu respirant, ajustable et confortable pour un port quotidien.",
      price: 2500,
      originalPrice: 3200,
      image: 'assets/images/genouillere.jpg',
      rating: 4.6,
      reviewCount: 42,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_chevillere',
      name: 'Chevillère de maintien',
      brand: 'MedicaClic',
      category: 'Orthopédie',
      description: "Chevillère élastique pour stabiliser la cheville après une entorse ou pendant l'activité sportive. Maintien ferme, réduit l'œdème et sécurise l'articulation.",
      price: 1800,
      image: 'assets/images/chevillere.jpg',
      rating: 4.5,
      reviewCount: 28,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_semelles',
      name: 'Semelles orthopédiques',
      brand: 'MedicaClic',
      category: 'Orthopédie',
      description: "Semelles anatomiques à mémoire de forme qui soutiennent la voûte plantaire, absorbent les chocs et corrigent la posture. Idéales contre la fatigue et les douleurs du pied.",
      price: 2200,
      image: 'assets/images/semelles.jpg',
      rating: 4.7,
      reviewCount: 55,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_sacoche_insuline',
      name: 'Sacoche isotherme insuline',
      brand: 'MedicaClic',
      category: 'Bien-être',
      description: "Trousse isotherme pour conserver l'insuline et les médicaments au frais lors des déplacements. Compartiments protégés, maintien de la température plusieurs heures.",
      price: 3500,
      originalPrice: 4000,
      image: 'assets/images/sacoche_insuline.jpg',
      rating: 4.8,
      reviewCount: 33,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_brosse_dents',
      name: 'Brosse à dents souple',
      brand: 'MedicaClic',
      category: 'Hygiène',
      description: "Brosse à dents à poils souples respectueuse des gencives sensibles et de l'émail. Nettoyage doux et efficace, manche ergonomique antidérapant.",
      price: 350,
      image: 'assets/images/brosse_dents.jpg',
      rating: 4.4,
      reviewCount: 19,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_vitamine_c_e',
      name: 'Vitamine C + E anti-rides',
      brand: 'MedicaClic',
      category: 'Bien-être',
      description: "Capsules Vitamine C + E qui hydratent et nourrissent la peau pour un teint jeune et énergique. 90 capsules, action douce et efficace anti-âge.",
      price: 2800,
      originalPrice: 3400,
      image: 'assets/images/vitamine_c_e.jpg',
      rating: 4.5,
      reviewCount: 27,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_balance_pese_personne',
      name: 'Pèse-personne digital',
      brand: 'MedicaClic',
      category: 'Diagnostic',
      description: "Balance électronique précise avec écran digital rétroéclairé : poids et température affichés instantanément. Design compact aux coins arrondis.",
      price: 3200,
      image: 'assets/images/balance_pese_personne.jpg',
      rating: 4.6,
      reviewCount: 34,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_porte_cles_halteres',
      name: 'Porte-clés haltères (lot de 2)',
      brand: 'MedicaClic',
      category: 'Bien-être',
      description: "Porte-clés en forme d'haltère 5kg, lot de 2. Petit rappel motivant à garder toujours sur soi pour ne jamais oublier ses objectifs fitness.",
      price: 900,
      image: 'assets/images/porte_cles_halteres.jpg',
      rating: 4.3,
      reviewCount: 12,
      seller: 'MedicaClic',
      phone: '',
    ),
    Product(
      id: 'local_serums_visage',
      name: 'Trio sérums visage',
      brand: 'MedicaClic',
      category: 'Bien-être',
      description: "Coffret 3 sérums : Acide Salicylique 2% (anti-imperfections), Niacinamide 5% (éclat et pores resserrés), Rétinol 0.1% (anti-taches, contrôle du sébum). 60ml chacun.",
      price: 4500,
      originalPrice: 5200,
      image: 'assets/images/serums_visage.jpg',
      rating: 4.7,
      reviewCount: 45,
      seller: 'MedicaClic',
      phone: '',
    ),
  ];

  ProductProvider() {
    fetchAll();
  }

  List<String> get categories => ['Tout', 'Orthopédie', 'Mobilité', 'Diagnostic', 'Hygiène', 'Bien-être', 'Location'];

  List<Product> get featured {
    final sorted = List<Product>.from(_products)..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        supabase.from('products').select(),
        supabase.from('promo_offers').select(),
      ]);
      _products = (results[0] as List).map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
      promoOffers = (results[1] as List).map((row) => PromoOffer.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    }

    // Toujours ajouter les produits locaux (affichés meme hors ligne).
    _products = [..._localProducts, ..._products];

    // Bannières pub (table optionnelle) : isolé pour ne pas casser les
    // produits si la table n'existe pas encore.
    try {
      final b = await supabase.from('promo_banners').select().eq('active', true).order('created_at', ascending: false);
      banners = (b as List).map((row) => AdBanner.fromMap(row as Map<String, dynamic>)).toList();
    } catch (_) {
      banners = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Product> byCategory(String category) => category == 'Tout' ? _products : _products.where((p) => p.category == category).toList();

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
