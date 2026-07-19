import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'profile_theme.dart';

const _productCategories = ['Orthopédie', 'Mobilité', 'Diagnostic', 'Hygiène', 'Bien-être', 'Location'];

class AddProductSheet extends StatefulWidget {
  const AddProductSheet({super.key});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _category = _productCategories.first;
  XFile? _image;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = picked);
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty && double.tryParse(_price.text.trim()) != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ProfileProvider>().addProduct(
            name: _name.text.trim(),
            category: _category,
            description: _description.text.trim(),
            price: double.parse(_price.text.trim()),
            image: _image,
          );
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
              const Text('Ajouter un article', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(_image!.path, height: 140, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), height: 140, width: double.infinity, fit: BoxFit.cover),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined, color: ProfileColors.accent, size: 18),
                  label: const Text('Ajouter une photo (optionnel)', style: TextStyle(color: ProfileColors.accent)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: ProfileColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
              const SizedBox(height: 14),
              _field('Nom de l\'article', _name, 'ex: Tensiomètre digital'),
              const SizedBox(height: 14),
              const Text('Catégorie', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: _decoration(),
                items: _productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              _field('Prix (DA)', _price, 'ex: 2500', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 14),
              _field('Description', _description, 'Décrivez votre article...', maxLines: 3),
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
                      : const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
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
          decoration: _decoration().copyWith(hintText: hint),
        ),
      ],
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: ProfileColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProfileColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProfileColors.accent)),
    );
  }
}
