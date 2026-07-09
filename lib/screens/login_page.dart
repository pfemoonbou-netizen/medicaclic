import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/app_user.dart';
import '../services/user_session.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await UserSession.instance.initialize();
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
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      setState(() => _error = msg.contains('invalid')
          ? 'Email ou mot de passe incorrect.'
          : msg.contains('rate')
              ? 'Trop de tentatives. Réessayez dans quelques minutes.'
              : e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepPurple,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Hero (brand) ─────────────────────────────────────────
                  _buildHero(),

                  // ── Form card ────────────────────────────────────────────
                  Transform.translate(
                    offset: const Offset(0, -26),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                      Text('Connexion',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),

                      const SizedBox(height: 6),

                      Text('Bienvenue ! Entrez vos identifiants.',
                          style: GoogleFonts.montserrat(
                              color: AppColors.gray,
                              fontSize: 14,
                              height: 1.5)),

                      const SizedBox(height: 32),

                      AppTextField(
                        label: 'Email',
                        hint: 'exemple@email.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.email_outlined,
                            size: 18, color: AppColors.grayLight),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Champ requis' : null,
                      ),

                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Mot de passe',
                        hint: '••••••••',
                        controller: _passCtrl,
                        obscure: _obscure,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _login,
                        prefixIcon: const Icon(Icons.lock_outline,
                            size: 18, color: AppColors.grayLight),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min. 6 caractères'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.grayLight,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/forgot-password'),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8)),
                          child: Text('Mot de passe oublié ?',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.deepPurple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.25)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: GoogleFonts.montserrat(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: 'Se connecter',
                        loading: _loading,
                        onPressed: _login,
                      ),

                      const SizedBox(height: 28),

                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Pas encore de compte ? ',
                                style: GoogleFonts.montserrat(
                                    color: AppColors.gray, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/signup'),
                              child: Text('Créer un compte',
                                  style: GoogleFonts.montserrat(
                                      color: AppColors.nearBlack,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero (brand header, replaces the old plain top bar) ─────────────────────
  Widget _buildHero() {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 236,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 4, top: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.brandGradient.createShader(bounds),
                        child: Text('L',
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('lincoo',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
