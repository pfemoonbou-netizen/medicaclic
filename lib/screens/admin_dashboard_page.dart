import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── palette ─────────────────────────────────────────────────────────────────
const _bg     = Color(0xFF07080F);
const _card   = Color(0xFF0E1020);
const _border = Color(0xFF1A1D30);
const _accent = Color(0xFF3D8BFF);
const _green  = Color(0xFF06EFC5);
const _red    = Color(0xFFEF4444);
const _gold   = Color(0xFFFFB800);
const _purp   = Color(0xFF8B5CF6);

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {

  bool    _loading  = true;
  bool    _isAdmin  = false;
  String? _error;
  int     _section  = 0; // 0=overview 1=comptes 2=contenu 3=creators 4=paiements 5=packs 6=delivery

  // ── Overview stats ────────────────────────────────────────────────────────
  int _statUsers    = 0;
  int _statSellers  = 0;
  int _statCreators = 0;
  int _statPosts    = 0;
  int _statReels    = 0;
  int _statPending  = 0;
  int _statContent  = 0; // flagged content

  // ── Comptes ───────────────────────────────────────────────────────────────
  late TabController _accountTabs;
  List<_UserRow> _accPending  = [];
  List<_UserRow> _accVerified = [];
  List<_UserRow> _accRejected = [];

  // ── Contenu ───────────────────────────────────────────────────────────────
  List<_PostRow> _posts        = [];
  bool           _postsLoading = false;
  String         _postFilter   = 'all'; // all | reel | classic | rejected

  // ── Creators ─────────────────────────────────────────────────────────────
  List<_UserRow> _crPending  = [];
  List<_UserRow> _crVerified = [];
  late TabController _crTabs;

  // ── Paiements & Reçus ────────────────────────────────────────────────────
  List<_AdRow> _adsPending  = [];
  List<_AdRow> _adsApproved = [];
  List<_AdRow> _adsRejected = [];
  bool         _adsLoading  = false;
  late TabController _adTabs;

  // ── Packs vendeurs ────────────────────────────────────────────────────────
  List<_PackRow> _packsPending   = [];
  List<_PackRow> _packsActive    = [];
  List<_PackRow> _packsCancelled = [];
  bool           _packsLoading   = false;
  late TabController _packTabs;

  // ── Delivery Management ───────────────────────────────────────────────────
  List<Map<String,dynamic>> _delivSmartReqs  = [];
  List<Map<String,dynamic>> _delivPickups    = [];
  List<Map<String,dynamic>> _delivGroups     = [];
  bool                      _delivLoading    = false;
  late TabController         _delivTabs;

  @override
  void initState() {
    super.initState();
    _accountTabs = TabController(length: 3, vsync: this);
    _crTabs      = TabController(length: 2, vsync: this);
    _adTabs      = TabController(length: 3, vsync: this);
    _packTabs    = TabController(length: 3, vsync: this);
    _delivTabs   = TabController(length: 3, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _accountTabs.dispose();
    _crTabs.dispose();
    _adTabs.dispose();
    _packTabs.dispose();
    _delivTabs.dispose();
    super.dispose();
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────
  Future<void> _checkAdmin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) { setState(() { _isAdmin = false; _loading = false; }); return; }
      final p = await Supabase.instance.client
          .from('profiles').select('is_admin').eq('id', user.id).maybeSingle();
      if (p?['is_admin'] != true) {
        setState(() { _isAdmin = false; _loading = false; }); return;
      }
      _isAdmin = true;
      await Future.wait([_loadAccounts(), _loadStats(), _loadContent(), _loadCreators(), _loadAds(), _loadPacks(), _loadDelivery()]);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ─── Data loaders ─────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    final c = Supabase.instance.client;
    try {
      final users    = await c.from('profiles').select('id').neq('pro_role','none');
      final sellers  = await c.from('profiles').select('id').eq('pro_role','seller');
      final creators = await c.from('profiles').select('id').eq('pro_role','creator');
      final posts    = await c.from('store_posts').select('id').eq('post_type','classic');
      final reels    = await c.from('store_posts').select('id').eq('post_type','reel');
      final pending  = await c.from('profiles').select('id').eq('pro_status','pending');
      final flagged  = await c.from('store_posts').select('id').eq('moderation_status','rejected');
      if (mounted) {
        setState(() {
        _statUsers    = (users    as List).length;
        _statSellers  = (sellers  as List).length;
        _statCreators = (creators as List).length;
        _statPosts    = (posts    as List).length;
        _statReels    = (reels    as List).length;
        _statPending  = (pending  as List).length;
        _statContent  = (flagged  as List).length;
      });
      }
    } catch (_) {}
  }

  Future<void> _loadAccounts() async {
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .neq('pro_status', 'none')
          .inFilter('pro_role', ['seller','company','buyer'])
          .order('created_at', ascending: false);
      final all = (rows as List).map((m) => _UserRow.fromMap(m)).toList();
      if (mounted) {
        setState(() {
        _accPending  = all.where((u) => u.status == 'pending').toList();
        _accVerified = all.where((u) => u.status == 'verified').toList();
        _accRejected = all.where((u) => u.status == 'rejected').toList();
      });
      }
    } catch (_) {}
  }

  Future<void> _loadContent() async {
    setState(() => _postsLoading = true);
    try {
      final rows = await Supabase.instance.client
          .from('store_posts')
          .select('id, caption, media_url, post_type, moderation_status, moderation_note, created_at, store_id')
          .inFilter('post_type', ['reel','classic','commercial'])
          .order('created_at', ascending: false)
          .limit(80);

      // fetch store names in one query
      final storeIds = (rows as List)
          .map((r) => r['store_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> storeMap = {};
      if (storeIds.isNotEmpty) {
        final stores = await Supabase.instance.client
            .from('stores')
            .select('id, store_name, user_id, profiles(full_name, pro_role)')
            .inFilter('id', storeIds);
        for (final s in stores as List) {
          storeMap[s['id'] as String] = s as Map<String, dynamic>;
        }
      }

      if (mounted) {
        setState(() {
        _posts = rows.map((r) {
          final store = storeMap[r['store_id'] as String? ?? ''];
          final profile = store?['profiles'] as Map<String, dynamic>?;
          return _PostRow(
            id:           r['id'] as String,
            storeId:      r['store_id'] as String? ?? '',
            storeName:    store?['store_name'] as String? ?? 'Boutique',
            authorName:   profile?['full_name'] as String? ?? 'Utilisateur',
            authorRole:   profile?['pro_role'] as String? ?? 'seller',
            caption:      r['caption'] as String? ?? '',
            mediaUrl:     r['media_url'] as String? ?? '',
            postType:     r['post_type'] as String? ?? 'classic',
            modStatus:    r['moderation_status'] as String? ?? 'approved',
            modNote:      r['moderation_note'] as String?,
            createdAt:    r['created_at'] != null
                ? DateTime.tryParse(r['created_at'] as String)
                : null,
          );
        }).toList();
        _postsLoading = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() => _postsLoading = false);
    }
  }

  Future<void> _loadAds() async {
    if (mounted) setState(() => _adsLoading = true);
    try {
      final rows = await Supabase.instance.client
          .from('ad_campaigns')
          .select('*, profiles!company_id(full_name, email, store_name, telephone)')
          .order('created_at', ascending: false);

      final all = await Future.wait(
        (rows as List).map((r) async {
          final profile = r['profiles'] as Map<String, dynamic>?;
          String? signedReceiptUrl;
          final rawPath = r['receipt_url'] as String?;
          if (rawPath != null && rawPath.isNotEmpty) {
            try {
              signedReceiptUrl = await Supabase.instance.client.storage
                  .from('ad-receipts')
                  .createSignedUrl(rawPath, 3600);
            } catch (_) {}
          }
          return _AdRow(
            id:              r['id'] as String,
            companyId:       r['company_id'] as String,
            advertiserName:  profile?['full_name'] as String? ?? 'Annonceur',
            advertiserEmail: profile?['email'] as String? ?? '',
            companyName:     profile?['store_name'] as String? ?? '',
            contact:         profile?['telephone'] as String? ?? '',
            title:           r['title'] as String,
            description:     r['description'] as String?,
            imageUrl:        r['image_url'] as String?,
            receiptStoragePath: rawPath,
            receiptSignedUrl:   signedReceiptUrl,
            paymentStatus:   r['payment_status'] as String? ?? 'pending',
            approvalStatus:  r['approval_status'] as String? ?? 'pending',
            paymentMethod:   r['payment_method'] as String? ?? '',
            budgetDZD:       (r['budget_dzd'] as num?)?.toInt() ?? 0,
            createdAt:       r['created_at'] != null
                ? DateTime.tryParse(r['created_at'] as String) : null,
            approvedAt:      r['approved_at'] != null
                ? DateTime.tryParse(r['approved_at'] as String) : null,
          );
        }),
      );

      if (mounted) {
        setState(() {
          _adsPending  = all.where((a) => a.approvalStatus == 'pending').toList();
          _adsApproved = all.where((a) => a.approvalStatus == 'approved').toList();
          _adsRejected = all.where((a) => a.approvalStatus == 'rejected').toList();
          _adsLoading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _adsLoading = false);
    }
  }

  Future<void> _loadCreators() async {
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('pro_role', 'creator')
          .order('created_at', ascending: false);
      final all = (rows as List).map((m) => _UserRow.fromMap(m)).toList();
      if (mounted) {
        setState(() {
        _crPending  = all.where((u) => u.status == 'pending').toList();
        _crVerified = all.where((u) => u.status == 'verified').toList();
      });
      }
    } catch (_) {}
  }

  // ─── Ad payment actions ───────────────────────────────────────────────────
  Future<void> _approveAd(_AdRow ad) async {
    final ok = await _confirmDialog(
      'Approuver le paiement ?',
      'La publicité "${ad.title}" sera publiée immédiatement sur le fil.',
    );
    if (!ok) return;
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('ad_campaigns').update({
        'payment_status':  'verified',
        'approval_status': 'approved',
        'status':          'active',
        'approved_at':     DateTime.now().toIso8601String(),
        'approved_by':     adminId,
      }).eq('id', ad.id);
      _tryNotify(ad.companyId, '✅ Publicité approuvée',
          'Votre annonce "${ad.title}" a été approuvée et est maintenant visible sur le fil.');
      _snack('✅ Paiement approuvé — annonce publiée', _green);
      await _loadAds();
    } catch (e) { _snack('Erreur : $e', _red); }
  }

  Future<void> _rejectAd(_AdRow ad) async {
    final reason = await _rejectDialog('le paiement de "${ad.title}"');
    if (reason == null) return;
    try {
      await Supabase.instance.client.from('ad_campaigns').update({
        'payment_status':  'rejected',
        'approval_status': 'rejected',
        'status':          'rejected',
      }).eq('id', ad.id);
      _tryNotify(ad.companyId, '❌ Publicité refusée',
          reason.isNotEmpty
              ? 'Votre annonce "${ad.title}" a été refusée. Raison : $reason'
              : 'Votre annonce "${ad.title}" a été refusée.');
      _snack('❌ Paiement rejeté', Colors.orange);
      await _loadAds();
    } catch (e) { _snack('Erreur : $e', _red); }
  }

  // ─── Account actions ──────────────────────────────────────────────────────
  Future<void> _approveAccount(_UserRow u) async {
    try {
      await Supabase.instance.client.from('profiles')
          .update({'pro_status': 'verified', 'onboarding_complete': true}).eq('id', u.id);
      _tryNotify(u.id, '✅ Compte approuvé',
          'Votre compte ${u.roleLabel} a été validé. Bienvenue sur Lincoo !');
      _snack('✅ ${u.name} approuvé', _green);
      await Future.wait([_loadAccounts(), _loadStats()]);
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  Future<void> _rejectAccount(_UserRow u) async {
    final reason = await _rejectDialog('le compte de ${u.name}');
    if (reason == null) return;
    try {
      await Supabase.instance.client.from('profiles')
          .update({'pro_status': 'rejected'}).eq('id', u.id);
      _tryNotify(u.id, 'Demande refusée',
          reason.isNotEmpty ? 'Refus: $reason' : 'Votre demande a été refusée.');
      _snack('❌ ${u.name} rejeté', Colors.orange);
      await Future.wait([_loadAccounts(), _loadStats()]);
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  // ─── Content actions ──────────────────────────────────────────────────────
  Future<void> _approvePost(_PostRow p) async {
    try {
      await Supabase.instance.client.from('store_posts')
          .update({'moderation_status': 'approved'}).eq('id', p.id);
      _snack('✅ Contenu approuvé', _green);
      await _loadContent();
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  Future<void> _rejectPost(_PostRow p) async {
    final reason = await _rejectDialog('ce contenu');
    if (reason == null) return;
    try {
      await Supabase.instance.client.from('store_posts').update({
        'moderation_status': 'rejected',
        'moderation_note': reason,
      }).eq('id', p.id);
      _snack('🚫 Contenu rejeté', Colors.orange);
      await _loadContent();
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  Future<void> _deletePost(_PostRow p) async {
    final ok = await _confirmDialog('Supprimer ce contenu ?',
        'Cette action est irréversible.');
    if (!ok) return;
    try {
      await Supabase.instance.client.from('store_posts').delete().eq('id', p.id);
      _snack('🗑️ Contenu supprimé', _red);
      await _loadContent();
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  // ─── Pack actions ────────────────────────────────────────────────────────
  Future<void> _loadPacks() async {
    if (mounted) setState(() => _packsLoading = true);
    try {
      final rows = await Supabase.instance.client
          .from('seller_packs')
          .select('*, profiles!seller_id(full_name, email)')
          .order('created_at', ascending: false);

      final all = (rows as List).map((r) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        return _PackRow(
          id:           r['id'] as String,
          sellerId:     r['seller_id'] as String,
          sellerName:   profile?['full_name'] as String? ?? 'Vendeur',
          sellerEmail:  profile?['email'] as String? ?? '',
          packType:     r['pack_type'] as String? ?? 'starter',
          status:       r['status'] as String? ?? 'pending_payment',
          priceDzd:     r['price_dzd'] as int? ?? 0,
          paymentRef:   r['payment_ref'] as String?,
          adminNote:    r['admin_note'] as String?,
          createdAt:    r['created_at'] != null
              ? DateTime.tryParse(r['created_at'] as String) : null,
          activatedAt:  r['activated_at'] != null
              ? DateTime.tryParse(r['activated_at'] as String) : null,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _packsPending   = all.where((p) => p.status == 'paid' || p.status == 'pending_payment').toList();
          _packsActive    = all.where((p) => p.status == 'active').toList();
          _packsCancelled = all.where((p) => p.status == 'cancelled' || p.status == 'expired').toList();
          _packsLoading   = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _packsLoading = false);
    }
  }

  // ─── Delivery loaders ────────────────────────────────────────────────────
  Future<void> _loadDelivery() async {
    if (mounted) setState(() => _delivLoading = true);
    final c = Supabase.instance.client;
    try {
      // seller_id references auth.users, not profiles → fetch profiles separately
      final rawReqs    = (await c.from('seller_smart_delivery_requests')
          .select('*').order('created_at', ascending: false).limit(50)) as List;
      final rawPickups = (await c.from('pickup_requests')
          .select('*').order('pickup_date', ascending: false).limit(50)) as List;
      final rawGroups  = (await c.from('smart_delivery_groups')
          .select('id, group_code, status, total_sellers, total_products, total_price_dzd, delivery_fee_dzd, savings_dzd, created_at, buyer_wilaya')
          .order('created_at', ascending: false).limit(50)) as List;

      // collect unique seller IDs, fetch profiles in one query
      final ids = <String>{};
      for (final r in rawReqs)    { final id = r['seller_id'] as String?; if (id != null) ids.add(id); }
      for (final p in rawPickups) { final id = p['seller_id'] as String?; if (id != null) ids.add(id); }

      Map<String, Map<String,dynamic>> profileMap = {};
      if (ids.isNotEmpty) {
        final profs = await c.from('profiles').select('id, full_name, email').inFilter('id', ids.toList());
        for (final p in profs as List) {
          profileMap[p['id'] as String] = p as Map<String,dynamic>;
        }
      }

      if (mounted) {
        setState(() {
          _delivSmartReqs = rawReqs.cast<Map<String,dynamic>>().map((r) =>
              {...r, 'profiles': profileMap[r['seller_id']]}).toList();
          _delivPickups   = rawPickups.cast<Map<String,dynamic>>().map((p) =>
              {...p, 'profiles': profileMap[p['seller_id']]}).toList();
          _delivGroups    = rawGroups.cast<Map<String,dynamic>>();
          _delivLoading   = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _delivLoading = false);
    }
  }

  // ─── Delivery actions ─────────────────────────────────────────────────────
  Future<void> _approveSmartReq(String reqId, String sellerName) async {
    final ok = await _confirmDialog('Approuver Smart Delivery ?',
        '$sellerName sera activé sur le réseau Smart Delivery.');
    if (!ok) return;
    try {
      await Supabase.instance.client
          .from('seller_smart_delivery_requests')
          .update({'status': 'approved', 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('id', reqId);
      _snack('✅ Smart Delivery approuvé pour $sellerName', _green);
      await _loadDelivery();
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  Future<void> _rejectSmartReq(String reqId, String sellerName) async {
    final reason = await _rejectDialog('la demande Smart Delivery de $sellerName');
    if (reason == null) return;
    try {
      await Supabase.instance.client
          .from('seller_smart_delivery_requests')
          .update({'status': 'rejected', 'admin_note': reason, 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('id', reqId);
      _snack('❌ Demande rejetée', Colors.orange);
      await _loadDelivery();
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  Future<void> _approvePack(_PackRow pack) async {
    final ok = await _confirmDialog(
      'Activer le pack ${pack.packLabel} ?',
      'Le vendeur ${pack.sellerName} aura accès à toutes les fonctionnalités de ce pack.',
    );
    if (!ok) return;
    try {
      final now = DateTime.now();
      final expires = now.add(const Duration(days: 30));
      await Supabase.instance.client.from('seller_packs').update({
        'status':       'active',
        'activated_at': now.toIso8601String(),
        'expires_at':   expires.toIso8601String(),
        'admin_note':   null,
      }).eq('id', pack.id);
      _tryNotify(pack.sellerId,
          '🎉 Pack ${pack.packLabel} activé !',
          'Votre pack ${pack.packLabel} est maintenant actif. Toutes vos fonctionnalités sont débloquées !');
      _snack('✅ Pack ${pack.packLabel} activé pour ${pack.sellerName}', _green);
      await _loadPacks();
    } catch (e) { _snack('Erreur : $e', _red); }
  }

  Future<void> _rejectPack(_PackRow pack) async {
    final reason = await _rejectDialog('le pack de ${pack.sellerName}');
    if (reason == null) return;
    try {
      await Supabase.instance.client.from('seller_packs').update({
        'status':     'cancelled',
        'admin_note': reason.isNotEmpty ? reason : 'Paiement non confirmé',
      }).eq('id', pack.id);
      _tryNotify(pack.sellerId, '❌ Pack refusé',
          reason.isNotEmpty
              ? 'Votre demande de pack a été refusée. Raison : $reason'
              : 'Votre demande de pack a été refusée. Contactez le support.');
      _snack('❌ Pack refusé pour ${pack.sellerName}', Colors.orange);
      await _loadPacks();
    } catch (e) { _snack('Erreur : $e', _red); }
  }

  // ─── Creator actions ──────────────────────────────────────────────────────
  Future<void> _approveCreator(_UserRow u) async {
    try {
      await Supabase.instance.client.from('profiles').update({
        'pro_status': 'verified', 'onboarding_complete': true
      }).eq('id', u.id);

      // Create a store for the creator if they don't have one
      final existing = await Supabase.instance.client
          .from('stores').select('id').eq('user_id', u.id).maybeSingle();
      if (existing == null) {
        await Supabase.instance.client.from('stores').insert({
          'user_id': u.id,
          'store_name': u.name,
          'is_active': true,
        });
      }

      _tryNotify(u.id, '🎉 Tu es maintenant Lincoo Creator !',
          'Ton profil Creator a été validé. Commence à créer du contenu et gagner des XP !');
      _snack('✅ Creator ${u.name} approuvé', _green);
      await Future.wait([_loadCreators(), _loadStats()]);
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  Future<void> _rejectCreator(_UserRow u) async {
    final reason = await _rejectDialog('la demande creator de ${u.name}');
    if (reason == null) return;
    try {
      await Supabase.instance.client.from('profiles').update({
        'pro_status': 'rejected',
      }).eq('id', u.id);
      _tryNotify(u.id, 'Demande creator refusée',
          reason.isNotEmpty ? 'Raison: $reason' : 'Votre demande n\'a pas été acceptée.');
      _snack('❌ Creator ${u.name} rejeté', Colors.orange);
      await _loadCreators();
    } catch (e) { _snack('Erreur: $e', _red); }
  }

  void _tryNotify(String userId, String title, String msg) {
    Supabase.instance.client.from('notifications').insert({
      'user_id': userId, 'title': title, 'message': msg,
    }).catchError((_) {});
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
      backgroundColor: _bg,
      body: Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
    );
    }
    if (!_isAdmin) return _accessDenied();
    if (_error != null) {
      return Scaffold(
      backgroundColor: _bg,
      body: Center(child: Text(_error!, style: const TextStyle(color: _red))),
    );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        // ── Rail ──────────────────────────────────────────────────────
        _buildRail(),
        const VerticalDivider(width: 1, color: _border),
        // ── Content ───────────────────────────────────────────────────
        Expanded(child: _buildSection()),
      ]),
    );
  }

  Widget _buildRail() => Container(
    width: 72,
    color: _card,
    child: SafeArea(
      child: Column(children: [
        const SizedBox(height: 16),
        // Logo
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
              colors: [_accent, _purp]).createShader(r),
          child: const Text('L',
              style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 24),
        const Divider(color: _border, indent: 12, endIndent: 12),
        const SizedBox(height: 8),
        _railItem(0, Icons.dashboard_rounded,       'Overview'),
        _railItem(1, Icons.people_rounded,           'Comptes',
            badge: _statPending),
        _railItem(2, Icons.photo_library_rounded,    'Contenu',
            badge: _statContent),
        _railItem(3, Icons.auto_awesome_rounded,     'Creators',
            badge: _crPending.length),
        _railItem(4, Icons.receipt_long_rounded,     'Paiements',
            badge: _adsPending.length),
        _railItem(5, Icons.inventory_2_rounded,      'Packs',
            badge: _packsPending.length),
        _railItem(6, Icons.local_shipping_rounded,   'Delivery',
            badge: _delivSmartReqs.where((r) => r['status'] == 'pending').length),
        const Spacer(),
        _railItem(-1, Icons.refresh_rounded, 'Refresh',
            onTap: () async {
              setState(() => _loading = true);
              await Future.wait([_loadAccounts(), _loadStats(), _loadContent(), _loadCreators(), _loadAds(), _loadPacks(), _loadDelivery()]);
              setState(() => _loading = false);
            }),
        const SizedBox(height: 16),
      ]),
    ),
  );

  Widget _railItem(int idx, IconData icon, String label,
      {int badge = 0, VoidCallback? onTap}) {
    final sel = _section == idx;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _section = idx),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 48, height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: sel ? _accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: sel
                ? Border.all(color: _accent.withValues(alpha: 0.4))
                : null,
          ),
          child: Icon(icon,
              color: sel ? _accent : Colors.white30, size: 22),
        ),
        if (badge > 0)
          Positioned(
            top: 2, right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _gold, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge',
                  style: const TextStyle(color: Colors.black,
                      fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
      ]),
    );
  }

  Widget _buildSection() => switch (_section) {
    0 => _buildOverview(),
    1 => _buildAccounts(),
    2 => _buildContent(),
    3 => _buildCreators(),
    4 => _buildPayments(),
    5 => _buildPacks(),
    6 => _buildDelivery(),
    _ => const SizedBox.shrink(),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _topBar('Vue d\'ensemble', subtitle: 'Métriques clés de la plateforme'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // KPI row 1
            Row(children: [
              _kpi('👥', 'Utilisateurs', _statUsers, _accent),
              const SizedBox(width: 12),
              _kpi('🏪', 'Vendeurs', _statSellers, _purp),
              const SizedBox(width: 12),
              _kpi('🎬', 'Creators', _statCreators, _green),
            ]),
            const SizedBox(height: 12),
            // KPI row 2
            Row(children: [
              _kpi('📸', 'Posts', _statPosts, const Color(0xFFFF6B35)),
              const SizedBox(width: 12),
              _kpi('🎥', 'Reels', _statReels, _accent),
              const SizedBox(width: 12),
              _kpi('⏳', 'En attente', _statPending, _gold),
            ]),
            const SizedBox(height: 24),
            _overviewLabel('Actions rapides'),
            const SizedBox(height: 12),
            Row(children: [
              _actionBtn(
                icon: Icons.pending_actions_rounded,
                label: 'Comptes en attente',
                count: _statPending,
                color: _gold,
                onTap: () => setState(() { _section = 1; _accountTabs.animateTo(0); }),
              ),
              const SizedBox(width: 12),
              _actionBtn(
                icon: Icons.auto_awesome_rounded,
                label: 'Creators en attente',
                count: _crPending.length,
                color: _purp,
                onTap: () => setState(() { _section = 3; _crTabs.animateTo(0); }),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _actionBtn(
                icon: Icons.flag_rounded,
                label: 'Contenu rejeté',
                count: _statContent,
                color: _red,
                onTap: () => setState(() {
                  _section = 2;
                  _postFilter = 'rejected';
                }),
              ),
              const SizedBox(width: 12),
              _actionBtn(
                icon: Icons.photo_library_rounded,
                label: 'Tout le contenu',
                count: _statPosts + _statReels,
                color: _accent,
                onTap: () => setState(() {
                  _section = 2;
                  _postFilter = 'all';
                }),
              ),
            ]),
          ]),
        ),
      ),
    ],
  );

  Widget _kpi(String icon, String label, int val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 10),
        Text('$val',
            style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label,
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10)),
      ]),
    ),
  );

  Widget _actionBtn({
    required IconData icon, required String label,
    required int count, required Color color, required VoidCallback onTap,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700)),
              Text('$count éléments',
                  style: GoogleFonts.montserrat(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color, size: 13),
        ]),
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPTES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAccounts() => Column(children: [
    _topBar('Comptes',
        subtitle: 'Validation des vendeurs & acheteurs'),
    Container(
      color: _card,
      child: TabBar(
        controller: _accountTabs,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12),
        indicatorColor: _accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: _border,
        tabs: [
          Tab(text: 'En attente (${_accPending.length})'),
          Tab(text: 'Vérifiés (${_accVerified.length})'),
          Tab(text: 'Rejetés (${_accRejected.length})'),
        ],
      ),
    ),
    Expanded(
      child: TabBarView(controller: _accountTabs, children: [
        _userList(_accPending,  isCreator: false),
        _userList(_accVerified, isCreator: false),
        _userList(_accRejected, isCreator: false),
      ]),
    ),
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENU
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildContent() => Column(children: [
    _topBar('Modération du contenu',
        subtitle: 'Posts et Reels des vendeurs & creators'),
    // filter chips
    Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _filterChip('all',      '🌐 Tout'),
          _filterChip('reel',     '🎬 Reels'),
          _filterChip('classic',  '📸 Posts'),
          _filterChip('rejected', '🚫 Rejetés'),
        ]),
      ),
    ),
    Expanded(
      child: _postsLoading
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _loadContent,
              color: _accent,
              child: Builder(builder: (_) {
                final filtered = _postFilter == 'all'
                    ? _posts
                    : _postFilter == 'rejected'
                        ? _posts.where((p) => p.modStatus == 'rejected').toList()
                        : _posts.where((p) => p.postType == _postFilter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('Aucun contenu',
                      style: TextStyle(color: Colors.white38)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _postCard(filtered[i]),
                );
              }),
            ),
    ),
  ]);

  Widget _filterChip(String val, String label) {
    final sel = _postFilter == val;
    return GestureDetector(
      onTap: () => setState(() => _postFilter = val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? _accent : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(label,
            style: GoogleFonts.montserrat(
                color: sel ? _accent : Colors.white38,
                fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _postCard(_PostRow p) {
    final isVideo = _isVideo(p.mediaUrl);
    final statusColor = switch (p.modStatus) {
      'approved' => _green,
      'rejected' => _red,
      _          => _gold,
    };
    final statusLabel = switch (p.modStatus) {
      'approved' => 'Approuvé',
      'rejected' => 'Rejeté',
      _          => 'En attente',
    };
    final typeIcon = p.postType == 'reel' ? '🎬' : '📸';

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16)),
            child: SizedBox(
              width: 90, height: 90,
              child: Stack(fit: StackFit.expand, children: [
                p.mediaUrl.isNotEmpty
                    ? Image.network(p.mediaUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.white10,
                                child: const Icon(Icons.image_outlined,
                                    color: Colors.white24, size: 28)))
                    : Container(color: Colors.white10,
                        child: const Icon(Icons.image_outlined,
                            color: Colors.white24, size: 28)),
                if (isVideo)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white70, size: 28)),
                  ),
              ]),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(typeIcon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text('${p.postType == 'reel' ? 'Reel' : 'Post'} · ${p.storeName}',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(statusLabel,
                        style: GoogleFonts.montserrat(
                            color: statusColor, fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(p.authorName,
                    style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 4),
                if (p.caption.isNotEmpty)
                  Text(p.caption,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          color: Colors.white60, fontSize: 11, height: 1.4)),
                if (p.modNote != null && p.modNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Note: ${p.modNote}',
                        style: GoogleFonts.montserrat(
                            color: _red.withValues(alpha: 0.7),
                            fontSize: 10, fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 4),
                Text(_timeAgo(p.createdAt),
                    style: GoogleFonts.montserrat(
                        color: Colors.white24, fontSize: 9)),
              ]),
            ),
          ),
        ]),

        // Action bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(children: [
            if (p.modStatus != 'approved')
              _contentBtn(Icons.check_rounded, 'Approuver', _green,
                  () => _approvePost(p)),
            if (p.modStatus != 'rejected')
              _contentBtn(Icons.block_rounded, 'Rejeter', Colors.orange,
                  () => _rejectPost(p)),
            const Spacer(),
            _contentBtn(Icons.delete_outline_rounded, 'Supprimer', _red,
                () => _deletePost(p)),
          ]),
        ),
      ]),
    );
  }

  Widget _contentBtn(IconData icon, String label, Color color,
      VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.montserrat(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATORS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCreators() => Column(children: [
    _topBar('Creators', subtitle: 'Validation des demandes Lincoo Creator'),
    Container(
      color: _card,
      child: TabBar(
        controller: _crTabs,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12),
        indicatorColor: _purp,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: _border,
        tabs: [
          Tab(text: 'En attente (${_crPending.length})'),
          Tab(text: 'Vérifiés (${_crVerified.length})'),
        ],
      ),
    ),
    Expanded(
      child: TabBarView(controller: _crTabs, children: [
        _userList(_crPending,  isCreator: true),
        _userList(_crVerified, isCreator: true),
      ]),
    ),
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // PAIEMENTS & REÇUS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPayments() => Column(children: [
    _topBar('Paiements & Reçus',
        subtitle: 'Validation des demandes publicitaires'),
    Container(
      color: _card,
      child: TabBar(
        controller: _adTabs,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12),
        indicatorColor: _gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: _border,
        tabs: [
          Tab(text: 'En attente (${_adsPending.length})'),
          Tab(text: 'Approuvés (${_adsApproved.length})'),
          Tab(text: 'Rejetés (${_adsRejected.length})'),
        ],
      ),
    ),
    Expanded(
      child: _adsLoading
          ? const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2))
          : TabBarView(controller: _adTabs, children: [
              _adList(_adsPending,  showActions: true),
              _adList(_adsApproved, showActions: false),
              _adList(_adsRejected, showActions: false),
            ]),
    ),
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // PACKS VENDEURS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPacks() => Column(children: [
    _topBar('Packs Vendeurs', subtitle: 'Activation des abonnements boutique'),
    Container(
      color: _card,
      child: TabBar(
        controller: _packTabs,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12),
        indicatorColor: _purp,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: _border,
        tabs: [
          Tab(text: 'En attente (${_packsPending.length})'),
          Tab(text: 'Actifs (${_packsActive.length})'),
          Tab(text: 'Annulés (${_packsCancelled.length})'),
        ],
      ),
    ),
    Expanded(
      child: _packsLoading
          ? const Center(child: CircularProgressIndicator(color: _purp, strokeWidth: 2))
          : TabBarView(controller: _packTabs, children: [
              _packList(_packsPending,   showActions: true),
              _packList(_packsActive,    showActions: false),
              _packList(_packsCancelled, showActions: false),
            ]),
    ),
  ]);

  Widget _packList(List<_PackRow> packs, {required bool showActions}) {
    if (packs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white12, size: 48),
          const SizedBox(height: 12),
          Text('Aucune demande',
              style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 13)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPacks,
      color: _purp,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: packs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _packCard(packs[i], showActions: showActions),
      ),
    );
  }

  Widget _packCard(_PackRow pack, {required bool showActions}) {
    final packColor = switch (pack.packType) {
      'business' => _gold,
      'pro'      => _purp,
      _          => _accent,
    };
    final statusColor = switch (pack.status) {
      'active'          => _green,
      'cancelled'       => _red,
      'expired'         => Colors.white30,
      'paid'            => _gold,
      _                 => Colors.white38,
    };
    final statusLabel = switch (pack.status) {
      'active'          => 'Actif',
      'cancelled'       => 'Annulé',
      'expired'         => 'Expiré',
      'paid'            => 'Payé — en attente',
      'pending_payment' => 'En attente paiement',
      _                 => pack.status,
    };

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: packColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: packColor.withValues(alpha: 0.15),
                border: Border.all(color: packColor.withValues(alpha: 0.4)),
              ),
              child: Center(child: Text(pack.packEmoji,
                  style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pack.sellerName,
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              Text(pack.sellerEmail,
                  style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: packColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: packColor.withValues(alpha: 0.35)),
                ),
                child: Text('${pack.packEmoji} ${pack.packLabel}',
                    style: GoogleFonts.montserrat(
                        color: packColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statusLabel,
                    style: GoogleFonts.montserrat(
                        color: statusColor, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),

        // Meta chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _adChip(Icons.payments_outlined, '${pack.priceDzd} DA', _gold),
            if (pack.paymentRef != null)
              _adChip(Icons.tag_rounded, pack.paymentRef!, Colors.white38),
            _adChip(Icons.schedule_outlined, _timeAgo(pack.createdAt), Colors.white38),
            if (pack.activatedAt != null)
              _adChip(Icons.check_circle_outline, 'Activé ${_fmtDate(pack.activatedAt)}', _green),
            if (pack.adminNote != null && pack.adminNote!.isNotEmpty)
              _adChip(Icons.note_outlined, pack.adminNote!, _red),
          ]),
        ),

        // Action buttons
        if (showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _rejectPack(pack),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: _red.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text('Refuser',
                        style: GoogleFonts.montserrat(
                            color: _red, fontSize: 12, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _approvePack(pack),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [packColor, _green]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text('Activer le pack',
                        style: GoogleFonts.montserrat(
                            color: Colors.black, fontSize: 12,
                            fontWeight: FontWeight.w900))),
                  ),
                ),
              ),
            ]),
          )
        else
          const SizedBox(height: 16),
      ]),
    );
  }

  Widget _adList(List<_AdRow> ads, {required bool showActions}) {
    if (ads.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.receipt_long_outlined, color: Colors.white12, size: 48),
          const SizedBox(height: 12),
          Text('Aucune demande',
              style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 13)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAds,
      color: _gold,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _adCard(ads[i], showActions: showActions),
      ),
    );
  }

  Widget _adCard(_AdRow ad, {required bool showActions}) {
    final statusColor = switch (ad.approvalStatus) {
      'approved' => _green,
      'rejected' => _red,
      _          => _gold,
    };
    final statusLabel = switch (ad.approvalStatus) {
      'approved' => 'Approuvé',
      'rejected' => 'Rejeté',
      _          => 'En attente',
    };

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header: advertiser info + status ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_gold, Color(0xFFFF6B35)]),
              ),
              child: Center(child: Text(
                ad.advertiserName.isNotEmpty ? ad.advertiserName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.black,
                    fontSize: 18, fontWeight: FontWeight.w900),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ad.advertiserName,
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              if (ad.companyName.isNotEmpty)
                Text(ad.companyName,
                    style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11)),
              Text(ad.advertiserEmail,
                  style: GoogleFonts.montserrat(color: Colors.white30, fontSize: 10)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(statusLabel,
                  style: GoogleFonts.montserrat(
                      color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        // ── Ad preview + receipt side by side ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Ad visual preview
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Annonce',
                    style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _adVisual(ad),
                ),
                const SizedBox(height: 6),
                Text(ad.title,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (ad.description != null && ad.description!.isNotEmpty)
                  Text(ad.description!,
                      style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),

            const SizedBox(width: 12),

            // Receipt preview
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Justificatif',
                    style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: ad.receiptSignedUrl != null
                      ? () => _showFullImage(ad.receiptSignedUrl!)
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ad.receiptSignedUrl != null
                        ? Image.network(
                            ad.receiptSignedUrl!,
                            height: 110, width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _receiptPlaceholder(),
                          )
                        : _receiptPlaceholder(),
                  ),
                ),
                const SizedBox(height: 6),
                if (ad.receiptSignedUrl != null)
                  Row(children: [
                    const Icon(Icons.zoom_in_rounded, color: Colors.white30, size: 12),
                    const SizedBox(width: 4),
                    Text('Appuyer pour agrandir',
                        style: GoogleFonts.montserrat(
                            color: Colors.white30, fontSize: 9)),
                  ]),
              ]),
            ),
          ]),
        ),

        // ── Payment meta ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _adChip(Icons.payments_outlined,
                '${ad.budgetDZD} DA', _gold),
            _adChip(Icons.credit_card_outlined,
                ad.paymentMethod.isEmpty ? '—' : ad.paymentMethod, Colors.white38),
            _adChip(Icons.schedule_outlined,
                _fmtDate(ad.createdAt), Colors.white38),
            if (ad.approvedAt != null)
              _adChip(Icons.check_circle_outline, _fmtDate(ad.approvedAt), _green),
          ]),
        ),

        // ── Action buttons ────────────────────────────────────────────────
        if (showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _rejectAd(ad),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: _red.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text('Rejeter le paiement',
                        style: GoogleFonts.montserrat(
                            color: _red, fontSize: 12, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _approveAd(ad),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_green, _accent]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text('Approuver le paiement',
                        style: GoogleFonts.montserrat(
                            color: Colors.black, fontSize: 12,
                            fontWeight: FontWeight.w900))),
                  ),
                ),
              ),
            ]),
          )
        else
          const SizedBox(height: 16),
      ]),
    );
  }

  Widget _adVisual(_AdRow ad) {
    if (ad.imageUrl != null &&
        ad.imageUrl!.isNotEmpty &&
        !ad.imageUrl!.startsWith('gradient:')) {
      return Image.network(
        ad.imageUrl!,
        height: 110, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientBox(ad.imageUrl, ad.title),
      );
    }
    return _gradientBox(ad.imageUrl, ad.title);
  }

  Widget _gradientBox(String? gradientId, String title) {
    final colors = switch (gradientId) {
      'gradient:neon'    => [const Color(0xFF00F6FF), const Color(0xFF00B2FF)],
      'gradient:crimson' => [const Color(0xFF292526), const Color(0xFF6E1128)],
      'gradient:purple'  => [const Color(0xFF8A2BE2), const Color(0xFF4B0082)],
      'gradient:orange'  => [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      _                  => [_card, _border],
    };
    return Container(
      height: 110, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Text(title,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
    );
  }

  Widget _receiptPlaceholder() => Container(
    height: 110, width: double.infinity,
    color: Colors.white.withValues(alpha: 0.04),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 28),
      const SizedBox(height: 6),
      Text('Pas de reçu', style: GoogleFonts.montserrat(
          color: Colors.white24, fontSize: 10)),
    ]),
  );

  Widget _adChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.montserrat(
          color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image, color: Colors.white54, size: 64)),
          ),
        ),
      ),
    );
  }

  // ─── Shared user list ─────────────────────────────────────────────────────
  Widget _userList(List<_UserRow> list, {required bool isCreator}) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.inbox_outlined, color: Colors.white12, size: 48),
          const SizedBox(height: 12),
          Text('Aucun élément',
              style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 13)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: isCreator ? _loadCreators : _loadAccounts,
      color: _accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _userCard(list[i], isCreator: isCreator),
      ),
    );
  }

  Widget _userCard(_UserRow u, {required bool isCreator}) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            // avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isCreator
                      ? [_purp, _accent]
                      : [_accent, const Color(0xFF1E40AF)],
                ),
              ),
              child: Center(child: Text(
                u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w900),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                Text(u.email, style: GoogleFonts.montserrat(
                    color: Colors.white38, fontSize: 10)),
              ]),
            ),
            _badge(u.status),
          ]),
        ),

        // Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            _chip(u.roleLabel,
                isCreator ? _purp : _accent, Icons.badge_outlined),
            if (u.storeName != null)
              _chip(u.storeName!, Colors.white30, Icons.storefront_outlined),
            if (u.wilaya != null)
              _chip(u.wilaya!, Colors.white30, Icons.location_on_outlined),
            if (u.category != null)
              _chip(u.category!, Colors.white30, Icons.category_outlined),
            if (isCreator && u.creatorType != null)
              _chip(u.creatorType!, _purp, Icons.auto_awesome_outlined),
            if (isCreator && u.followersRange != null)
              _chip(u.followersRange!, _green, Icons.people_outline),
            _chip(_timeAgo(u.createdAt), Colors.white24, Icons.schedule_outlined),
          ]),
        ),

        // Creator-specific: social links
        if (isCreator && (u.instagramUrl != null || u.tiktokUrl != null ||
            u.youtubeUrl != null))
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(children: [
              if (u.instagramUrl != null)
                _socialTag('IG', u.instagramUrl!),
              if (u.tiktokUrl != null)
                _socialTag('TT', u.tiktokUrl!),
              if (u.youtubeUrl != null)
                _socialTag('YT', u.youtubeUrl!),
            ]),
          ),

        // Creator bio
        if (isCreator && u.bio != null && u.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(u.bio!,
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                    color: Colors.white54, fontSize: 11, height: 1.4)),
          ),

        // Action row
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border))),
          child: Row(children: [
            GestureDetector(
              onTap: () => _showUserDetail(u, isCreator: isCreator),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.open_in_new_rounded,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 5),
                  Text('Dossier',
                      style: GoogleFonts.montserrat(
                          color: Colors.white38, fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            if (u.status == 'pending') ...[
              const Spacer(),
              _actionIcon(Icons.close_rounded, _red,
                  () => isCreator ? _rejectCreator(u) : _rejectAccount(u)),
              const SizedBox(width: 8),
              _actionIcon(Icons.check_rounded, _green,
                  () => isCreator ? _approveCreator(u) : _approveAccount(u)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _socialTag(String prefix, String url) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _border),
    ),
    child: Text('$prefix: $url',
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10)),
  );

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      );

  // ─── User detail sheet ────────────────────────────────────────────────────
  void _showUserDetail(_UserRow u, {required bool isCreator}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4)),
            ),
            // header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _border))),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: isCreator
                        ? [_purp, _accent] : [_accent, Colors.blue]),
                  ),
                  child: Center(child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.w900),
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(u.name, style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(u.email, style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 11)),
                  ]),
                ),
                _badge(u.status),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.all(16),
                children: [
                  _detailSection('Identité', [
                    _dr('Rôle', u.roleLabel),
                    _dr('Email', u.email),
                    if (u.telephone != null) _dr('Téléphone', u.telephone!),
                    _dr('Inscrit', _fmtDate(u.createdAt)),
                    if (u.wilaya != null) _dr('Wilaya', u.wilaya!),
                  ]),
                  if (u.storeName != null || u.category != null)
                    _detailSection('Boutique / Profil', [
                      if (u.storeName != null) _dr('Nom boutique', u.storeName!),
                      if (u.category != null) _dr('Catégorie', u.category!),
                      if (u.subcategory != null) _dr('Sous-catégorie', u.subcategory!),
                      if (u.businessSize != null) _dr('Taille', u.businessSize!),
                      if (u.address != null) _dr('Adresse', u.address!),
                    ]),
                  if (isCreator)
                    _detailSection('Profil Creator', [
                      if (u.creatorType != null) _dr('Type', u.creatorType!),
                      if (u.followersRange != null) _dr('Abonnés', u.followersRange!),
                      if (u.instagramUrl != null) _dr('Instagram', u.instagramUrl!),
                      if (u.tiktokUrl != null) _dr('TikTok', u.tiktokUrl!),
                      if (u.youtubeUrl != null) _dr('YouTube', u.youtubeUrl!),
                      if (u.bio != null && u.bio!.isNotEmpty)
                        _dr('Motivation', u.bio!, multi: true),
                    ]),
                  if (u.kycCinUrl != null)
                    _detailSection('KYC', [
                      _kycThumb('CIN', u.kycCinUrl!),
                      if (u.kycSelfieUrl != null) _kycThumb('Selfie', u.kycSelfieUrl!),
                    ]),
                ],
              ),
            ),
            if (u.status == 'pending')
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _border))),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (isCreator) {
                          _rejectCreator(u);
                        } else {
                          _rejectAccount(u);
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          border: Border.all(color: _red.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('Rejeter',
                            style: GoogleFonts.montserrat(
                                color: _red, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (isCreator) {
                          _approveCreator(u);
                        } else {
                          _approveAccount(u);
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_green, _accent]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('Approuver',
                            style: GoogleFonts.montserrat(
                                color: Colors.black, fontWeight: FontWeight.w900))),
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  // ─── Shared UI atoms ──────────────────────────────────────────────────────
  Widget _topBar(String title, {String? subtitle}) => Container(
    color: _card,
    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(
            colors: [Colors.white, Color(0xFFCDD6F8)]).createShader(r),
        child: Text(title, style: GoogleFonts.montserrat(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ),
      if (subtitle != null)
        Text(subtitle, style: GoogleFonts.montserrat(
            color: Colors.white30, fontSize: 11)),
    ]),
  );

  Widget _badge(String status) {
    final (color, label) = switch (status) {
      'pending'  => (_gold, 'En attente'),
      'verified' => (_green, 'Vérifié'),
      'rejected' => (_red, 'Rejeté'),
      _          => (Colors.white30, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: GoogleFonts.montserrat(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _chip(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.montserrat(
          color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _overviewLabel(String t) => Text(t,
      style: GoogleFonts.montserrat(
          color: Colors.white54, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 0.8));

  Widget _detailSection(String title, List<Widget> rows) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _bg.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.montserrat(
          color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      ...rows,
    ]),
  );

  Widget _dr(String label, String val, {bool multi = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment:
        multi ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
      SizedBox(width: 90,
          child: Text(label, style: GoogleFonts.montserrat(
              color: Colors.white30, fontSize: 10))),
      Expanded(child: Text(val, style: GoogleFonts.montserrat(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
          height: multi ? 1.4 : 1))),
    ]),
  );

  Widget _kycThumb(String label, String url) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.montserrat(
          color: Colors.white30, fontSize: 10)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, height: 120, width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 120, color: Colors.white10,
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.white24))),
        ),
      ),
    ]),
  );

  Widget _accessDenied() => Scaffold(
    backgroundColor: _bg,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
      const Icon(Icons.lock_outline, color: _accent, size: 64),
      const SizedBox(height: 16),
      Text('Accès refusé', style: GoogleFonts.montserrat(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text("Droits administrateur requis.", style: GoogleFonts.montserrat(
          color: Colors.white38, fontSize: 13)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => Navigator.pushReplacementNamed(context, '/feed'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accent, _purp]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Retour', style: GoogleFonts.montserrat(
              color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    ])),
  );

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  Future<String?> _rejectDialog(String target) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rejeter $target',
            style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Raison (optionnel)',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl, maxLines: 3,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ex: Contenu inapproprié, informations incorrectes...',
              hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 11),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text('Confirmer',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog(String title, String body) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.montserrat(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        content: Text(body, style: GoogleFonts.montserrat(
            color: Colors.white38, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Utils ────────────────────────────────────────────────────────────────
  static bool _isVideo(String url) =>
      ['.mp4', '.mov', '.webm', '.avi']
          .any((ext) => url.toLowerCase().endsWith(ext));

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60)  return 'Il y a ${d.inMinutes}min';
    if (d.inHours   < 24)  return 'Il y a ${d.inHours}h';
    return 'Il y a ${d.inDays}j';
  }

  static String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/'
        '${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELIVERY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDelivery() => Column(children: [
    _topBar('Delivery Management', subtitle: 'Smart Delivery — Ramassages — Groupes'),
    Container(
      color: _card,
      child: TabBar(
        controller: _delivTabs,
        labelColor: _accent,
        unselectedLabelColor: Colors.white38,
        indicatorColor: _accent, indicatorWeight: 2,
        dividerColor: _border,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        tabs: [
          Tab(text: 'Demandes Smart (${_delivSmartReqs.length})'),
          Tab(text: 'Ramassages (${_delivPickups.length})'),
          Tab(text: 'Groupes (${_delivGroups.length})'),
        ],
      ),
    ),
    Expanded(
      child: _delivLoading
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : TabBarView(controller: _delivTabs, children: [
              _delivSmartReqsList(),
              _delivPickupsList(),
              _delivGroupsList(),
            ]),
    ),
  ]);

  // ── Smart Delivery Requests tab ──────────────────────────────────────────
  Widget _delivSmartReqsList() {
    if (_delivSmartReqs.isEmpty) return _emptyState('📦', 'Aucune demande Smart Delivery');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _delivSmartReqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = _delivSmartReqs[i];
        final profile = r['profiles'] as Map<String,dynamic>?;
        final name    = profile?['full_name'] as String? ?? 'Vendeur';
        final email   = profile?['email']     as String? ?? '';
        final status  = r['status'] as String? ?? 'pending';
        final isPending = status == 'pending';
        final statusColor = switch (status) {
          'approved'  => _green,
          'rejected'  => _red,
          'suspended' => _gold,
          _           => _gold,
        };
        return Container(
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white54, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(
                    color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ]),
            if (r['store_name'] != null) ...[
              const SizedBox(height: 8),
              Text('Boutique: ${r['store_name']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
            if (r['admin_note'] != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Note: ${r['admin_note']}',
                    style: TextStyle(color: _red.withValues(alpha: 0.8), fontSize: 11)),
              ),
            ],
            const SizedBox(height: 4),
            Text(_fmtDate(r['created_at'] != null
                ? DateTime.tryParse(r['created_at'] as String) : null),
                style: const TextStyle(color: Colors.white24, fontSize: 10)),
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _actionChip('✓ Approuver', _green,
                    () => _approveSmartReq(r['id'] as String, name))),
                const SizedBox(width: 10),
                Expanded(child: _actionChip('✕ Rejeter', _red,
                    () => _rejectSmartReq(r['id'] as String, name))),
              ]),
            ],
          ]),
        );
      },
    );
  }

  // ── Pickup Requests tab ──────────────────────────────────────────────────
  Widget _delivPickupsList() {
    if (_delivPickups.isEmpty) return _emptyState('📅', 'Aucun ramassage planifié');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _delivPickups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _delivPickups[i];
        final profile = p['profiles'] as Map<String,dynamic>?;
        final name    = profile?['full_name'] as String? ?? 'Vendeur';
        final status  = p['status'] as String? ?? 'scheduled';
        final statusColor = switch (status) {
          'completed'       => _green,
          'en_route'        => _accent,
          'driver_assigned' => _accent,
          'confirmed'       => _green,
          'failed'          => _red,
          'cancelled'       => Colors.white24,
          _                 => _gold,
        };
        return Container(
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.calendar_today_rounded, color: statusColor, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              Text('${p['pickup_date'] ?? '—'}  ${p['pickup_from'] ?? ''} — ${p['pickup_to'] ?? ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              if (p['address'] != null)
                Text(p['address'] as String, style: const TextStyle(color: Colors.white24, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Text('📦 ${p['packages_count'] ?? 1} colis',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
        );
      },
    );
  }

  // ── Smart Groups tab ─────────────────────────────────────────────────────
  Widget _delivGroupsList() {
    if (_delivGroups.isEmpty) return _emptyState('🔗', 'Aucun groupe Smart Delivery');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _delivGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final g = _delivGroups[i];
        final status  = g['status'] as String? ?? 'pending_confirmation';
        final statusColor = switch (status) {
          'delivered'   => _green,
          'in_transit'  => _accent,
          'picked_up'   => _accent,
          'confirmed'   => _green,
          'cancelled'   => Colors.white24,
          'disputed'    => _red,
          _             => _gold,
        };
        final code = (g['group_code'] as String? ?? '').toUpperCase();
        return Container(
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(code.isNotEmpty ? '#$code' : 'Groupe',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900,
                      letterSpacing: 1))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                child: Text(status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _infoTag('🏪 ${g['total_sellers'] ?? 0} vendeurs', Colors.white38),
              _infoTag('📦 ${g['total_products'] ?? 0} produits', Colors.white38),
              _infoTag('💰 ${g['total_price_dzd'] ?? 0} DA', _accent),
              _infoTag('🚚 ${g['delivery_fee_dzd'] ?? 0} DA livraison', _gold),
              if ((g['savings_dzd'] as int? ?? 0) > 0)
                _infoTag('💚 -${g['savings_dzd']} DA économisés', _green),
              if (g['buyer_wilaya'] != null)
                _infoTag('📍 ${g['buyer_wilaya']}', Colors.white24),
            ]),
            const SizedBox(height: 4),
            Text(_fmtDate(g['created_at'] != null
                ? DateTime.tryParse(g['created_at'] as String) : null),
                style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ]),
        );
      },
    );
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    ),
  );

  Widget _infoTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10)),
  );

  Widget _emptyState(String icon, String label) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(icon, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
    ],
  ));

}

