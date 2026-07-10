import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _darkNavy = Color(0xFF101522);

  int _tabIndex = 0; // 0 = Email, 1 = Téléphone
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  DateTime? _birthDate;
  String? _genre;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  InputDecoration _fieldDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA0A7B0), fontSize: 15),
      prefixIcon: Icon(icon, color: const Color(0xFFA0A7B0), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9F9FB),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _darkNavy, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? _darkNavy : const Color(0xFFA0A7B0)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? _darkNavy : const Color(0xFFA0A7B0),
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genreButton(String label, IconData icon) {
    final active = _genre == label;
    return GestureDetector(
      onTap: () => setState(() => _genre = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: active ? _darkNavy : const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? _darkNavy : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? Colors.white : const Color(0xFF707684)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF707684),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    final emailOrPhone = _tabIndex == 0 ? _email.text.trim() : _phone.text.trim();

    if (emailOrPhone.isEmpty) {
      _snack(_tabIndex == 0 ? 'Entrez votre adresse e-mail' : 'Entrez votre numéro de téléphone');
      return;
    }
    if (_tabIndex == 1) {
      _snack('La connexion par téléphone sera disponible prochainement');
      return;
    }
    if (_password.text.length < 8) {
      _snack('Le mot de passe doit contenir au moins 8 caractères');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      _snack('Les mots de passe ne correspondent pas');
      return;
    }
    if (_birthDate == null) {
      _snack('Veuillez entrer votre date de naissance');
      return;
    }
    if (_genre == null) {
      _snack('Veuillez sélectionner votre genre');
      return;
    }

    final birthDateStr =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

    final ok = await auth.signup(
      '',
      emailOrPhone,
      _password.text,
      birthDate: birthDateStr,
      gender: _genre,
    );
    if (ok && mounted) context.go('/home');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _darkNavy, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
        title: const Text(
          'Inscription',
          style: TextStyle(color: _darkNavy, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Créez votre\ncompte',
                style: TextStyle(color: _darkNavy, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rejoignez Medicaclic en quelques secondes.',
                style: TextStyle(color: Color(0xFF707684), fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Tab switcher
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    _tab(0, Icons.mail_outline, 'Email'),
                    _tab(1, Icons.phone_outlined, 'Téléphone'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email or Phone
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _tabIndex == 0
                    ? _labeledField(
                        'Adresse e-mail',
                        TextField(
                          key: const ValueKey('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _fieldDecoration('exemple@gmail.com', Icons.mail_outline),
                        ),
                      )
                    : _labeledField(
                        'Numéro de téléphone',
                        TextField(
                          key: const ValueKey('phone'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration('+213 6XX XXX XXX', Icons.phone_outlined),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Password
              _labeledField(
                'Mot de passe',
                TextField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: _fieldDecoration(
                    'Minimum 8 caractères',
                    Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFFA0A7B0),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password
              _labeledField(
                'Confirmer le mot de passe',
                TextField(
                  controller: _confirmPassword,
                  obscureText: _obscureConfirm,
                  decoration: _fieldDecoration(
                    'Répétez le mot de passe',
                    Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFFA0A7B0),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Birth date
              _labeledField(
                'Date de naissance',
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Color(0xFFA0A7B0), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _birthDate == null
                                ? 'JJ / MM / AAAA'
                                : '${_birthDate!.day.toString().padLeft(2, '0')} / ${_birthDate!.month.toString().padLeft(2, '0')} / ${_birthDate!.year}',
                            style: TextStyle(
                              color: _birthDate == null ? const Color(0xFFA0A7B0) : _darkNavy,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFA0A7B0)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Genre
              _labeledField(
                'Genre',
                Row(
                  children: [
                    Expanded(child: _genreButton('Femme', Icons.female)),
                    const SizedBox(width: 12),
                    Expanded(child: _genreButton('Homme', Icons.male)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              Consumer<AuthProvider>(
                builder: (context, auth, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : () => _submit(auth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Créer mon compte',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Login link
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Color(0xFF707684), fontSize: 15),
                  children: [
                    const TextSpan(text: 'Déjà inscrit? '),
                    TextSpan(
                      text: 'Se connecter',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()..onTap = () => context.go('/login'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
