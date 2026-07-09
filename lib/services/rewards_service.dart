import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Reward event (for real-time toast animation) ──────────────────────────────
class RewardEvent {
  final int    amount;
  final bool   isXp;   // true = XP, false = Coins
  final String reason;
  const RewardEvent(this.amount, this.isXp, this.reason);
}

// ── Levels ─────────────────────────────────────────────────────────────────────
enum LincooLevel {
  explorer(    '🌱 Explorer',     0),
  rising(      '🚀 Rising Creator', 500),
  professional('💼 Professional',  1500),
  elite(       '👑 Elite',         4000),
  ambassador(  '💎 Ambassador',   10000),
  legend(      '🔥 Legend',       25000);

  const LincooLevel(this.label, this.minXp);
  final String label;
  final int    minXp;

  static LincooLevel fromXp(int xp) {
    for (final l in LincooLevel.values.reversed) {
      if (xp >= l.minXp) return l;
    }
    return LincooLevel.explorer;
  }

  LincooLevel? get next {
    final i = LincooLevel.values.indexOf(this);
    return i + 1 < LincooLevel.values.length
        ? LincooLevel.values[i + 1]
        : null;
  }
}

// ── XP & Coins constants ───────────────────────────────────────────────────────
class XpReward {
  static const int completeProfile = 200;
  static const int verifyIdentity  = 300;
  static const int firstPost       = 50;
  static const int publishReel     = 20;
  static const int firstSale       = 300;
  static const int orderDelivered  = 20;
  static const int fiveStarReview  = 50;
  static const int inviteCreator   = 150;
}

class CoinsReward {
  static const int dailyLogin    = 20;
  static const int publishReel   = 10;
  static const int publishStory  = 5;
  static const int dailyMissions = 100;
  static const int streak7       = 300;
  static const int firstSale     = 100;
}

// ── Daily mission keys ─────────────────────────────────────────────────────────
class MissionKey {
  static const String login  = 'daily_login';
  static const String reel   = 'publish_reel';
  static const String story  = 'publish_story';
  static const String streak = 'streak_7';
}

// ── Service ────────────────────────────────────────────────────────────────────
class RewardsService {
  RewardsService._();
  static final RewardsService instance = RewardsService._();

  // Real-time notifiers
  final ValueNotifier<int>         xp     = ValueNotifier(0);
  final ValueNotifier<int>         coins  = ValueNotifier(0);
  final ValueNotifier<LincooLevel> level  = ValueNotifier(LincooLevel.explorer);

  // Stream for toast animations
  final _eventCtrl = StreamController<RewardEvent>.broadcast();
  Stream<RewardEvent> get events => _eventCtrl.stream;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('xp_total, coins_total')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        final x = (row['xp_total']    as int?) ?? 0;
        final c = (row['coins_total'] as int?) ?? 0;
        xp.value    = x;
        coins.value = c;
        level.value = LincooLevel.fromXp(x);
        _loaded = true;
      }
    } catch (_) {}
  }

  Future<void> awardXp(int amount, String reason) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final newXp = xp.value + amount;
    xp.value    = newXp;
    level.value = LincooLevel.fromXp(newXp);
    _eventCtrl.add(RewardEvent(amount, true, reason));
    try {
      await Future.wait([
        Supabase.instance.client
            .from('profiles')
            .update({'xp_total': newXp})
            .eq('id', user.id),
        Supabase.instance.client
            .from('xp_log')
            .insert({'user_id': user.id, 'xp_amount': amount, 'reason': reason}),
      ]);
    } catch (_) {}
  }

  Future<void> awardCoins(int amount, String reason) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final newCoins = coins.value + amount;
    coins.value = newCoins;
    _eventCtrl.add(RewardEvent(amount, false, reason));
    try {
      await Future.wait([
        Supabase.instance.client
            .from('profiles')
            .update({'coins_total': newCoins})
            .eq('id', user.id),
        Supabase.instance.client
            .from('coins_log')
            .insert({'user_id': user.id, 'coins_amount': amount, 'reason': reason}),
      ]);
    } catch (_) {}
  }

  // Complete a daily mission — idempotent (won't double-award)
  Future<bool> completeMission(String key,
      {int xpAmount = 0, int coinsAmount = 0}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client
          .from('creator_daily_missions')
          .insert({
            'user_id':      user.id,
            'mission_key':  key,
            'mission_date': DateTime.now().toIso8601String().substring(0, 10),
          });
      // Insert succeeded → first time today
      if (xpAmount    > 0) await awardXp(xpAmount, key);
      if (coinsAmount > 0) await awardCoins(coinsAmount, key);
      return true;
    } catch (_) {
      return false; // already completed (unique constraint)
    }
  }

  // Check which missions are done today
  Future<Set<String>> todayMissions() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};
    try {
      final today =
          DateTime.now().toIso8601String().substring(0, 10);
      final rows = await Supabase.instance.client
          .from('creator_daily_missions')
          .select('mission_key')
          .eq('user_id', user.id)
          .eq('mission_date', today);
      return {for (final r in rows as List) r['mission_key'] as String};
    } catch (_) {
      return {};
    }
  }

  void reset() {
    xp.value    = 0;
    coins.value = 0;
    level.value = LincooLevel.explorer;
    _loaded     = false;
  }
}
