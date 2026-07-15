import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'profile_theme.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  XFile? _photo;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _name = TextEditingController(text: profile.name);
    _bio = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ProfileProvider>().updateProfile(name: _name.text.trim(), bio: _bio.text.trim(), photo: _photo);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: ProfileColors.border, borderRadius: BorderRadius.circular(2))),
            const Text('Modifier le profil', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: ProfileColors.card,
                      backgroundImage: _photo != null
                          ? (kIsWeb ? NetworkImage(_photo!.path) : FileImage(File(_photo!.path))) as ImageProvider
                          : (profile.photoUrl != null && profile.photoUrl!.isNotEmpty ? NetworkImage(profile.photoUrl!) : null),
                      child: (_photo == null && (profile.photoUrl == null || profile.photoUrl!.isEmpty)) ? const Icon(Icons.person, size: 40, color: ProfileColors.textFaint) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: ProfileColors.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Nom', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: _name, onChanged: (_) => setState(() {}), decoration: _decoration()),
            const SizedBox(height: 14),
            const Text('Bio', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: _bio, maxLines: 3, decoration: _decoration(hint: 'Parlez un peu de vous...')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: ProfileColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_name.text.trim().isNotEmpty && !_submitting) ? _submit : null,
                style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.accent, disabledBackgroundColor: ProfileColors.border, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: ProfileColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProfileColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProfileColors.accent)),
    );
  }
}
