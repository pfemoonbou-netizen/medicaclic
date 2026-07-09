import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_models.dart';

// =============================================================================
// Lincoo Smart Delivery Service
// =============================================================================

class DeliveryService {
  DeliveryService._();
  static final instance = DeliveryService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── Rule Engine ─────────────────────────────────────────────────────────────

  final Map<String, DeliveryRule> _rulesCache = {};

  Future<Map<String, DeliveryRule>> loadRules() async {
    try {
      final rows = await _db.from('delivery_rules').select();
      _rulesCache.clear();
      for (final r in rows) {
        final rule = DeliveryRule.fromMap(r);
        _rulesCache[rule.ruleKey] = rule;
      }
    } catch (_) {}
    return _rulesCache;
  }

  DeliveryRule? rule(String key) => _rulesCache[key];
  int    ruleInt(String key, int    fallback) => rule(key)?.asInt    ?? fallback;
  double ruleDbl(String key, double fallback) => rule(key)?.asDouble ?? fallback;

  Future<void> updateRule(String key, dynamic value) async {
    await _db.from('delivery_rules').update({
      'rule_value': value.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('rule_key', key);
    if (_rulesCache.containsKey(key)) {
      _rulesCache[key] = DeliveryRule(ruleKey: key, ruleValue: value);
    }
  }

  // ── Delivery Partners ────────────────────────────────────────────────────────

  Future<List<DeliveryPartner>> loadPartners() async {
    final rows = await _db.from('delivery_partners').select().order('name');
    return rows.map((r) => DeliveryPartner.fromMap(r)).toList();
  }

  // ── Smart Delivery Request ───────────────────────────────────────────────────

  Future<SmartDeliveryRequest?> mySmartRequest(String sellerId) async {
    final row = await _db
        .from('seller_smart_delivery_requests')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row != null ? SmartDeliveryRequest.fromMap(row) : null;
  }

  Future<void> submitSmartRequest({
    required String sellerId,
    required String storeName,
    required bool contractSigned,
  }) async {
    final existing = await mySmartRequest(sellerId);
    if (existing != null && existing.status == SmartDeliveryRequestStatus.pending) return;

    await _db.from('seller_smart_delivery_requests').insert({
      'seller_id':       sellerId,
      'store_name':      storeName,
      'contract_signed': contractSigned,
      'status':          'pending',
    });
  }

  // ── Seller Delivery Settings ──────────────────────────────────────────────────

  Future<SellerDeliverySettings?> mySettings(String sellerId) async {
    final row = await _db
        .from('seller_delivery_settings')
        .select()
        .eq('seller_id', sellerId)
        .maybeSingle();
    return row != null ? SellerDeliverySettings.fromMap(row) : null;
  }

  Future<void> saveSettings({
    required String sellerId,
    int?    wilayaCode,
    String? wilayaName,
    String? commune,
    String? address,
    String? pickupAddress,
    int?    avgPrepHours,
    double? maxWeightKg,
    bool?   isPickupEnabled,
    bool?   isDropoffEnabled,
  }) async {
    final payload = {
      'seller_id':          sellerId,
      if (wilayaCode    != null) 'wilaya_code':        wilayaCode,
      if (wilayaName    != null) 'wilaya_name':        wilayaName,
      if (commune       != null) 'commune':            commune,
      if (address       != null) 'address':            address,
      if (pickupAddress != null) 'pickup_address':     pickupAddress,
      if (avgPrepHours  != null) 'avg_prep_hours':     avgPrepHours,
      if (maxWeightKg   != null) 'max_weight_kg':      maxWeightKg,
      if (isPickupEnabled  != null) 'is_pickup_enabled':  isPickupEnabled,
      if (isDropoffEnabled != null) 'is_dropoff_enabled': isDropoffEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _db.from('seller_delivery_settings').upsert(payload, onConflict: 'seller_id');
  }

  // ── Smart Orders (items assigned to this seller) ──────────────────────────────

  Future<List<SmartDeliveryItem>> mySmartItems(String sellerId, {String? statusFilter}) async {
    var query = _db
        .from('smart_delivery_items')
        .select('*, smart_delivery_groups(group_code, status, buyer_id, expires_at, buyer_address, buyer_phone, delivery_type)')
        .eq('seller_id', sellerId);
    if (statusFilter != null) query = query.eq('status', statusFilter);
    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => SmartDeliveryItem.fromMap(r)).toList();
  }

  Future<void> confirmItem(String itemId) async {
    await _db.from('smart_delivery_items').update({
      'status':       'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
      'updated_at':   DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  Future<void> rejectItem(String itemId, String reason) async {
    await _db.from('smart_delivery_items').update({
      'status':           'rejected',
      'rejected_at':      DateTime.now().toIso8601String(),
      'rejection_reason': reason,
      'updated_at':       DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  Future<void> markPrepared(String itemId, {String? note}) async {
    await _db.from('smart_delivery_items').update({
      'status':      'prepared',
      'prepared_at': DateTime.now().toIso8601String(),
      'prep_notes':  note,
      'updated_at':  DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  // ── Pickup Requests ──────────────────────────────────────────────────────────

  Future<List<PickupRequest>> myPickups(String sellerId) async {
    final rows = await _db
        .from('pickup_requests')
        .select()
        .eq('seller_id', sellerId)
        .order('pickup_date', ascending: false);
    return rows.map((r) => PickupRequest.fromMap(r)).toList();
  }

  Future<void> schedulePickup({
    required String sellerId,
    required DateTime date,
    required String fromTime,
    required String toTime,
    required String address,
    String?  wilayaName,
    String?  commune,
    int      packagesCount = 1,
    String?  notes,
  }) async {
    await _db.from('pickup_requests').insert({
      'seller_id':      sellerId,
      'pickup_date':    date.toIso8601String().substring(0, 10),
      'pickup_from':    fromTime,
      'pickup_to':      toTime,
      'address':        address,
      'wilaya_name':    wilayaName,
      'commune':        commune,
      'packages_count': packagesCount,
      'notes':          notes,
      'status':         'scheduled',
    });
  }

  Future<void> cancelPickup(String pickupId) async {
    await _db.from('pickup_requests').update({
      'status':     'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', pickupId);
  }

  // ── Shipping Labels ───────────────────────────────────────────────────────────

  Future<List<ShippingLabel>> myLabels(String sellerId) async {
    final rows = await _db
        .from('shipping_labels')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((r) => ShippingLabel.fromMap(r)).toList();
  }

  Future<ShippingLabel> generateLabel({
    required String sellerId,
    String?  groupId,
    String?  itemId,
  }) async {
    final tracking = _generateTrackingNumber();
    final row = await _db.from('shipping_labels').insert({
      'seller_id':       sellerId,
      'group_id':        groupId,
      'item_id':         itemId,
      'tracking_number': tracking,
      'barcode':         tracking,
      'qr_data': {
        'tracking': tracking,
        'seller':   sellerId,
        'ts':       DateTime.now().millisecondsSinceEpoch,
      },
    }).select().single();
    return ShippingLabel.fromMap(row);
  }

  Future<void> markLabelPrinted(String labelId) async {
    await _db.from('shipping_labels').update({
      'printed_at': DateTime.now().toIso8601String(),
    }).eq('id', labelId);
  }

  // ── Fulfillment ──────────────────────────────────────────────────────────────

  Future<List<FulfillmentInventoryItem>> myInventory(String sellerId) async {
    final rows = await _db
        .from('fulfillment_inventory')
        .select()
        .eq('seller_id', sellerId)
        .order('product_name');
    return rows.map((r) => FulfillmentInventoryItem.fromMap(r)).toList();
  }

  // ── Analytics ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> myDeliveryStats(String sellerId) async {
    try {
      final items = await _db
          .from('smart_delivery_items')
          .select('status, created_at')
          .eq('seller_id', sellerId);

      final total      = items.length;
      final confirmed  = items.where((i) => i['status'] == 'confirmed').length;
      final rejected   = items.where((i) => i['status'] == 'rejected').length;
      final prepared   = items.where((i) => i['status'] == 'prepared' || i['status'] == 'picked_up').length;
      final pending    = items.where((i) => i['status'] == 'pending').length;

      final pickups = await _db
          .from('pickup_requests')
          .select('status')
          .eq('seller_id', sellerId);

      final pickupsCompleted = pickups.where((p) => p['status'] == 'completed').length;

      return {
        'total':           total,
        'confirmed':       confirmed,
        'rejected':        rejected,
        'prepared':        prepared,
        'pending':         pending,
        'pickupsTotal':    pickups.length,
        'pickupsCompleted': pickupsCompleted,
        'confirmationRate': total > 0 ? ((confirmed + prepared) / total * 100).round() : 0,
      };
    } catch (_) {
      return {'total': 0, 'confirmed': 0, 'rejected': 0, 'prepared': 0, 'pending': 0};
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────────────

  Future<List<SmartDeliveryRequest>> allSmartRequests({String? status}) async {
    var query = _db.from('seller_smart_delivery_requests').select(
      '*, profiles!seller_id(full_name, email)',
    );
    if (status != null) query = query.eq('status', status);
    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => SmartDeliveryRequest.fromMap(r)).toList();
  }

  Future<void> approveSmartRequest(String requestId, String reviewerId) async {
    await _db.from('seller_smart_delivery_requests').update({
      'status':      'approved',
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'updated_at':  DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> rejectSmartRequest(String requestId, String reviewerId, String note) async {
    await _db.from('seller_smart_delivery_requests').update({
      'status':      'rejected',
      'admin_note':  note,
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'updated_at':  DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<List<Map<String, dynamic>>> allGroups({String? status}) async {
    var q = _db.from('smart_delivery_groups')
        .select('*, profiles!buyer_id(full_name, email)');
    if (status != null) q = q.eq('status', status);
    return (await q.order('created_at', ascending: false)).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> allPickupRequests({String? status}) async {
    var q = _db.from('pickup_requests')
        .select('*, profiles!seller_id(full_name, email)');
    if (status != null) q = q.eq('status', status);
    return (await q.order('pickup_date', ascending: false)).cast<Map<String, dynamic>>();
  }

  Future<Map<String, int>> adminDeliveryStats() async {
    try {
      final groups   = await _db.from('smart_delivery_groups').select('status');
      final requests = await _db.from('seller_smart_delivery_requests').select('status');
      final pickups  = await _db.from('pickup_requests').select('status');

      return {
        'groups_total':     groups.length,
        'groups_pending':   groups.where((g) => g['status'] == 'pending_confirmation').length,
        'groups_delivered': groups.where((g) => g['status'] == 'delivered').length,
        'requests_pending': requests.where((r) => r['status'] == 'pending').length,
        'requests_approved':requests.where((r) => r['status'] == 'approved').length,
        'pickups_pending':  pickups.where((p) => p['status'] == 'scheduled').length,
        'pickups_done':     pickups.where((p) => p['status'] == 'completed').length,
      };
    } catch (_) {
      return {};
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _generateTrackingNumber() {
    final now = DateTime.now();
    final rand = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'LNC${now.year}${now.month.toString().padLeft(2,'0')}$rand';
  }
}
