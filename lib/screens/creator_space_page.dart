import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/rewards_service.dart';
import '../services/user_session.dart';
import '../widgets/rewards_toast.dart';

// ─── palette ───────────────────────────────────────────────────────────────────
const _bg       = Color(0xFF04050E);
const _card     = Color(0xFF0B0D1A);
const _neonBlue = Color(0xFF3D8BFF);
const _neonPurp = Color(0xFF8B5CF6);
const _neonTeal = Color(0xFF06EFC5);
const _gold     = Color(0xFFFFB800);
const _orb1     = Color(0x3D3D8BFF);
const _orb2     = Color(0x2D8B5CF6);
const _orb3     = Color(0x1D06EFC5);

class CreatorSpacePage extends StatefulWidget {
  const CreatorSpacePage({super.key});

  @override
  State<CreatorSpacePage> createState() => _CreatorSpacePageState();
}

class _CreatorSpacePageState extends State<CreatorSpacePage>
    with TickerProviderStateMixin {
  Set<String> _doneMissions   = {};
  bool        _missionsLoading = true;
  double      _walletBalance   = 0.0;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    RewardsService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    RewardsService.instance.xp.addListener(_onChange);
    RewardsService.instance.coins.addListener(_onChange);
    RewardsService.instance.level.addListener(_onChange);
    _loadMissions();
    _loadWallet();
    _doLoginMission();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    RewardsService.instance.xp.removeListener(_onChange);
    RewardsService.instance.coins.removeListener(_onChange);
    RewardsService.instance.level.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  Future<void> _loadMissions() async {
    final done = await RewardsService.instance.todayMissions();
    if (mounted) setState(() { _doneMissions = done; _missionsLoading = false; });
  }

  Future<void> _doLoginMission() async {
    final added = await RewardsService.instance.completeMission(
      MissionKey.login, coinsAmount: CoinsReward.dailyLogin);
    if (added && mounted) setState(() => _doneMissions.add(MissionKey.login));
  }

  Future<void> _loadWallet() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && row != null) {
        setState(() =>
            _walletBalance = (row['wallet_balance'] as num?)?.toDouble() ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return RewardsToastLayer(
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          // ambient orbs painted behind everything
          const Positioned.fill(child: _AmbientOrbs()),
          CustomScrollView(
            slivers: [
              _buildHero(),
              _buildStatsRow(),
              _buildMissions(),
              _buildServices(),
              _buildLevelRoad(),
              _buildCampaigns(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ]),
      ),
    );
  }

  // ── HERO ────────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final xp   = RewardsService.instance.xp.value;
    final lv   = RewardsService.instance.level.value;
    final next = lv.next;
    final prog = next != null
        ? ((xp - lv.minXp) / (next.minXp - lv.minXp)).clamp(0.0, 1.0)
        : 1.0;
    final name  = UserSession.instance.current.displayName;
    final first = name.split(' ').first;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── top bar ──
          Row(children: [
            _glassButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 16),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [_neonTeal, _neonBlue, _neonPurp],
              ).createShader(r),
              child: Text('Creator Space',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
            ),
            const Spacer(),
            _glassButton(
              onTap: () => Navigator.pushNamed(context, '/wallet'),
              color: _neonTeal.withValues(alpha: 0.08),
              border: _neonTeal.withValues(alpha: 0.25),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: _neonTeal, size: 13),
                const SizedBox(width: 5),
                Text('${_walletBalance.toStringAsFixed(0)} DA',
                    style: GoogleFonts.montserrat(
                        color: _neonTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),

          const SizedBox(height: 28),

          // ── glassmorphism level card ──
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    _neonBlue.withValues(alpha: 0.06 + _pulse.value * 0.04),
                    _neonPurp.withValues(alpha: 0.08 + _pulse.value * 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _neonBlue.withValues(alpha: 0.18 + _pulse.value * 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _neonBlue.withValues(alpha: 0.12 + _pulse.value * 0.08),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // greeting row
                      Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Bonjour, $first 👋',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFCDD6F8)],
                            ).createShader(r),
                            child: Text(name,
                                style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ]),
                        const Spacer(),
                        // level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _neonBlue.withValues(alpha: 0.25),
                                _neonPurp.withValues(alpha: 0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: _neonBlue.withValues(alpha: 0.4)),
                          ),
                          child: Text(lv.label,
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3)),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // XP big number
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [_gold, Color(0xFFFFE082)],
                          ).createShader(r),
                          child: Text('$xp',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  height: 1)),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8, left: 6),
                          child: Text('XP',
                              style: GoogleFonts.montserrat(
                                  color: _gold.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const Spacer(),
                        if (next != null)
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                            Text('Prochain niveau',
                                style: GoogleFonts.montserrat(
                                    color: Colors.white30, fontSize: 9)),
                            Text(next.label,
                                style: GoogleFonts.montserrat(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '${(next.minXp - xp)} XP restants',
                                style: GoogleFonts.montserrat(
                                    color: _neonTeal.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ]),
                      ]),

                      const SizedBox(height: 16),

                      // XP bar with glow
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: prog.toDouble()),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Stack(children: [
                          // track
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // fill with glow
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_neonTeal, _neonBlue],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _neonTeal.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── STATS ───────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final xp    = RewardsService.instance.xp.value;
    final coins = RewardsService.instance.coins.value;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          _statCard('⭐', '$xp', 'XP', _gold, const [_gold, Color(0xFFFF6B00)]),
          const SizedBox(width: 10),
          _statCard('🪙', '$coins', 'Coins', const Color(0xFFE4A000),
              const [Color(0xFFE4A000), Color(0xFFFF8C00)]),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/wallet'),
            child: _statCard('💳', '${_walletBalance.toStringAsFixed(0)} DA',
                'Wallet', _neonTeal, const [_neonTeal, _neonBlue]),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String icon, String val, String label, Color glow,
      List<Color> gradColors) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glow.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(children: [
            ShaderMask(
              shaderCallback: (r) =>
                  LinearGradient(colors: gradColors).createShader(r),
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (r) =>
                  LinearGradient(colors: gradColors).createShader(r),
              child: Text(val,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.montserrat(
                    color: Colors.white30, fontSize: 9,
                    letterSpacing: 0.8)),
          ]),
        ),
      );

  // ── MISSIONS ─────────────────────────────────────────────────────────────────
  Widget _buildMissions() {
    final missions = [
      const _Mission(MissionKey.login, '☀️', 'Connexion\ndu jour',
          '+${CoinsReward.dailyLogin}🪙',
          xp: 0, coins: CoinsReward.dailyLogin,
          grad: [Color(0xFFFF6B35), Color(0xFFFF8E53)]),
      const _Mission(MissionKey.reel, '🎬', 'Publier\nun Reel',
          '+${XpReward.publishReel}⭐ +${CoinsReward.publishReel}🪙',
          xp: XpReward.publishReel, coins: CoinsReward.publishReel,
          route: '/create',
          grad: [_neonBlue, _neonPurp]),
      const _Mission(MissionKey.story, '⚡', 'Faire une\nStory',
          '+${CoinsReward.publishStory}🪙',
          xp: 0, coins: CoinsReward.publishStory,
          route: '/create',
          grad: [_neonPurp, Color(0xFFEC4899)]),
      const _Mission('complete_profile', '✅', 'Compléter\nton profil',
          '+${XpReward.completeProfile}⭐',
          xp: XpReward.completeProfile, coins: 0,
          route: '/edit-profile',
          grad: [_neonTeal, _neonBlue]),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 14),
            child: _label('🔥 Missions du jour'),
          ),
          _missionsLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: _neonTeal, strokeWidth: 1.5),
                  ))
              : SizedBox(
                  height: 160,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: missions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final m    = missions[i];
                      final done = _doneMissions.contains(m.key);
                      return _missionCard(m, done);
                    },
                  ),
                ),
        ]),
      ),
    );
  }

  Widget _missionCard(_Mission m, bool done) {
    return GestureDetector(
      onTap: done ? null : () async {
        HapticFeedback.lightImpact();
        if (m.route != null) {
          await Navigator.pushNamed(context, m.route!);
          _loadMissions();
        } else {
          final ok = await RewardsService.instance.completeMission(
            m.key, xpAmount: m.xp, coinsAmount: m.coins);
          if (ok && mounted) setState(() => _doneMissions.add(m.key));
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.45 : 1.0,
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: done
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      m.grad[0].withValues(alpha: 0.22),
                      m.grad[1].withValues(alpha: 0.14),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: done
                  ? Colors.white.withValues(alpha: 0.07)
                  : m.grad[0].withValues(alpha: 0.4),
              width: done ? 1 : 1.2,
            ),
            boxShadow: done
                ? []
                : [
                    BoxShadow(
                      color: m.grad[0].withValues(alpha: 0.15),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(m.icon, style: const TextStyle(fontSize: 26)),
                if (done)
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.success, width: 1.5),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 12),
                  )
                else
                  ShaderMask(
                    shaderCallback: (r) =>
                        LinearGradient(colors: m.grad).createShader(r),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ),
              ]),
              const Spacer(),
              Text(m.label,
                  style: GoogleFonts.montserrat(
                      color: done ? Colors.white30 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.3),
                  maxLines: 2),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (r) =>
                    LinearGradient(colors: done
                        ? [Colors.white24, Colors.white12]
                        : m.grad).createShader(r),
                child: Text(m.reward,
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SERVICES ─────────────────────────────────────────────────────────────────
  Widget _buildServices() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 14),
            child: _label('🎯 Mes services Creator'),
          ),
          SizedBox(
            height: 190,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _serviceCard(
                  '🎥', 'UGC Creator',
                  'Photos & vidéos\npour les marques',
                  [const Color(0xFF1A56FF), const Color(0xFF6D28D9)],
                ),
                const SizedBox(width: 12),
                _serviceCard(
                  '📢', 'Affiliate',
                  'Liens & commissions\nsur chaque vente',
                  [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
                ),
                const SizedBox(width: 12),
                _serviceCard(
                  '📣', 'Influenceur',
                  'Promeut des marques\nà ta communauté',
                  [const Color(0xFFFF6B35), const Color(0xFFFF8E53)],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _serviceCard(
      String icon, String title, String sub, List<Color> grad) =>
      Container(
        width: 155,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [grad[0].withValues(alpha: 0.25), grad[1].withValues(alpha: 0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: grad[0].withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: grad[0].withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // icon in gradient circle
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: grad[0].withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const Spacer(),
          Text(title,
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub,
              style: GoogleFonts.montserrat(
                  color: Colors.white54,
                  fontSize: 10,
                  height: 1.4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [grad[0].withValues(alpha: 0.3),
                   grad[1].withValues(alpha: 0.3)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: grad[0].withValues(alpha: 0.4)),
            ),
            child: Text('Bientôt disponible',
                style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ),
        ]),
      );

  // ── LEVEL ROAD ───────────────────────────────────────────────────────────────
  Widget _buildLevelRoad() {
    final xp      = RewardsService.instance.xp.value;
    final current = RewardsService.instance.level.value;
    const levels  = LincooLevel.values;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('📈 Ton parcours Creator'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: levels.map((l) {
                final isNow  = l == current;
                final done   = l.minXp <= xp;
                final isLast = l == levels.last;
                return _levelRow(l, isNow, done, isLast);
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _levelRow(LincooLevel l, bool isNow, bool done, bool isLast) {
    final dot = isNow
        ? Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [_neonTeal, _neonBlue]),
              boxShadow: [
                BoxShadow(
                  color: _neonTeal.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          )
        : done
            ? Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 9),
              )
            : Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5)),
              );

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // timeline
        Column(children: [
          dot,
          if (!isLast)
            Expanded(
              child: Container(
                width: 1.5,
                color: done
                    ? AppColors.success.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Row(children: [
              Text(l.label.split(' ').first,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l.label.split(' ').skip(1).join(' '),
                      style: GoogleFonts.montserrat(
                          color: done ? Colors.white : Colors.white24,
                          fontSize: 13,
                          fontWeight:
                              isNow ? FontWeight.w900 : FontWeight.w600)),
                  Text('Dès ${l.minXp} XP',
                      style: GoogleFonts.montserrat(
                          color: Colors.white24, fontSize: 10)),
                ]),
              ),
              if (isNow)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_neonTeal, _neonBlue]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _neonTeal.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text('Actuel',
                      style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── CAMPAIGNS ────────────────────────────────────────────────────────────────
  Widget _buildCampaigns() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('🏢 Campagnes & Marques'),
          const SizedBox(height: 14),
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  _neonPurp.withValues(alpha: 0.12),
                  _neonBlue.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _neonPurp.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: _neonPurp.withValues(alpha: 0.06),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [_neonBlue, _neonPurp],
                      ).createShader(r),
                      child: const Icon(Icons.campaign_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 10),
                    Text('Campagnes & Marques',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Bientôt — les marques te contacteront\ndirectement depuis l\'app.',
                        style: GoogleFonts.montserrat(
                            color: Colors.white38,
                            fontSize: 11,
                            height: 1.5),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2));

  Widget _glassButton({
    required Widget child,
    VoidCallback? onTap,
    Color? color,
    Color? border,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: border ?? Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      );
}

// ── Ambient blurred orbs ────────────────────────────────────────────────────────
class _AmbientOrbs extends StatelessWidget {
  const _AmbientOrbs();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return CustomPaint(
      painter: _OrbsPainter(w),
    );
  }
}

class _OrbsPainter extends CustomPainter {
  final double w;
  _OrbsPainter(this.w);

  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset c, double r, Color col) {
      final p = Paint()
        ..color = col
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      canvas.drawCircle(c, r, p);
    }

    orb(Offset(w * 0.85, 80),   140, _orb1);
    orb(Offset(w * 0.1,  280),  110, _orb2);
    orb(Offset(w * 0.6,  600),  130, _orb3);
    orb(Offset(w * 0.2,  900),  100, _orb1.withValues(alpha: 0.15));
  }

  @override
  bool shouldRepaint(_OrbsPainter old) => old.w != w;
}

// ── Mission model ──────────────────────────────────────────────────────────────
class _Mission {
  final String       key;
  final String       icon;
  final String       label;
  final String       reward;
  final int          xp;
  final int          coins;
  final String?      route;
  final List<Color>  grad;

  const _Mission(this.key, this.icon, this.label, this.reward,
      {required this.xp, required this.coins, this.route,
       required this.grad});
}

