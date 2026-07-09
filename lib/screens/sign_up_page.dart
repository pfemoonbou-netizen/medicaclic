import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';
import '../models/app_user.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Contact method toggle
  bool _usePhone = false;

  // Controllers
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Visibility toggles
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  // Profile fields
  DateTime? _birthDate;
  String?   _gender; // 'female' | 'male'

  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _dobDisplay {
    if (_birthDate == null) return '';
    final d = _birthDate!;
    final dd  = d.day.toString().padLeft(2, '0');
    final mm  = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColors.nearBlack,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.nearBlack),
          ),
        ),
        child: child!,
      ),
    );
    if (result != null && mounted) setState(() => _birthDate = result);
  }

  // Validates and submits
  Future<void> _submit() async {
    setState(() { _error = null; });

    final contact = _usePhone
        ? _phoneCtrl.text.trim()
        : _emailCtrl.text.trim();

    // Validation
    if (contact.isEmpty) {
      setState(() => _error = _usePhone
          ? 'Veuillez entrer votre numéro de téléphone.'
          : 'Veuillez entrer votre adresse e-mail.');
      return;
    }
    if (!_usePhone &&
        !RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(contact)) {
      setState(() => _error = 'Format e-mail invalide (ex : nom@gmail.com).');
      return;
    }
    if (_usePhone && contact.length < 9) {
      setState(() => _error = 'Numéro de téléphone invalide.');
      return;
    }
    if (_passCtrl.text.length < 8) {
      setState(() => _error = 'Mot de passe : minimum 8 caractères.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (_birthDate == null) {
      setState(() => _error = 'Veuillez entrer votre date de naissance.');
      return;
    }
    if (_gender == null) {
      setState(() => _error = 'Veuillez sélectionner votre genre.');
      return;
    }

    setState(() => _loading = true);
    try {
      // For phone: use internal email so Supabase doesn't require OTP
      final email = _usePhone
          ? '${contact.replaceAll(RegExp(r'[^0-9]'), '')}@users.lincoo.dz'
          : contact;

      final res = await Supabase.instance.client.auth.signUp(
        email:    email,
        password: _passCtrl.text,
      );

      if (res.user != null) {
        final uid = res.user!.id;
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id':                  uid,
            'email':               _usePhone ? null : contact,
            'telephone':           _usePhone ? contact : null,
            'birth_date':          _birthDate!.toIso8601String().split('T').first,
            'gender':              _gender,
            'pro_role':            'none',
            'pro_status':          'none',
            'onboarding_complete': false,
          }, onConflict: 'id');
        } catch (_) {}

        UserSession.instance.update(AppUser(
          id:          uid,
          email:       email,
          displayName: '',
        ));
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/feed');
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      setState(() => _error = msg.contains('rate')
          ? 'Trop de tentatives. Réessayez dans quelques minutes.'
          : msg.contains('already registered') || msg.contains('already been registered')
              ? _usePhone
                  ? 'Ce numéro est déjà utilisé.'
                  : 'Adresse e-mail déjà utilisée.'
              : msg.contains('invalid email') || msg.contains('invalid format')
                  ? 'Adresse invalide.'
                  : msg.contains('password')
                      ? 'Mot de passe trop faible. Minimum 8 caractères.'
                      : 'Erreur : ${e.message}');
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              children: [
                // Title
                Text('Créez votre\ncompte',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack, fontSize: 28,
                        fontWeight: FontWeight.w900, height: 1.2,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Rejoignez Lincoo en quelques secondes.',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: AppColors.gray, height: 1.5)),
                const SizedBox(height: 28),

                // ── Toggle Email / Téléphone ──────────────────────────────
                _contactToggle(),
                const SizedBox(height: 16),

                // ── Contact field ─────────────────────────────────────────
                if (!_usePhone) ...[
                  _field(
                    label: 'Adresse e-mail',
                    hint: 'exemple@gmail.com',
                    ctrl: _emailCtrl,
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    action: TextInputAction.next,
                  ),
                ] else ...[
                  _field(
                    label: 'Numéro de téléphone',
                    hint: '07 xx xx xx xx',
                    ctrl: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    action: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.allow(
                        RegExp(r'[\d\s\+\-\(\)]'))],
                  ),
                ],
                const SizedBox(height: 14),

                // ── Password ──────────────────────────────────────────────
                _passField(
                  label: 'Mot de passe',
                  hint: 'Minimum 8 caractères',
                  ctrl: _passCtrl,
                  obscure: _obscurePass,
                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                ),
                const SizedBox(height: 14),

                // ── Confirm password ──────────────────────────────────────
                _passField(
                  label: 'Confirmer le mot de passe',
                  hint: 'Répétez le mot de passe',
                  ctrl: _confirmCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 14),

                // ── Date de naissance ─────────────────────────────────────
                _dobField(),
                const SizedBox(height: 20),

                // ── Genre ─────────────────────────────────────────────────
                _genderField(),
                const SizedBox(height: 28),

                // ── Error ─────────────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    margin: const EdgeInsets.only(bottom: 16),
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
                                color: AppColors.error, fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ),
                ],

                // ── Submit ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nearBlack,
                      disabledBackgroundColor: AppColors.nearBlack.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Créer mon compte',
                            style: GoogleFonts.montserrat(
                                color: Colors.white, fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Login link ────────────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Déjà un compte ? ',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: AppColors.gray)),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('Se connecter',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: AppColors.nearBlack,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            size: 20, color: AppColors.nearBlack),
        onPressed: () => Navigator.pop(context),
      ),
      const Spacer(),
      Text('Inscription',
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 15,
              fontWeight: FontWeight.w800)),
      const Spacer(),
      const SizedBox(width: 48),
    ]),
  );

  // ── Email / Phone toggle ────────────────────────────────────────────────────

  Widget _contactToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _toggleTab('Email', Icons.email_outlined, !_usePhone),
        _toggleTab('Téléphone', Icons.phone_outlined, _usePhone),
      ]),
    );
  }

  Widget _toggleTab(String label, IconData icon, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _usePhone = label == 'Téléphone';
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 15,
                color: active ? AppColors.nearBlack : AppColors.gray),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: active ? AppColors.nearBlack : AppColors.gray,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  // ── Input fields ───────────────────────────────────────────────────────────

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          textInputAction: action,
          inputFormatters: inputFormatters,
          style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.nearBlack),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
                fontSize: 13, color: AppColors.grayLight),
            prefixIcon: Icon(icon, size: 18, color: AppColors.grayLight),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ]);
  }

  Widget _passField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.nearBlack),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
                fontSize: 13, color: AppColors.grayLight),
            prefixIcon: const Icon(Icons.lock_outline,
                size: 18, color: AppColors.grayLight),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.grayLight, size: 18,
              ),
              onPressed: onToggle,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ]);
  }

  // ── Date de naissance ──────────────────────────────────────────────────────

  Widget _dobField() {
    final hasDate = _birthDate != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Date de naissance',
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: _pickDate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: hasDate ? AppColors.nearBlack : AppColors.lightGray),
          ),
          child: Row(children: [
            Icon(Icons.cake_outlined,
                size: 18,
                color: hasDate ? AppColors.nearBlack : AppColors.grayLight),
            const SizedBox(width: 12),
            Text(
              hasDate ? _dobDisplay : 'JJ / MM / AAAA',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: hasDate ? AppColors.nearBlack : AppColors.grayLight,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400),
            ),
            const Spacer(),
            if (hasDate)
              GestureDetector(
                onTap: () => setState(() => _birthDate = null),
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.grayLight),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grayLight, size: 20),
          ]),
        ),
      ),
    ]);
  }

  // ── Genre ──────────────────────────────────────────────────────────────────

  Widget _genderField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Genre',
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _genderOption('Femme', 'female', Icons.woman_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _genderOption('Homme', 'male', Icons.man_outlined)),
      ]),
    ]);
  }

  Widget _genderOption(String label, String value, IconData icon) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.nearBlack : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.nearBlack : AppColors.lightGray,
              width: selected ? 1.5 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 20,
              color: selected ? Colors.white : AppColors.gray),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: selected ? Colors.white : AppColors.nearBlack,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
