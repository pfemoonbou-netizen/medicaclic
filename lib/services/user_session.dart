import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

/// Singleton ChangeNotifier that holds the authenticated AppUser.
/// Wrap the widget tree with [UserScope] to make it available via context.
class UserSession extends ChangeNotifier {
  UserSession._();
  static final UserSession instance = UserSession._();

  AppUser _current = AppUser.demo();
  AppUser get current => _current;

  // ── Initialization ──────────────────────────────────────────────────────────

  /// Called once at app startup. Loads the user profile from Supabase or
  /// falls back to a demo user when the session is unavailable.
  Future<void> initialize() async {
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;

      if (session == null) {
        _current = AppUser.demo();
        notifyListeners();
        return;
      }

      final data = await client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      _current = data != null
          ? AppUser.fromMap({...data, 'email': session.user.email ?? ''})
          : AppUser(
              id: session.user.id,
              email: session.user.email ?? '',
              displayName:
                  session.user.userMetadata?['full_name'] as String? ??
                      'Utilisateur',
            );
    } catch (e) {
      debugPrint('UserSession.initialize: $e');
      _current = AppUser.demo();
    }
    notifyListeners();
  }

  // ── Mutations ───────────────────────────────────────────────────────────────

  /// Replace the current user and notify listeners.
  void update(AppUser user) {
    _current = user;
    notifyListeners();
  }

  /// Select a pro role from the onboarding sheet.
  /// Buyer → immediate verification; others → incomplete (pending form).
  Future<void> selectProRole(ProRole role) async {
    final isImmediate = role == ProRole.buyer;
    final updated = _current.copyWith(
      proRole: role,
      proStatus: isImmediate ? ProStatus.verified : ProStatus.incomplete,
      onboardingComplete: isImmediate,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Called after a pro completes their registration form.
  /// Transitions proStatus → pending (awaits admin review).
  Future<void> submitForVerification() async {
    final updated = _current.copyWith(
      proStatus: ProStatus.pending,
      onboardingComplete: false,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Called after completing pro registration (no admin validation).
  /// Activates the role immediately as verified.
  Future<void> activateProRole(ProRole role) async {
    final updated = _current.copyWith(
      proRole: role,
      proStatus: ProStatus.verified,
      onboardingComplete: true,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Called after seller completes the 9-step KYC registration.
  /// Sets role to seller and status to pending until KYC is reviewed.
  Future<void> registerSellerPending() async {
    final updated = _current.copyWith(
      proRole: ProRole.seller,
      proStatus: ProStatus.pending,
      onboardingComplete: true,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Ensures a store row exists for the current seller and syncs the latest
  /// profile details into it so the store is immediately usable for posts,
  /// products, and profile updates.
  Future<Map<String, dynamic>?> ensureSellerStore({
    String? ownerId,
    String? storeName,
    String? wilaya,
    String? category,
    String? avatarUrl,
    String? bio,
    String? username,
  }) async {
    final uid = ownerId ?? _current.id;
    if (uid.isEmpty || uid == AppUser.demo().id) return null;

    try {
      final client = Supabase.instance.client;
      final existing = await client
          .from('stores')
          .select('id, owner_id, store_name, wilaya, category, logo_url, username, bio, followers_count, products_count, total_sales, rating')
          .eq('owner_id', uid)
          .maybeSingle();

      final payload = <String, dynamic>{};
      if (storeName != null && storeName.trim().isNotEmpty) {
        payload['store_name'] = storeName.trim();
      }
      if (wilaya != null && wilaya.trim().isNotEmpty) {
        payload['wilaya'] = wilaya.trim();
      }
      if (category != null && category.trim().isNotEmpty) {
        payload['category'] = category.trim();
      }
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        payload['logo_url'] = avatarUrl.trim();
      }
      if (bio != null && bio.trim().isNotEmpty) {
        payload['bio'] = bio.trim();
      }
      if (username != null && username.trim().isNotEmpty) {
        payload['username'] = username.trim();
      }

      if (existing != null) {
        if (payload.isNotEmpty) {
          await client.from('stores').update(payload).eq('id', existing['id']);
        }
        return existing;
      }

      if (payload['store_name'] == null) {
        payload['store_name'] = _current.displayName.isNotEmpty
            ? _current.displayName
            : 'Ma boutique';
      }
      payload['owner_id'] = uid;

      return await client
          .from('stores')
          .insert(payload)
          .select('id, owner_id, store_name, wilaya, category, logo_url, username, bio, followers_count, products_count, total_sales, rating')
          .single();
    } catch (e) {
      debugPrint('UserSession.ensureSellerStore ERROR: $e');
      return null;
    }
  }

  /// Called after creator completes registration.
  Future<void> registerCreatorPending() async {
    final updated = _current.copyWith(
      proRole: ProRole.creator,
      proStatus: ProStatus.pending,
      onboardingComplete: true,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Called after company completes registration.
  Future<void> registerCompanyPending() async {
    final updated = _current.copyWith(
      proRole: ProRole.company,
      proStatus: ProStatus.pending,
      onboardingComplete: true,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Called when Realtime notifies that an admin approved the pro account.
  Future<void> onAdminVerified() async {
    final updated = _current.copyWith(
      proStatus: ProStatus.verified,
      onboardingComplete: true,
    );
    update(updated);
    await _upsertProfile(updated);
  }

  /// Subscribe to Supabase Realtime changes on the profiles row so that
  /// admin approval is reflected instantly without a restart.
  void listenToProfileChanges() {
    if (_current.isGuest) return;
    try {
      Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', _current.id)
          .listen((rows) {
            if (rows.isEmpty) return;
            final updated = AppUser.fromMap({
              ...rows.first,
              'email': _current.email,
            });
            if (updated.proStatus == ProStatus.verified &&
                _current.proStatus != ProStatus.verified) {
              onAdminVerified();
            } else if (updated.proStatus != _current.proStatus ||
                updated.onboardingComplete != _current.onboardingComplete) {
              update(updated);
            }
          });
    } catch (e) {
      debugPrint('UserSession.listenToProfileChanges: $e');
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _upsertProfile(AppUser user) async {
    if (user.isGuest) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .upsert(user.toMap(), onConflict: 'id');
    } catch (e) {
      debugPrint('UserSession._upsertProfile ERROR: $e');
      rethrow;
    }
  }
}
