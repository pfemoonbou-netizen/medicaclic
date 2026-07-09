import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Points & Récompenses',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined,
                color: AppColors.nearBlack, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildPointsCard(),
          _buildLevelProgress(),
          const SizedBox(height: 8),
          _buildSectionTitle('Comment gagner des points'),
          _buildEarningWays(),
          const SizedBox(height: 8),
          _buildSectionTitle('Mes récompenses disponibles'),
          _buildRewardsList(context),
          const SizedBox(height: 8),
          _buildSectionTitle('Historique des points'),
          _buildPointsHistory(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Points hero card ─────────────────────────────────────────────────────

  Widget _buildPointsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF292526), Color(0xFF6E1128)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x336E1128),
              blurRadius: 20,
              offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40, bottom: -30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.card_giftcard,
                    color: Color(0xFFFFC107), size: 20),
                const SizedBox(width: 8),
                Text('LINCOO POINTS',
                    style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 12),
              Text('1 250',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.0)),
              Text('points disponibles',
                  style: GoogleFonts.montserrat(
                      color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 16),
              Row(children: [
                _pointsBadge('≈ 125 DA', 'de réduction'),
                const SizedBox(width: 12),
                _pointsBadge('Niveau', 'Silver ✦'),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pointsBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.montserrat(
                  color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Level progress ───────────────────────────────────────────────────────

  Widget _buildLevelProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Niveau actuel : Silver',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text('750 pts pour Gold',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 1250 / 2000,
              minHeight: 8,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E1128)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _levelDot('Bronze', false),
              _levelDot('Silver', true),
              _levelDot('Gold', false),
              _levelDot('Platinum', false),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _levelDot(String label, bool active) {
    return Column(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF6E1128) : AppColors.lightGray,
          border: Border.all(
              color: active ? const Color(0xFF6E1128) : AppColors.lightGray,
              width: 2),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: GoogleFonts.montserrat(
              color: active ? AppColors.nearBlack : AppColors.gray,
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
    ]);
  }

  // ── Section title ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 15,
              fontWeight: FontWeight.w800)),
    );
  }

  // ── Earning ways ─────────────────────────────────────────────────────────

  Widget _buildEarningWays() {
    const ways = [
      _EarnWay(Icons.shopping_bag_outlined, 'Achat', '+10 pts/100 DA', Color(0xFF347EFB)),
      _EarnWay(Icons.favorite_outline, 'J\'aimer', '+2 pts', Color(0xFFE31E1E)),
      _EarnWay(Icons.star_outline, 'Avis', '+15 pts', Color(0xFFFFC107)),
      _EarnWay(Icons.share_outlined, 'Partager', '+5 pts', Color(0xFF4CAF50)),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: ways.length,
        itemBuilder: (_, i) {
          final w = ways[i];
          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: w.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: w.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(w.icon, color: w.color, size: 22),
                const SizedBox(height: 6),
                Text(w.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(w.pts,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        color: w.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Rewards list ─────────────────────────────────────────────────────────

  Widget _buildRewardsList(BuildContext context) {
    const rewards = [
      _Reward('Réduction 50 DA', '500 points', true, Icons.local_offer_outlined),
      _Reward('Livraison gratuite', '800 points', true, Icons.local_shipping_outlined),
      _Reward('Réduction 200 DA', '2000 points', false, Icons.discount_outlined),
      _Reward('Cadeau surprise', '5000 points', false, Icons.card_giftcard_outlined),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: rewards.length,
      itemBuilder: (_, i) {
        final r = rewards[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: r.unlocked
                    ? const Color(0xFF6E1128).withValues(alpha: 0.3)
                    : AppColors.lightGray),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: r.unlocked
                    ? const Color(0xFF6E1128).withValues(alpha: 0.1)
                    : AppColors.bgGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(r.icon,
                  color: r.unlocked
                      ? const Color(0xFF6E1128)
                      : AppColors.gray,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(r.title,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(r.cost,
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 11)),
              ]),
            ),
            if (r.unlocked)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Récompense "${r.title}" utilisée !'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E1128),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text('Utiliser',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline,
                    size: 14, color: AppColors.gray),
              ),
          ]),
        );
      },
    );
  }

  // ── Points history ───────────────────────────────────────────────────────

  Widget _buildPointsHistory() {
    const history = [
      _HistoryItem('Achat LOOLET SCRAF', '+140 pts', '15 juin 2026', true),
      _HistoryItem('Avis laissé', '+15 pts', '12 juin 2026', true),
      _HistoryItem('Partage post', '+5 pts', '10 juin 2026', true),
      _HistoryItem('Réduction utilisée', '-500 pts', '8 juin 2026', false),
      _HistoryItem('Achat Femmedz', '+90 pts', '5 juin 2026', true),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: h.isEarned
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                h.isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: h.isEarned ? Colors.green : Colors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(h.label,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(h.date,
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 11)),
              ]),
            ),
            Text(h.points,
                style: GoogleFonts.montserrat(
                    color: h.isEarned ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ]),
        );
      },
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class _EarnWay {
  final IconData icon;
  final String label;
  final String pts;
  final Color color;
  const _EarnWay(this.icon, this.label, this.pts, this.color);
}

class _Reward {
  final String title;
  final String cost;
  final bool unlocked;
  final IconData icon;
  const _Reward(this.title, this.cost, this.unlocked, this.icon);
}

class _HistoryItem {
  final String label;
  final String points;
  final String date;
  final bool isEarned;
  const _HistoryItem(this.label, this.points, this.date, this.isEarned);
}
