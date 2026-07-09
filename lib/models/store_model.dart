// ─────────────────────────────────────────────────────────────────────────────
// Store domain models
// ─────────────────────────────────────────────────────────────────────────────

class StoreData {
  final String id;
  final String ownerId;
  final String storeName;
  final String username;
  final String? logoUrl;
  final String? coverUrl;
  final String? bio;
  final String? address;
  final String? wilaya;
  final String? category;
  final List<String> subcategories;
  final String? website;
  final Map<String, String> socialLinks;
  final Map<String, String> contactLinks;
  final int followersCount;
  final int productsCount;
  final int postsCount;
  final int reelsCount;
  final bool isVerified;

  const StoreData({
    required this.id,
    required this.ownerId,
    required this.storeName,
    this.username = '',
    this.logoUrl,
    this.coverUrl,
    this.bio,
    this.address,
    this.wilaya,
    this.category,
    this.subcategories = const [],
    this.website,
    this.socialLinks = const {},
    this.contactLinks = const {},
    this.followersCount = 0,
    this.productsCount = 0,
    this.postsCount = 0,
    this.reelsCount = 0,
    this.isVerified = false,
  });

  factory StoreData.fromMap(Map<String, dynamic> m) => StoreData(
        id: m['id'] as String,
        ownerId: m['owner_id'] as String,
        storeName: m['store_name'] as String? ?? '',
        username: m['username'] as String? ?? '',
        logoUrl: m['logo_url'] as String?,
        coverUrl: m['cover_url'] as String?,
        bio: m['bio'] as String?,
        address: m['address'] as String?,
        wilaya: m['wilaya'] as String?,
        category: m['category'] as String?,
        subcategories: List<String>.from(m['subcategories'] as List? ?? []),
        website: m['website'] as String?,
        socialLinks: Map<String, String>.from(m['social_links'] as Map? ?? {}),
        contactLinks: Map<String, String>.from(m['contact_links'] as Map? ?? {}),
        followersCount: m['followers_count'] as int? ?? 0,
        productsCount: m['products_count'] as int? ?? 0,
        postsCount: m['posts_count'] as int? ?? 0,
        reelsCount: m['reels_count'] as int? ?? 0,
        isVerified: m['is_verified'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'owner_id': ownerId,
        'store_name': storeName,
        'username': username,
        'logo_url': logoUrl,
        'cover_url': coverUrl,
        'bio': bio,
        'address': address,
        'wilaya': wilaya,
        'category': category,
        'subcategories': subcategories,
        'website': website,
        'social_links': socialLinks,
        'contact_links': contactLinks,
        'is_verified': isVerified,
      };

  StoreData copyWith({
    String? storeName,
    String? username,
    String? logoUrl,
    String? coverUrl,
    String? bio,
    String? address,
    String? wilaya,
    String? category,
    List<String>? subcategories,
    String? website,
    Map<String, String>? socialLinks,
    Map<String, String>? contactLinks,
  }) =>
      StoreData(
        id: id,
        ownerId: ownerId,
        storeName: storeName ?? this.storeName,
        username: username ?? this.username,
        logoUrl: logoUrl ?? this.logoUrl,
        coverUrl: coverUrl ?? this.coverUrl,
        bio: bio ?? this.bio,
        address: address ?? this.address,
        wilaya: wilaya ?? this.wilaya,
        category: category ?? this.category,
        subcategories: subcategories ?? this.subcategories,
        website: website ?? this.website,
        socialLinks: socialLinks ?? this.socialLinks,
        contactLinks: contactLinks ?? this.contactLinks,
        followersCount: followersCount,
        productsCount: productsCount,
        postsCount: postsCount,
        reelsCount: reelsCount,
        isVerified: isVerified,
      );

  static const demo = StoreData(
    id: 'demo-store',
    ownerId: 'demo',
    storeName: 'LOOLET STORE',
    username: 'loolet_store',
    bio: 'Boutique de mode tendance en Algérie 🌸\nCollection été 2026 disponible !',
    address: 'Alger Centre, Rue Didouche Mourad',
    wilaya: '16 - Alger',
    category: 'Mode',
    subcategories: ['Femme', 'Hijab', 'Accessoires'],
    website: 'www.loolet.dz',
    socialLinks: {'instagram': '@loolet_store', 'facebook': 'LooletStore'},
    contactLinks: {'whatsapp': '0612345678', 'email': 'contact@loolet.dz'},
    followersCount: 2500,
    productsCount: 48,
    postsCount: 124,
    reelsCount: 18,
    isVerified: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class StoreProduct {
  final String id;
  final String storeId;
  final String name;
  final double price;
  final double? promoPrice;
  final List<String> images;
  final bool available;
  final int soldCount;
  final double rating;

  // Variants (used by ProductDetailsPage)
  final List<Map<String, dynamic>> sizeVariants;
  final List<Map<String, dynamic>> colorVariants;

  const StoreProduct({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    this.promoPrice,
    this.images = const [],
    this.available = true,
    this.soldCount = 0,
    this.rating = 5.0,
    this.sizeVariants = const [],
    this.colorVariants = const [],
  });

  factory StoreProduct.fromMap(Map<String, dynamic> m) => StoreProduct(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        promoPrice: m['promo_price'] != null
            ? (m['promo_price'] as num).toDouble()
            : null,
        images: List<String>.from(m['images'] as List? ?? []),
        available: m['available'] as bool? ?? true,
        soldCount: m['sold_count'] as int? ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        sizeVariants: (m['size_variants'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        colorVariants: (m['color_variants'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );

  int get discountPercent => promoPrice == null
      ? 0
      : ((1 - promoPrice! / price) * 100).round();
}


// ─────────────────────────────────────────────────────────────────────────────

class StorePost {
  final String id;
  final String storeId;
  final String type; // classic | commercial | reel | story
  final String? caption;
  final List<String> mediaUrls;
  final String? coverUrl;
  final String? productId;
  final String? productName;
  final double? price;
  final double? promoPrice;
  final List<String> hashtags;
  final String? location;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;

  const StorePost({
    required this.id,
    required this.storeId,
    required this.type,
    this.caption,
    this.mediaUrls = const [],
    this.coverUrl,
    this.productId,
    this.productName,
    this.price,
    this.promoPrice,
    this.hashtags = const [],
    this.location,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
  });

  factory StorePost.fromMap(Map<String, dynamic> m) => StorePost(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        type: m['post_type'] as String,
        caption: m['caption'] as String?,
        mediaUrls: List<String>.from(m['media_urls'] as List? ?? []),
        coverUrl: m['cover_url'] as String?,
        productId: m['product_id'] as String?,
        productName: m['product_name'] as String?,
        price: m['price'] != null ? (m['price'] as num).toDouble() : null,
        promoPrice: m['promo_price'] != null
            ? (m['promo_price'] as num).toDouble()
            : null,
        hashtags: List<String>.from(m['hashtags'] as List? ?? []),
        location: m['location'] as String?,
        likesCount: m['likes_count'] as int? ?? 0,
        commentsCount: m['comments_count'] as int? ?? 0,
        viewsCount: m['views_count'] as int? ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  bool get isReel => type == 'reel';
  bool get isStory => type == 'story';
  bool get isCommercial => type == 'commercial';
  bool get hasMedia => mediaUrls.isNotEmpty;
}