// ─── Models ───────────────────────────────────────────────────────────────────
class _UserRow {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? telephone;
  final String? storeName;
  final String? wilaya;
  final String? address;
  final String? category;
  final String? subcategory;
  final String? businessSize;
  final String? bio;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? creatorType;
  final String? followersRange;
  final String? kycCinUrl;
  final String? kycSelfieUrl;
  final DateTime? createdAt;

  const _UserRow({
    required this.id, required this.name, required this.email,
    required this.role, required this.status,
    this.telephone, this.storeName, this.wilaya, this.address,
    this.category, this.subcategory, this.businessSize, this.bio,
    this.instagramUrl, this.tiktokUrl, this.youtubeUrl,
    this.creatorType, this.followersRange,
    this.kycCinUrl, this.kycSelfieUrl, this.createdAt,
  });

  factory _UserRow.fromMap(Map<String, dynamic> m) => _UserRow(
    id:             m['id'] as String,
    name:           m['full_name'] as String? ?? 'Utilisateur',
    email:          m['email'] as String? ?? '',
    role:           m['pro_role'] as String? ?? 'none',
    status:         m['pro_status'] as String? ?? 'none',
    telephone:      m['telephone'] as String?,
    storeName:      m['store_name'] as String?,
    wilaya:         m['wilaya'] as String?,
    address:        m['address'] as String?,
    category:       m['category'] as String?,
    subcategory:    m['subcategory'] as String?,
    businessSize:   m['business_size'] as String?,
    bio:            (m['creator_bio'] ?? m['bio']) as String?,
    instagramUrl:   m['instagram_url'] as String?,
    tiktokUrl:      m['tiktok_url'] as String?,
    youtubeUrl:     m['youtube_url'] as String?,
    creatorType:    m['creator_type'] as String?,
    followersRange: m['followers_range'] as String?,
    kycCinUrl:      m['kyc_cin_url'] as String?,
    kycSelfieUrl:   m['kyc_selfie_url'] as String?,
    createdAt:      m['created_at'] != null
        ? DateTime.tryParse(m['created_at'] as String) : null,
  );

