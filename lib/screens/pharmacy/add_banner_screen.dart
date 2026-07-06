import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../config/supabase_config.dart';

/// Écran Admin : créer une bannière publicitaire affichée dans la boutique.
class AddBannerScreen extends StatefulWidget {
  const AddBannerScreen({super.key});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  static const _purple = Color(0xFF5F55D7);

  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  Uint8List? _imageBytes;
  String _colorHex = '#6C5FE0';
  bool _saving = false;
  String? _error;

  static const _colors = <String, Color>{
    '#6C5FE0': Color(0xFF6C5FE0),
    '#1AA88F': Color(0xFF1AA88F),
    '#F2994A': Color(0xFFF2994A),
    '#FF5C5C': Color(0xFFFF5C5C),
    '#2E7D6B': Color(0xFF2E7D6B),
  };

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = 'Image: $e');
    }
  }

  Future<void> _publish() async {
    if (_title.text.trim().isEmpty && _imageBytes == null) {
      setState(() => _error = 'Ajoute au moins un titre ou une image.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_imageBytes != null) {
        final path = 'banners/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('banner-images').uploadBinary(
              path,
              _imageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
        imageUrl = supabase.storage.from('banner-images').getPublicUrl(path);
      }
      await supabase.from('promo_banners').insert({
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'image_url': imageUrl,
        'color_hex': _colorHex,
        'active': true,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF101522),
        title: const Text('Ajouter une pub', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Aperçu
          _preview(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_imageBytes == null ? Icons.add_photo_alternate_outlined : Icons.check_circle, color: _purple, size: 32),
                  const SizedBox(height: 8),
                  Text(_imageBytes == null ? 'Choisir une image (optionnel)' : 'Image sélectionnée ✓', style: const TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _field('Titre', _title, 'Ex : Offre spéciale'),
          const SizedBox(height: 14),
          _field('Sous-titre', _subtitle, 'Ex : -20% sur tout l\'orthopédie'),
          const SizedBox(height: 20),
          const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF101522))),
          const SizedBox(height: 10),
          Row(
            children: _colors.entries.map((e) {
              final selected = e.key == _colorHex;
              return GestureDetector(
                onTap: () => setState(() => _colorHex = e.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: e.value,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? Colors.black : Colors.transparent, width: 3),
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _publish,
              style: ElevatedButton.styleFrom(backgroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Publier la pub', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final color = _colors[_colorHex] ?? _purple;
    return Container(
      height: 130,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_imageBytes != null) Image.memory(_imageBytes!, fit: BoxFit.cover),
          if (_imageBytes != null) Container(color: Colors.black.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title.text.isEmpty ? 'Titre' : _title.text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(_subtitle.text.isEmpty ? 'Sous-titre de la pub' : _subtitle.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF101522))),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
      ],
    );
  }
}
