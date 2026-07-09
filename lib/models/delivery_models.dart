// =============================================================================
// Lincoo Smart Delivery — Models
// =============================================================================

// ── Delivery Partner ──────────────────────────────────────────────────────────

class DeliveryPartner {
  final String  id;
  final String  name;
  final String  code;
  final String? logoUrl;
  final bool    isActive;
  final bool    supportsSmart;
  final bool    supportsExpress;
  final bool    supportsPickup;
  final bool    supportsDropoff;
  final DateTime? lastSyncAt;

  const DeliveryPartner({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    this.isActive = true,
    this.supportsSmart = false,
    this.supportsExpress = false,
    this.supportsPickup = true,
    this.supportsDropoff = false,
    this.lastSyncAt,
  });

  factory DeliveryPartner.fromMap(Map<String, dynamic> m) => DeliveryPartner(
    id:              m['id'] as String,
    name:            m['name'] as String,
    code:            m['code'] as String,
    logoUrl:         m['logo_url'] as String?,
    isActive:        m['is_active'] as bool? ?? true,
    supportsSmart:   m['supports_smart'] as bool? ?? false,
    supportsExpress: m['supports_express'] as bool? ?? false,
    supportsPickup:  m['supports_pickup'] as bool? ?? true,
    supportsDropoff: m['supports_dropoff'] as bool? ?? false,
    lastSyncAt:      m['last_sync_at'] != null
        ? DateTime.tryParse(m['last_sync_at'] as String) : null,
  );
}

// ── Delivery Rule ─────────────────────────────────────────────────────────────

class DeliveryRule {
  final String ruleKey;
  final dynamic ruleValue;
  final String? description;
  final String  category;

  const DeliveryRule({
    required this.ruleKey,
    required this.ruleValue,
    this.description,
    this.category = 'global',
  });

  factory DeliveryRule.fromMap(Map<String, dynamic> m) => DeliveryRule(
    ruleKey:     m['rule_key'] as String,
    ruleValue:   m['rule_value'],
    description: m['description'] as String?,
    category:    m['category'] as String? ?? 'global',
  );

  int    get asInt    => int.tryParse(ruleValue.toString()) ?? 0;
  double get asDouble => double.tryParse(ruleValue.toString()) ?? 0.0;
  String get asString => ruleValue.toString();
}

// ── Smart Delivery Request ────────────────────────────────────────────────────

enum SmartDeliveryRequestStatus { pending, approved, rejected, suspended }

class SmartDeliveryRequest {
  final String   id;
  final String   sellerId;
  final String?  storeName;
  final SmartDeliveryRequestStatus status;
  final bool     contractSigned;
  final String?  adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const SmartDeliveryRequest({
    required this.id,
    required this.sellerId,
    this.storeName,
    required this.status,
    this.contractSigned = false,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory SmartDeliveryRequest.fromMap(Map<String, dynamic> m) =>
    SmartDeliveryRequest(
      id:             m['id'] as String,
      sellerId:       m['seller_id'] as String,
      storeName:      m['store_name'] as String?,
      status:         SmartDeliveryRequestStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String? ?? 'pending'),
        orElse: () => SmartDeliveryRequestStatus.pending,
      ),
      contractSigned: m['contract_signed'] as bool? ?? false,
      adminNote:      m['admin_note'] as String?,
      createdAt:      DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      reviewedAt:     m['reviewed_at'] != null
          ? DateTime.tryParse(m['reviewed_at'] as String) : null,
    );
}

// ── Seller Delivery Settings ──────────────────────────────────────────────────

class SellerDeliverySettings {
  final String  id;
  final String  sellerId;
  final int?    wilayaCode;
  final String? wilayaName;
  final String? commune;
  final String? address;
  final String? pickupAddress;
  final int     avgPrepHours;
  final double  maxWeightKg;
  final bool    isPickupEnabled;
  final bool    isDropoffEnabled;

  const SellerDeliverySettings({
    required this.id,
    required this.sellerId,
    this.wilayaCode,
    this.wilayaName,
    this.commune,
    this.address,
    this.pickupAddress,
    this.avgPrepHours = 24,
    this.maxWeightKg = 30,
    this.isPickupEnabled = true,
    this.isDropoffEnabled = false,
  });