  String get roleLabel => switch (role) {
    'seller'  => 'Vendeur',
    'creator' => 'Creator',
    'buyer'   => 'Acheteur',
    'company' => 'Entreprise',
    _         => role,
  };
}

class _AdRow {
  final String  id;
  final String  companyId;
  final String  advertiserName;
  final String  advertiserEmail;
  final String  companyName;
  final String  contact;
  final String  title;
  final String? description;
  final String? imageUrl;
  final String? receiptStoragePath;
  final String? receiptSignedUrl;
  final String  paymentStatus;
  final String  approvalStatus;
  final String  paymentMethod;
  final int     budgetDZD;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  const _AdRow({
    required this.id,
    required this.companyId,
    required this.advertiserName,
    required this.advertiserEmail,
    required this.companyName,
    required this.contact,
    required this.title,
    this.description,
    this.imageUrl,
    this.receiptStoragePath,
    this.receiptSignedUrl,
    required this.paymentStatus,
    required this.approvalStatus,
    required this.paymentMethod,
    required this.budgetDZD,
    this.createdAt,
    this.approvedAt,
  });
}

class _PackRow {
  final String  id;
  final String  sellerId;
  final String  sellerName;
  final String  sellerEmail;
  final String  packType;
  final String  status;
  final int     priceDzd;
  final String? paymentRef;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? activatedAt;

  const _PackRow({
    required this.id, required this.sellerId,
    required this.sellerName, required this.sellerEmail,
    required this.packType, required this.status,
    required this.priceDzd,
    this.paymentRef, this.adminNote, this.createdAt, this.activatedAt,
  });

  String get packLabel => switch (packType) {
    'starter'  => 'Starter',
    'pro'      => 'Pro',
    'business' => 'Lincoo+',
    _          => packType,
  };

  String get packEmoji => switch (packType) {
    'starter'  => '🛍️',
    'pro'      => '⭐',
    'business' => '💎',
    _          => '📦',
  };
}

class _PostRow {
  final String id;
  final String storeId;
  final String storeName;
  final String authorName;
  final String authorRole;
  final String caption;
  final String mediaUrl;
  final String postType;
  final String modStatus;
  final String? modNote;
  final DateTime? createdAt;

  const _PostRow({
    required this.id, required this.storeId,
    required this.storeName, required this.authorName,
    required this.authorRole, required this.caption,
    required this.mediaUrl, required this.postType,
    required this.modStatus, this.modNote, this.createdAt,
  });
}
