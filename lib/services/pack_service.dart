import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────

enum PackType { starter, essentiel, pro, business, lincooPlus }

class SellerPack {
  final String  id;
  final String  sellerId;
  final PackType type;
  final String  status;
  final int     priceDzd;
  final String? paymentRef;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DateTime  createdAt;

  const SellerPack({
    required this.id,
    required this.sellerId,
    required this.type,
    required this.status,
    required this.priceDzd,
    this.paymentRef,
    this.activatedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory SellerPack.fromMap(Map<String, dynamic> m) {
    final raw = m['pack_type'] as String? ?? 'starter';
    final type = switch (raw) {
      'essentiel'   => PackType.essentiel,
      'pro'         => PackType.pro,
      'lincoo_plus' => PackType.lincooPlus, // legacy
      'business'    => PackType.lincooPlus, // legacy
      _             => PackType.starter,
    };
    return SellerPack(
    id:          m['id'] as String,
    sellerId:    m['seller_id'] as String,
    type:        type,
    status:      m['status']      as String? ?? 'pending_payment',
    priceDzd:    m['price_dzd']   as int? ?? 0,
    paymentRef:  m['payment_ref'] as String?,
    activatedAt: m['activated_at'] != null
        ? DateTime.tryParse(m['activated_at'] as String)
        : null,
    expiresAt: m['expires_at'] != null
        ? DateTime.tryParse(m['expires_at'] as String)
        : null,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  bool get isActive =>
      status == 'active' &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get isPendingPayment => status == 'pending_payment';
  bool get isPaid           => status == 'paid';
  bool get isExpired        => status == 'expired' ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));

  String get label => switch (type) {
    PackType.starter    => 'Starter',
    PackType.essentiel  => 'Essentiel',
    PackType.pro        => 'Pro',
    PackType.business   => 'Pro',
    PackType.lincooPlus => 'Pro',
  };

  String get emoji => switch (type) {
    PackType.starter    => '🛍️',
    PackType.essentiel  => '⭐',
    PackType.pro        => '💎',
    PackType.business   => '💎',
    PackType.lincooPlus => '💎',
  };

  /// Commission Lincoo prélève sur chaque vente
  double get commissionRate => switch (type) {
    PackType.starter    => 0.05, // 5%
    PackType.essentiel  => 0.03, // 3%
    PackType.pro        => 0.03, // 3%
    PackType.business   => 0.03, // legacy
    PackType.lincooPlus => 0.03, // legacy
  };

  int get maxProducts => switch (type) {
    PackType.starter    => 15,
    PackType.essentiel  => 300,
    PackType.pro        => 999999,  // illimité
    PackType.business   => 999999,
    PackType.lincooPlus => 999999,
  };

  bool get isAnnual => type != PackType.starter;

  bool get canCreateReels   => type == PackType.pro || type == PackType.lincooPlus || type == PackType.business;
  bool get canCreateAds     => type != PackType.starter;
  bool get canViewAnalytics => type != PackType.starter;
  bool get hasAdvancedStats => type == PackType.pro || type == PackType.lincooPlus || type == PackType.business;
  bool get hasPremiumBadge  => type == PackType.pro || type == PackType.business || type == PackType.lincooPlus;
  bool get hasPriority      => type == PackType.pro || type == PackType.business || type == PackType.lincooPlus;
  bool get hasIATools       => type == PackType.pro || type == PackType.business || type == PackType.lincooPlus;
}

// ─────────────────────────────────────────────────────────────────────────────

class PackService {
  PackService._();
  static final instance = PackService._();

  SellerPack? _pack;
  bool        _loaded = false;

  /// Loads (or returns cached) the seller's current best pack.
  Future<SellerPack?> load(String sellerId, {bool refresh = false}) async {
    if (_loaded && !refresh) return _pack;
    try {
      final rows = await Supabase.instance.client
          .from('seller_packs')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(5);

      final list = (rows as List)
          .map((r) => SellerPack.fromMap(r as Map<String, dynamic>))
          .toList();

      // Priority: active > paid > pending_payment
      SellerPack? best;
      for (final p in list) {
        if (p.isActive)            { best = p; break; }
        if (p.isPaid && best == null) best = p;
        if (p.isPendingPayment && best == null) best = p;
      }
      _pack   = best;
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
    return _pack;
  }

  void clear() {
    _pack   = null;
    _loaded = false;
  }

  SellerPack? get current => _pack;
  bool get hasPack      => _pack?.isActive == true;
  bool get hasPending   => _pack?.isPendingPayment == true || _pack?.isPaid == true;
}