  factory SellerDeliverySettings.fromMap(Map<String, dynamic> m) =>
    SellerDeliverySettings(
      id:               m['id'] as String,
      sellerId:         m['seller_id'] as String,
      wilayaCode:       m['wilaya_code'] as int?,
      wilayaName:       m['wilaya_name'] as String?,
      commune:          m['commune'] as String?,
      address:          m['address'] as String?,
      pickupAddress:    m['pickup_address'] as String?,
      avgPrepHours:     m['avg_prep_hours'] as int? ?? 24,
      maxWeightKg:      (m['max_weight_kg'] as num?)?.toDouble() ?? 30.0,
      isPickupEnabled:  m['is_pickup_enabled'] as bool? ?? true,
      isDropoffEnabled: m['is_dropoff_enabled'] as bool? ?? false,
    );
}

// ── Smart Delivery Group ──────────────────────────────────────────────────────

enum SmartGroupStatus {
  pendingConfirmation, confirmed, inPreparation,
  pickedUp, inTransit, delivered, cancelled, disputed
}

extension SmartGroupStatusExt on SmartGroupStatus {
  String get dbValue => const {
    SmartGroupStatus.pendingConfirmation: 'pending_confirmation',
    SmartGroupStatus.confirmed:           'confirmed',
    SmartGroupStatus.inPreparation:       'in_preparation',
    SmartGroupStatus.pickedUp:            'picked_up',
    SmartGroupStatus.inTransit:           'in_transit',
    SmartGroupStatus.delivered:           'delivered',
    SmartGroupStatus.cancelled:           'cancelled',
    SmartGroupStatus.disputed:            'disputed',
  }[this]!;

  String get label => const {
    SmartGroupStatus.pendingConfirmation: 'En attente confirmation',
    SmartGroupStatus.confirmed:           'Confirmé',
    SmartGroupStatus.inPreparation:       'En préparation',
    SmartGroupStatus.pickedUp:            'Récupéré',
    SmartGroupStatus.inTransit:           'En transit',
    SmartGroupStatus.delivered:           'Livré',
    SmartGroupStatus.cancelled:           'Annulé',
    SmartGroupStatus.disputed:            'Litige',
  }[this]!;
}

class SmartDeliveryGroup {
  final String   id;
  final String   groupCode;
  final String   buyerId;
  final SmartGroupStatus status;
  final String   deliveryType;
  final int      totalSellers;
  final int      totalProducts;
  final double?  totalWeightKg;
  final int      totalPriceDzd;
  final int      deliveryFeeDzd;
  final int      savingsDzd;
  final String?  trackingNumber;
  final DateTime? expiresAt;
  final DateTime? estimatedDeliveryAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final String?  buyerAddress;
  final String?  buyerPhone;
  final DateTime createdAt;

  const SmartDeliveryGroup({
    required this.id,
    required this.groupCode,
    required this.buyerId,
    required this.status,
    this.deliveryType = 'smart',
    this.totalSellers = 0,
    this.totalProducts = 0,
    this.totalWeightKg,
    this.totalPriceDzd = 0,
    this.deliveryFeeDzd = 0,
    this.savingsDzd = 0,
    this.trackingNumber,
    this.expiresAt,
    this.estimatedDeliveryAt,
    this.confirmedAt,
    this.deliveredAt,
    this.buyerAddress,
    this.buyerPhone,
    required this.createdAt,
  });

