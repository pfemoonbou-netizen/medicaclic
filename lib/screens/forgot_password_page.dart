import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Veuillez entrer votre adresse email.');
      return;
    }
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _error = 'Format d\'email invalide.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() => _sent = true);
        _ctrl.reset();
        _ctrl.forward();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      size: 20, color: AppColors.nearBlack),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _sent ? _successView() : _formView(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _formView() => ListView(
        key: const ValueKey('form'),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          // Icon badge
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.accent,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppColors.nearBlack, size: 34),
          ),

          const SizedBox(height: 24),

          Text('Mot de passe\noublié ?',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.5)),

          const SizedBox(height: 10),

          Text(
            'Entrez votre adresse email pour recevoir\nun lien de réinitialisation.',
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 14, height: 1.6),
          ),

          const SizedBox(height: 32),

          AppTextField(
            label: 'Adresse email',
            hint: 'exemple@email.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onEditingComplete: _send,
            prefixIcon: const Icon(Icons.email_outlined,
                size: 18, color: AppColors.grayLight),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
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

          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Envoyer le lien',
            loading: _loading,
            onPressed: _send,
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Text('Retour à la connexion',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );

  Widget _successView() => Padding(
        key: const ValueKey('success'),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success badge
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  size: 50, color: AppColors.success),
            ),

            const SizedBox(height: 28),

            Text('Email envoyé !',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),

            const SizedBox(height: 12),

            Text(
              'Vérifiez votre boîte mail et suivez le lien '
              'pour réinitialiser votre mot de passe.\n\n'
              'Vérifiez aussi vos spams si vous ne trouvez pas l\'email.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 14, height: 1.65),
            ),

            const SizedBox(height: 40),

            PrimaryButton(
              label: 'Retour à la connexion',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => setState(() {
                _sent = false;
                _ctrl.reset();
                _ctrl.forward();
              }),
              child: Text('Renvoyer l\'email',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
