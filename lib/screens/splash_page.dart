import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';
import '../models/app_user.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    // Pas connecté → écran d'accueil
    if (session == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    if (!mounted) return;
    final user = UserSession.instance.current;

    final route = switch (user.proStatus) {
      ProStatus.pending  => '/pending',
      ProStatus.rejected => '/welcome',
      ProStatus.verified => '/feed',
      _ => switch (user.proRole) {
          ProRole.seller  => '/complete-seller',
          ProRole.creator => '/complete-creator',
          ProRole.company => '/complete-company',
          _               => '/feed',
        },
    };

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Stack(children: [
          // Glow orbs (brand feel)
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Center content
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with brand gradient
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'L',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 46,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Brand name
                  Text(
                    'lincoo',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3),
                  ),
                  const SizedBox(height: 6),
                  // Brand tagline
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.accent, AppColors.blue],
                    ).createShader(bounds),
                    child: Text(
                      'Connect. Learn. Grow.',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.accent.withValues(alpha: 0.7),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