  factory SmartDeliveryGroup.fromMap(Map<String, dynamic> m) =>
    SmartDeliveryGroup(
      id:                  m['id'] as String,
      groupCode:           m['group_code'] as String,
      buyerId:             m['buyer_id'] as String,
      status:              SmartGroupStatus.values.firstWhere(
        (s) => s.dbValue == (m['status'] as String? ?? 'pending_confirmation'),
        orElse: () => SmartGroupStatus.pendingConfirmation,
      ),
      deliveryType:        m['delivery_type'] as String? ?? 'smart',
      totalSellers:        m['total_sellers'] as int? ?? 0,
      totalProducts:       m['total_products'] as int? ?? 0,
      totalWeightKg:       (m['total_weight_kg'] as num?)?.toDouble(),
      totalPriceDzd:       m['total_price_dzd'] as int? ?? 0,
      deliveryFeeDzd:      m['delivery_fee_dzd'] as int? ?? 0,
      savingsDzd:          m['savings_dzd'] as int? ?? 0,
      trackingNumber:      m['tracking_number'] as String?,
      expiresAt:           m['expires_at'] != null ? DateTime.tryParse(m['expires_at'] as String) : null,
      estimatedDeliveryAt: m['estimated_delivery_at'] != null ? DateTime.tryParse(m['estimated_delivery_at'] as String) : null,
      confirmedAt:         m['confirmed_at'] != null ? DateTime.tryParse(m['confirmed_at'] as String) : null,
      deliveredAt:         m['delivered_at'] != null ? DateTime.tryParse(m['delivered_at'] as String) : null,
      buyerAddress:        m['buyer_address'] as String?,
      buyerPhone:          m['buyer_phone'] as String?,
      createdAt:           DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
}

// ── Smart Delivery Item ───────────────────────────────────────────────────────

enum SmartItemStatus { pending, confirmed, rejected, prepared, pickedUp, cancelled }

extension SmartItemStatusExt on SmartItemStatus {
  String get dbValue => const {
    SmartItemStatus.pending:   'pending',
    SmartItemStatus.confirmed: 'confirmed',
    SmartItemStatus.rejected:  'rejected',
    SmartItemStatus.prepared:  'prepared',
    SmartItemStatus.pickedUp:  'picked_up',
    SmartItemStatus.cancelled: 'cancelled',
  }[this]!;

  String get label => const {
    SmartItemStatus.pending:   'En attente',
    SmartItemStatus.confirmed: 'Confirmé',
    SmartItemStatus.rejected:  'Refusé',
    SmartItemStatus.prepared:  'Préparé',
    SmartItemStatus.pickedUp:  'Récupéré',
    SmartItemStatus.cancelled: 'Annulé',
  }[this]!;
}

class SmartDeliveryItem {
  final String   id;
  final String   groupId;
  final String   sellerId;
  final String?  storeName;
  final SmartItemStatus status;
  final List<Map<String, dynamic>> products;
  final int      subtotalDzd;
  final double?  weightKg;
  final String?  rejectionReason;
  final String?  prepNotes;
  final DateTime? confirmedAt;
  final DateTime? preparedAt;
  final DateTime createdAt;

  const SmartDeliveryItem({
    required this.id,
    required this.groupId,
    required this.sellerId,
    this.storeName,
    required this.status,
    this.products = const [],
    this.subtotalDzd = 0,
    this.weightKg,
    this.rejectionReason,
    this.prepNotes,
    this.confirmedAt,
    this.preparedAt,
    required this.createdAt,
  });

