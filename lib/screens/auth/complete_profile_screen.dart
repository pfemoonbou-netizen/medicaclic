import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/supabase_config.dart';
import '../../utils/app_colors.dart';
import '../../utils/wilayas.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String role;
  const CompleteProfileScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nom = TextEditingController();
  final _adresse = TextEditingController();
  String? _wilaya;
  XFile? _photo;
  XFile? _carteIdentite;
  bool _isLoading = false;
  String? _error;

  bool get _needsCarteIdentite => widget.role == 'vendeur' || widget.role == 'prestataire';

  Future<void> _pickImage(bool isCarteIdentite) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (isCarteIdentite) {
          _carteIdentite = picked;
        } else {
          _photo = picked;
        }
      });
    }
  }

  Future<String?> _uploadImage(XFile file, String prefix) async {
    final userId = supabase.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$userId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    await supabase.storage.from('profile-photos').uploadBinary(path, bytes);
    return supabase.storage.from('profile-photos').getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (_nom.text.isEmpty) {
      setState(() => _error = 'Le nom est requis');
      return;
    }
    if (_adresse.text.isEmpty) {
      setState(() => _error = 'L\'adresse est requise');
      return;
    }
    if (_wilaya == null) {
      setState(() => _error = 'La wilaya est requise');
      return;
    }
    if (_photo == null) {
      setState(() => _error = 'Une photo de profil est requise');
      return;
    }
    if (_needsCarteIdentite && _carteIdentite == null) {
      setState(() => _error = 'La photo de carte d\'identité est requise');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final photoUrl = await _uploadImage(_photo!, 'profile');
      String? carteUrl;
      if (_needsCarteIdentite) {
        carteUrl = await _uploadImage(_carteIdentite!, 'cni');
      }

      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').update({
        'name': _nom.text,
        'adresse': _adresse.text,
        'wilaya': _wilaya,
        'photo_url': photoUrl,
        'carte_identite_url': carteUrl,
        'role': widget.role,
        'profile_completed': true,
      }).eq('id', userId);

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _photoPicker(String label, XFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: Color(0xFFA0A7B0))),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.cover, width: double.infinity, height: 140)
                    : Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity, height: 140),
              ),
      ),
    );
  }

  String get _title {
    switch (widget.role) {
      case 'vendeur':
        return 'Profil vendeur';
      case 'prestataire':
        return 'Profil prestataire';
      default:
        return 'Compléter votre profil';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101522)),
          onPressed: () => context.go('/user-type-selection'),
        ),
        title: Text(_title, style: const TextStyle(color: Color(0xFF101522), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Photo de profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _photoPicker('Ajouter une photo', _photo, () => _pickImage(false)),
              const SizedBox(height: 20),
              const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _nom,
                decoration: InputDecoration(
                  hintText: 'Votre nom',
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Wilaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _wilaya,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                hint: const Text('Sélectionner votre wilaya'),
                items: wilayasAlgerie.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (v) => setState(() => _wilaya = v),
              ),
              const SizedBox(height: 20),
              const Text('Adresse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _adresse,
                decoration: InputDecoration(
                  hintText: 'Votre adresse',
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              if (_needsCarteIdentite) ...[
                const SizedBox(height: 20),
                const Text('Photo carte d\'identité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                _photoPicker('Ajouter la carte d\'identité', _carteIdentite, () => _pickImage(true)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continuer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
