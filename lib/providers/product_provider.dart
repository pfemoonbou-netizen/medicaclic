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

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<PromoOffer> promoOffers = [];
  bool _isLoading = false;
  String? _error;

  ProductProvider() {
    fetchAll();
  }

  List<String> get categories => ['Tout', 'Orthopédie', 'Mobilité', 'Diagnostic', 'Hygiène', 'Location'];

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
