import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_care_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _specialty = TextEditingController();
  final _phone = TextEditingController();
  bool _obscure = true;
  String _role = 'utilisateur';
  String? _providerCategoryId;
  final _homeCare = HomeCareProvider();

  @override
  void initState() {
    super.initState();
    _homeCare.addListener(_onHomeCareChanged);
  }

  void _onHomeCareChanged() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _specialty.dispose();
    _phone.dispose();
    _homeCare.removeListener(_onHomeCareChanged);
    _homeCare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(onTap: () => context.go('/login'), child: const Icon(Icons.arrow_back, color: AppColors.primary)),
              const SizedBox(height: 20),
              Text('Inscription', style: AppTextStyles.heading1),
              const SizedBox(height: 10),
              Text('Creez un nouveau compte', style: AppTextStyles.bodySmall),
              const SizedBox(height: 40),
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'Nom complet', prefixIcon: Icon(Icons.person_outlined))),
              const SizedBox(height: 15),
              TextField(controller: _email, decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
              ),
              const SizedBox(height: 30),
              Text('Type de compte', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _roleTile('utilisateur', 'Utilisateur', Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _roleTile('prestataire', 'Prestataire à domicile', Icons.medical_services_outlined)),
                ],
              ),
              if (_role == 'prestataire') ...[
                const SizedBox(height: 20),
                if (_homeCare.isLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: CircularProgressIndicator()))
                else
                  DropdownButtonFormField<String>(
                    initialValue: _providerCategoryId,
                    decoration: const InputDecoration(hintText: 'Catégorie de service', prefixIcon: Icon(Icons.category_outlined)),
                    items: _homeCare.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (value) => setState(() => _providerCategoryId = value),
                  ),
                const SizedBox(height: 15),
                TextField(controller: _specialty, decoration: const InputDecoration(hintText: 'Spécialité (ex: Infirmière diplômée)', prefixIcon: Icon(Icons.badge_outlined))),
                const SizedBox(height: 15),
                TextField(controller: _phone, decoration: const InputDecoration(hintText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
              ],
              const SizedBox(height: 30),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : () async {
                      final ok = await auth.signup(
                        _name.text,
                        _email.text,
                        _password.text,
                        role: _role,
                        providerCategoryId: _providerCategoryId,
                        providerSpecialty: _specialty.text.trim(),
                        providerPhone: _phone.text.trim(),
                      );
                      if (ok && context.mounted) context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.white))) : Text("S'inscrire", style: AppTextStyles.buttonText),
                  ),
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => auth.errorMessage == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Deja inscrit? ', style: AppTextStyles.body),
                  GestureDetector(onTap: () => context.go('/login'), child: Text('Se connecter', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTile(String value, String label, IconData icon) {
    final active = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? AppColors.primary : Colors.grey, size: 22),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? AppColors.primary : Colors.grey.shade700, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