  factory SmartDeliveryItem.fromMap(Map<String, dynamic> m) => SmartDeliveryItem(
    id:              m['id'] as String,
    groupId:         m['group_id'] as String,
    sellerId:        m['seller_id'] as String,
    storeName:       m['store_name'] as String?,
    status:          SmartItemStatus.values.firstWhere(
      (s) => s.dbValue == (m['status'] as String? ?? 'pending'),
      orElse: () => SmartItemStatus.pending,
    ),
    products:        List<Map<String, dynamic>>.from(
        (m['products'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map))),
    subtotalDzd:     m['subtotal_dzd'] as int? ?? 0,
    weightKg:        (m['weight_kg'] as num?)?.toDouble(),
    rejectionReason: m['rejection_reason'] as String?,
    prepNotes:       m['prep_notes'] as String?,
    confirmedAt:     m['confirmed_at'] != null ? DateTime.tryParse(m['confirmed_at'] as String) : null,
    preparedAt:      m['prepared_at'] != null ? DateTime.tryParse(m['prepared_at'] as String) : null,
    createdAt:       DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

// ── Pickup Request ────────────────────────────────────────────────────────────

enum PickupStatus { scheduled, confirmed, driverAssigned, enRoute, completed, failed, cancelled }

extension PickupStatusExt on PickupStatus {
  String get dbValue => const {
    PickupStatus.scheduled:       'scheduled',
    PickupStatus.confirmed:       'confirmed',
    PickupStatus.driverAssigned:  'driver_assigned',
    PickupStatus.enRoute:         'en_route',
    PickupStatus.completed:       'completed',
    PickupStatus.failed:          'failed',
    PickupStatus.cancelled:       'cancelled',
  }[this]!;

  String get label => const {
    PickupStatus.scheduled:       'Planifié',
    PickupStatus.confirmed:       'Confirmé',
    PickupStatus.driverAssigned:  'Livreur assigné',
    PickupStatus.enRoute:         'En route',
    PickupStatus.completed:       'Complété',
    PickupStatus.failed:          'Échoué',
    PickupStatus.cancelled:       'Annulé',
  }[this]!;
}

class PickupRequest {
  final String   id;
  final String   sellerId;
  final PickupStatus status;
  final DateTime pickupDate;
  final String   pickupFrom;
  final String   pickupTo;
  final String   address;
  final String?  wilayaName;
  final String?  commune;
  final String?  driverName;
  final String?  driverPhone;
  final int      packagesCount;
  final DateTime createdAt;

  const PickupRequest({
    required this.id,
    required this.sellerId,
    required this.status,
    required this.pickupDate,
    required this.pickupFrom,
    required this.pickupTo,
    required this.address,
    this.wilayaName,
    this.commune,
    this.driverName,
    this.driverPhone,
    this.packagesCount = 1,
    required this.createdAt,
  });

  factory PickupRequest.fromMap(Map<String, dynamic> m) => PickupRequest(
    id:            m['id'] as String,
    sellerId:      m['seller_id'] as String,
    status:        PickupStatus.values.firstWhere(
      (s) => s.dbValue == (m['status'] as String? ?? 'scheduled'),
      orElse: () => PickupStatus.scheduled,
    ),
    pickupDate:    DateTime.tryParse(m['pickup_date'] as String? ?? '') ?? DateTime.now(),
    pickupFrom:    m['pickup_from'] as String? ?? '09:00',
    pickupTo:      m['pickup_to'] as String? ?? '18:00',
    address:       m['address'] as String? ?? '',
    wilayaName:    m['wilaya_name'] as String?,
    commune:       m['commune'] as String?,
    driverName:    m['driver_name'] as String?,
    driverPhone:   m['driver_phone'] as String?,
    packagesCount: m['packages_count'] as int? ?? 1,
    createdAt:     DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

// ── Shipping Label ────────────────────────────────────────────────────────────

class ShippingLabel {
  final String  id;
  final String  sellerId;
  final String  trackingNumber;
  final String? barcode;
  final String? labelUrl;
  final String? groupId;
  final DateTime? printedAt;
  final DateTime  createdAt;

  const ShippingLabel({
    required this.id,
    required this.sellerId,
    required this.trackingNumber,
    this.barcode,
    this.labelUrl,
    this.groupId,
    this.printedAt,
    required this.createdAt,
  });

  factory ShippingLabel.fromMap(Map<String, dynamic> m) => ShippingLabel(
    id:             m['id'] as String,
    sellerId:       m['seller_id'] as String,
    trackingNumber: m['tracking_number'] as String,
    barcode:        m['barcode'] as String?,
    labelUrl:       m['label_url'] as String?,
    groupId:        m['group_id'] as String?,
    printedAt:      m['printed_at'] != null ? DateTime.tryParse(m['printed_at'] as String) : null,
    createdAt:      DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

// ── Fulfillment Item ──────────────────────────────────────────────────────────

class FulfillmentInventoryItem {
  final String  id;
  final String  centerId;
  final String  sellerId;
  final String  productName;
  final String? sku;
  final int     quantityStored;
  final int     quantityReserved;
  final int     quantityShipped;
  final double? weightKg;
  final DateTime enteredAt;

  const FulfillmentInventoryItem({
    required this.id,
    required this.centerId,
    required this.sellerId,
    required this.productName,
    this.sku,
    this.quantityStored = 0,
    this.quantityReserved = 0,
    this.quantityShipped = 0,
    this.weightKg,
    required this.enteredAt,
  });

  int get quantityAvailable => quantityStored - quantityReserved;

  factory FulfillmentInventoryItem.fromMap(Map<String, dynamic> m) =>
    FulfillmentInventoryItem(
      id:                m['id'] as String,
      centerId:          m['center_id'] as String,
      sellerId:          m['seller_id'] as String,
      productName:       m['product_name'] as String,
      sku:               m['sku'] as String?,
      quantityStored:    m['quantity_stored'] as int? ?? 0,
      quantityReserved:  m['quantity_reserved'] as int? ?? 0,
      quantityShipped:   m['quantity_shipped'] as int? ?? 0,
      weightKg:          (m['weight_kg'] as num?)?.toDouble(),
      enteredAt:         DateTime.tryParse(m['entered_at'] as String? ?? '') ?? DateTime.now(),
    );
}
