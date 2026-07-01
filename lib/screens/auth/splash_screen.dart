import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

const _kAccent = Color(0xFF1AA88F);
const _kBackground = Color(0xFF0A1614);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        context.go(auth.isLoggedIn ? '/home' : '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: -80, left: -60, child: _glow(220)),
          Positioned(bottom: -100, right: -80, child: _glow(260)),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(child: _dashedLine()),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1F1B),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 4)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_heart_outlined, color: _kAccent, size: 42),
                    const SizedBox(height: 6),
                    Text('Medica clic', style: TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Medica Clic', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  FadeTransition(
                    opacity: _cursorController,
                    child: Container(width: 3, height: 30, color: _kAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(width: 120, height: 2, color: _kAccent.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              const Text('Votre santé en un clic', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text('صحتك في نقرة واحدة', style: TextStyle(color: _kAccent.withValues(alpha: 0.85), fontSize: 14)),
              ),
            ],
          ),
          const Positioned(
            bottom: 28,
            child: Text('v1.0.0 — Algérie 🇩🇿', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _kAccent.withValues(alpha: 0.08)),
    );
  }

  Widget _dashedLine() {
    return SizedBox(
      width: 220,
      height: 16,
      child: CustomPaint(
        painter: _DashedLinePainter(color: Colors.white24),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, midY), Offset(startX + dashWidth, midY), paint);
      startX += dashWidth + dashSpace;
    }

    final peakPaint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width / 2 - 14, midY)
      ..lineTo(size.width / 2, midY - 10)
      ..lineTo(size.width / 2 + 14, midY);
    canvas.drawPath(path, peakPaint);
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
