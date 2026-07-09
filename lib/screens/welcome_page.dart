import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Stack(children: [
          // Glow orb — top right
          Positioned(
            top: -130, right: -90,
            child: Container(
              width: 380, height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: 0.13),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Glow orb — bottom left
          Positioned(
            bottom: 40, left: -90,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.purple.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(children: [
                    const Spacer(flex: 2),

                    // Logo mark
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.38),
                            blurRadius: 36,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text('L',
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 36,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text('lincoo',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 7)),

                    const SizedBox(height: 6),

                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue],
                      ).createShader(b),
                      child: Text('Connect. Learn. Grow.',
                          style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 2.8,
                              fontWeight: FontWeight.w600)),
                    ),

                    const Spacer(flex: 2),

                    // Category pills
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Mode', 'Beauté', 'Lifestyle', 'Tendances'].map((t) =>
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.11),
                                    width: 1),
                              ),
                              child: Text(t,
                                  style: GoogleFonts.montserrat(
                                      color:
                                          Colors.white.withValues(alpha: 0.70),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ).toList(),
                    ),

                    const SizedBox(height: 28),

                    // Hero headline
                    Text(
                      'Découvrez la mode\nalgérienne.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Achetez, vendez et inspirez\nvotre communauté.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 14,
                          height: 1.65),
                    ),

                    const Spacer(flex: 3),

                    // Primary CTA
                    _AnimatedCTA(
                      label: 'Créer un compte',
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      useGradient: true,
                    ),

                    const SizedBox(height: 12),

                    // Secondary CTA
                    _AnimatedCTA(
                      label: 'Se connecter',
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      useGradient: false,
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'En continuant, vous acceptez nos Conditions d\'utilisation',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.22),
                          fontSize: 10,
                          height: 1.6),
                    ),

                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AnimatedCTA extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool useGradient;

  const _AnimatedCTA({
    required this.label,
    required this.onTap,
    required this.useGradient,
  });

  @override
  State<_AnimatedCTA> createState() => _AnimatedCTAState();
}

class _AnimatedCTAState extends State<_AnimatedCTA>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.useGradient
                ? const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.useGradient
                ? null
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: widget.useGradient
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.16), width: 1.5),
            boxShadow: widget.useGradient
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.33),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.montserrat(
                  color: widget.useGradient
                      ? AppColors.nearBlack
                      : Colors.white.withValues(alpha: 0.88),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2),
            ),
          ),
        ),
      ),
    );
  }
}
