import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Ecran d'accueil "MomCare" : en-tete corail avec anneau de progression
/// de la grossesse + cartes (partenaire, suivi sante, MomCare TV).
/// Recree proprement le design maquette (sans les images reseau Codeless).
class MomCareHome extends StatelessWidget {
  final int currentWeek;
  const MomCareHome({super.key, required this.currentWeek});

  @override
  Widget build(BuildContext context) {
    final week = currentWeek <= 0 ? 1 : currentWeek;
    final int clampedWeek = week.clamp(1, 40).toInt();
    final int daysToGo = ((40 - clampedWeek) * 7).clamp(0, 280).toInt();
    final double donePercent = clampedWeek / 40 * 100;

    return Column(
      children: [
        _header(clampedWeek, daysToGo, donePercent),
        const SizedBox(height: 16),
        _partnerCard(),
        const SizedBox(height: 16),
        _trackingCard(),
        const SizedBox(height: 16),
        _momCareTvCard(),
      ],
    );
  }

  // ---- En-tete corail avec anneau de progression ----
  Widget _header(int week, int daysToGo, double donePercent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8695F), Color(0xFFF08D7F)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Home', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Icon(Icons.search, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _sideStat('${donePercent.toStringAsFixed(1)}%', 'DONE'),
              SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(
                  painter: _RingPainter(progress: week / 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('WEEK', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2)),
                        Text('$week', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600, height: 1.0)),
                        const SizedBox(height: 2),
                        Text('semaines', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              _sideStat('$daysToGo', 'JOURS RESTANTS'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Plus', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: Colors.white, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideStat(String value, String label) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ---- Carte "Pour le partenaire" ----
  Widget _partnerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4716A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 3), blurRadius: 6)],
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text('Pour le partenaire\net les proches', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
          ),
          Icon(Icons.favorite, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  // ---- Carte "Suivi sante maman" ----
  Widget _trackingCard() {
    return Container(
      height: 120,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 3), blurRadius: 6)],
        gradient: const LinearGradient(colors: [Color(0xFFFF7068), Color(0xFFE86BA7)]),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.85,
              child: Image.asset('assets/images/yemma/foetus.png', width: 130, height: 130, fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.pregnant_woman, color: Colors.white24, size: 90)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  width: 150,
                  child: Text('Suivi de la sante\nde maman', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Suivre', style: TextStyle(color: Color(0xFFE86BA7), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Carte "MomCare TV" ----
  Widget _momCareTvCard() {
    return Container(
      height: 110,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 3), blurRadius: 6)],
        gradient: const LinearGradient(colors: [Color(0xFF3A94FF), Color(0xFF69E4FF)]),
      ),
      child: Stack(
        children: [
          const Positioned(right: 16, top: 20, child: Icon(Icons.play_circle_fill, color: Colors.white38, size: 72)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MomCare TV', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Regarder', style: TextStyle(color: Color(0xFF3A94FF), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
