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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image de fond plein écran ──
          Image.asset(
            'assets/images/welcome_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5EEF0), Color(0xFFF8F2F5)],
                ),
              ),
            ),
          ),

          // ── Dégradé blanc en bas pour lisibilité ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7],
                ),
              ),
            ),
          ),

          // ── Contenu par-dessus ──
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(children: [
                  const SizedBox(height: 40),

                  // ── Logo LINCOO ──
                  _buildLogo(),

                  const SizedBox(height: 8),

                  // ── Slogan ──
                  Text(
                    'Découvrez, connectez, achetez.',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF6B5B6E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 4 icônes ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconCircle(Icons.shopping_bag_outlined),
                      const SizedBox(width: 16),
                      _iconCircle(Icons.play_circle_outline),
                      const SizedBox(width: 16),
                      _iconCircle(Icons.favorite_outline),
                      const SizedBox(width: 16),
                      _iconCircle(Icons.chat_bubble_outline),
                    ],
                  ),

                  const Spacer(),

                  // ── "Le commerce autrement." ──
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                        text: 'Le commerce\n',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF2D1F3D),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      TextSpan(
                        text: 'autrement.',
                        style: GoogleFonts.dancingScript(
                          color: AppColors.deepPurple,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── Boutons CTA ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(children: [
                      _AnimatedCTA(
                        label: 'Créer un compte',
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 12),
                      _AnimatedCTA(
                        label: 'Se connecter',
                        onTap: () => Navigator.pushNamed(context, '/login'),
                        isPrimary: false,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'En continuant, vous acceptez nos Conditions d\'utilisation',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF9B8A9E),
                      fontSize: 10,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 14),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deepPurple, Color(0xFF5B21B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.shopping_bag_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'LINCOO',
          style: GoogleFonts.montserrat(
            color: AppColors.deepPurple,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: AppColors.deepPurple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Icon(icon, color: AppColors.deepPurple, size: 20),
    );
  }
}

class _AnimatedCTA extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AnimatedCTA({
    required this.label,
    required this.onTap,
    required this.isPrimary,
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
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [AppColors.deepPurple, Color(0xFF5B21B6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.isPrimary
                ? null
                : Border.all(color: AppColors.deepPurple.withValues(alpha: 0.3), width: 1.5),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.deepPurple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.montserrat(
                color: widget.isPrimary
                    ? Colors.white
                    : AppColors.deepPurple,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
