import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_care_provider.dart';
import '../../providers/profile_provider.dart';
import 'profile_theme.dart';

class BecomeProSheet extends StatefulWidget {
  const BecomeProSheet({super.key});

  @override
  State<BecomeProSheet> createState() => _BecomeProSheetState();
}

class _BecomeProSheetState extends State<BecomeProSheet> {
  String? _kind; // 'prestataire' | 'vendeur'
  String? _categoryId;
  final _specialty = TextEditingController();
  final _phone = TextEditingController();
  final _shopName = TextEditingController();
  final _shopBio = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _specialty.dispose();
    _phone.dispose();
    _shopName.dispose();
    _shopBio.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_kind == 'prestataire') return _categoryId != null && _specialty.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty;
    if (_kind == 'vendeur') return _shopName.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty;
    return false;
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final profile = context.read<ProfileProvider>();
      if (_kind == 'prestataire') {
        await profile.becomePrestataire(categoryId: _categoryId!, specialty: _specialty.text.trim(), phone: _phone.text.trim());
      } else {
        await profile.becomeVendeur(shopName: _shopName.text.trim(), shopPhone: _phone.text.trim(), shopBio: _shopBio.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: ProfileColors.border, borderRadius: BorderRadius.circular(2))),
              const Text('Devenir un compte Pro', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Publiez du contenu et proposez vos services sur MedicaClic.', style: TextStyle(color: ProfileColors.textFaint, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _kindTile('prestataire', Icons.medical_services_outlined, 'Prestataire', 'Soins à domicile')),
                  const SizedBox(width: 12),
                  Expanded(child: _kindTile('vendeur', Icons.storefront_outlined, 'Vendeur', 'Boutique médicale')),
                ],
              ),
              if (_kind == 'prestataire') ..._prestataireFields(),
              if (_kind == 'vendeur') ..._vendeurFields(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: ProfileColors.red, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_canSubmit && !_submitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.accent, disabledBackgroundColor: ProfileColors.border, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindTile(String kind, IconData icon, String title, String subtitle) {
    final active = _kind == kind;
    return GestureDetector(
      onTap: () => setState(() => _kind = kind),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? ProfileColors.accent.withValues(alpha: 0.08) : ProfileColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? ProfileColors.accent : ProfileColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: active ? ProfileColors.accent : ProfileColors.textSecondary, size: 22),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: active ? ProfileColors.accent : ProfileColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: ProfileColors.textFaint, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  List<Widget> _prestataireFields() {
    final categories = context.watch<HomeCareProvider>().categories;
    return [
      const SizedBox(height: 20),
      const Text('Catégorie', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _categoryId,
        isExpanded: true,
        decoration: _fieldDecoration(),
        hint: const Text('Sélectionner une catégorie'),
        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
        onChanged: (v) => setState(() => _categoryId = v),
      ),
      const SizedBox(height: 14),
      _textField(_specialty, 'Spécialité', 'ex: Médecin généraliste'),
      const SizedBox(height: 14),
      _textField(_phone, 'Téléphone', 'ex: 0555000000', keyboardType: TextInputType.phone),
    ];
  }

  List<Widget> _vendeurFields() {
    return [
      const SizedBox(height: 20),
      _textField(_shopName, 'Nom de la boutique', 'ex: Pharmacie Centrale'),
      const SizedBox(height: 14),
      _textField(_phone, 'Téléphone', 'ex: 0555000000', keyboardType: TextInputType.phone),
      const SizedBox(height: 14),
      _textField(_shopBio, 'Description (optionnel)', 'Présentez votre boutique...', maxLines: 3),
    ];
  }

  Widget _textField(TextEditingController controller, String label, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: _fieldDecoration().copyWith(hintText: hint),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: ProfileColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProfileColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProfileColors.accent)),
    );
  }
}
