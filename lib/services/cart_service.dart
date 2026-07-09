import 'package:flutter/foundation.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class CartItem {
  final String  id;
  final String  name;
  final String  storeName;
  final String? sellerId;   // owner_id of the store — used for commission lookup
  final String? storeId;    // stores.id — used when inserting order
  final double  price;
  final double? promoPrice;
  final String? imageUrl;

  // Real seller variants — empty list means seller didn't define any
  final List<Map<String, dynamic>> sizeVariants;
  final List<Map<String, dynamic>> colorVariants;

  int    qty;
  String size;
  String colorName;
  String colorHex;

  CartItem({
    required this.id,
    required this.name,
    required this.storeName,
    this.sellerId,
    this.storeId,
    required this.price,
    this.promoPrice,
    this.imageUrl,
    this.sizeVariants  = const [],
    this.colorVariants = const [],
    this.qty       = 1,
    this.size      = '',
    this.colorName = '',
    this.colorHex  = '',
  });

  double get unitPrice => promoPrice ?? price;
  double get total     => unitPrice * qty;

  CartItem copyWith({
    int?    qty,
    String? size,
    String? colorName,
    String? colorHex,
  }) =>
      CartItem(
        id:            id,
        name:          name,
        storeName:     storeName,
        sellerId:      sellerId,
        storeId:       storeId,
        price:         price,
        promoPrice:    promoPrice,
        imageUrl:      imageUrl,
        sizeVariants:  sizeVariants,
        colorVariants: colorVariants,
        qty:           qty       ?? this.qty,
        size:          size      ?? this.size,
        colorName:     colorName ?? this.colorName,
        colorHex:      colorHex  ?? this.colorHex,
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  final ValueNotifier<List<CartItem>> notifier =
      ValueNotifier<List<CartItem>>([]);

  List<CartItem> get items => notifier.value;

  bool contains(String productId) =>
      notifier.value.any((i) => i.id == productId);

  void addProduct(Map<String, dynamic> product) {
    final id = _s(product['id']) ?? UniqueKey().toString();
    if (contains(id)) return;

    // Store name + seller/store IDs
    final storeRaw = product['stores'];
    String  storeName = '';
    String? sellerId;
    String? storeId;
    if (storeRaw is Map) {
      storeName = _s(storeRaw['store_name']) ?? '';
      sellerId  = _s(storeRaw['owner_id']);
      storeId   = _s(storeRaw['id']);
    } else if (storeRaw is List && storeRaw.isNotEmpty) {
      storeName = _s(storeRaw.first['store_name']) ?? '';
      sellerId  = _s(storeRaw.first['owner_id']);
      storeId   = _s(storeRaw.first['id']);
    }

    // First image
    final images = product['images'];
    String? imageUrl;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.startsWith('http')) imageUrl = first;
    }

    // Real size variants from seller
    final rawSizes = product['size_variants'];
    final sizeVariants = (rawSizes is List)
        ? rawSizes
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['size'] is String)
            .toList()
        : <Map<String, dynamic>>[];

    // Real color variants from seller
    final rawColors = product['color_variants'];
    final colorVariants = (rawColors is List)
        ? rawColors
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['hex'] is String)
            .toList()
        : <Map<String, dynamic>>[];

    // Pre-select first available size/color
    String defaultSize = '';
    if (sizeVariants.isNotEmpty) {
      final first = sizeVariants.firstWhere(
          (v) => ((v['qty'] as int?) ?? 999) > 0,
          orElse: () => sizeVariants.first);
      defaultSize = first['size'] as String? ?? '';
    }
    String defaultColorName = '';
    String defaultColorHex  = '';
    if (colorVariants.isNotEmpty) {
      final first = colorVariants.firstWhere(
          (v) => ((v['qty'] as int?) ?? 999) > 0,
          orElse: () => colorVariants.first);
      defaultColorName = first['name'] as String? ?? '';
      defaultColorHex  = first['hex']  as String? ?? '';
    }

    final item = CartItem(
      id:            id,
      name:          _s(product['name'])       ?? 'Produit',
      storeName:     storeName,
      sellerId:      sellerId,
      storeId:       storeId,
      price:         (_n(product['price'])     ?? 0).toDouble(),
      promoPrice:    _n(product['promo_price'])?.toDouble(),
      imageUrl:      imageUrl,
      sizeVariants:  sizeVariants,
      colorVariants: colorVariants,
      size:          defaultSize,
      colorName:     defaultColorName,
      colorHex:      defaultColorHex,
    );

    notifier.value = [...notifier.value, item];
  }

  void remove(String id) {
    notifier.value = notifier.value.where((i) => i.id != id).toList();
  }

  void update(String id,
      {int? qty, String? size, String? colorName, String? colorHex}) {
    notifier.value = notifier.value.map((i) {
      if (i.id != id) return i;
      if (qty != null && qty < 1) return null;
      return i.copyWith(
          qty: qty, size: size, colorName: colorName, colorHex: colorHex);
    }).whereType<CartItem>().toList();
  }

  void clear() => notifier.value = [];

  static String? _s(dynamic v) => v is String && v.isNotEmpty ? v : null;
  static num?    _n(dynamic v) => v is num ? v : null;
}
