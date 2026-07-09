import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/app_user.dart';
import '../services/user_session.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl      = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  // Contact links
  final _waCtrl        = TextEditingController();
  final _messengerCtrl = TextEditingController();
  final _telegramCtrl  = TextEditingController();
  final _proEmailCtrl  = TextEditingController();

  ProRole _role  = ProRole.none;
  String  _email = '';
  bool    _loading = false;
  Uint8List? _imageBytes;
  String?    _avatarUrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _storeNameCtrl, _phoneCtrl,
      _waCtrl, _messengerCtrl, _telegramCtrl, _proEmailCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final user = UserSession.instance.current;
    _role  = user.proRole;
    _email = user.email;

    if (user.isGuest) {
      setState(() => _nameCtrl.text = user.displayName);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, telephone, store_name, avatar_url, contact_links')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        setState(() => _nameCtrl.text = user.displayName);
        return;
      }

      final links = Map<String, dynamic>.from(
          data['contact_links'] as Map? ?? {});

      setState(() {
        _nameCtrl.text      = data['full_name']  as String? ?? user.displayName;
        _phoneCtrl.text     = data['telephone']  as String? ?? '';
        _storeNameCtrl.text = data['store_name'] as String? ?? '';
        _avatarUrl          = data['avatar_url'] as String?;
        _waCtrl.text        = links['whatsapp']  as String? ?? '';
        _messengerCtrl.text = links['messenger'] as String? ?? '';
        _telegramCtrl.text  = links['telegram']  as String? ?? '';
        _proEmailCtrl.text  = links['email']     as String? ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _nameCtrl.text = user.displayName);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final user   = UserSession.instance.current;
      final client = Supabase.instance.client;
      final name   = _nameCtrl.text.trim();

      // 1. Save basic profile — always
      final basicUpdate = <String, dynamic>{
        'full_name':   name,
        'nom_complet': name,
        'telephone':   _phoneCtrl.text.trim(),
      };
      if (_role == ProRole.seller || _role == ProRole.company) {
        basicUpdate['store_name'] = _storeNameCtrl.text.trim();
      }
      await client.from('profiles').update(basicUpdate).eq('id', user.id);

      // 2. Save contact links
      final links = <String, String>{};
      if (_waCtrl.text.trim().isNotEmpty) {
        links['whatsapp']  = _waCtrl.text.trim();
      }
      if (_messengerCtrl.text.trim().isNotEmpty) {
        links['messenger'] = _messengerCtrl.text.trim();
      }
      if (_telegramCtrl.text.trim().isNotEmpty) {
        links['telegram']  = _telegramCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        links['phone']     = _phoneCtrl.text.trim();
      }
      if (_proEmailCtrl.text.trim().isNotEmpty) {
        links['email']     = _proEmailCtrl.text.trim();
      }
      await client.from('profiles')
          .update({'contact_links': links}).eq('id', user.id);

      String? newAvatarUrl;

      // 3. Upload avatar if changed
      if (_imageBytes != null) {
        final path = 'avatars/${user.id}.jpg';
        await client.storage.from('avatars').uploadBinary(
          path, _imageBytes!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        newAvatarUrl = client.storage.from('avatars').getPublicUrl(path);
        await client.from('profiles')
            .update({'avatar_url': newAvatarUrl}).eq('id', user.id);
        if (mounted) setState(() => _avatarUrl = newAvatarUrl);
      }

      // 4. Sync seller/company store data so profile edits appear immediately
      if (_role == ProRole.seller || _role == ProRole.company) {
        await UserSession.instance.ensureSellerStore(
          ownerId: user.id,
          storeName: _storeNameCtrl.text.trim(),
          avatarUrl: newAvatarUrl ?? _avatarUrl,
        );
      }

      // 5. Update local session
      UserSession.instance.update(AppUser(
        id:                 user.id,
        email:              user.email,
        displayName:        name,
        avatarUrl:          newAvatarUrl ?? _avatarUrl,
        proRole:            user.proRole,
        proStatus:          user.proStatus,
        onboardingComplete: user.onboardingComplete,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour !'),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xf = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 800);
      if (xf != null) {
        final bytes = await xf.readAsBytes();
        if (mounted) setState(() => _imageBytes = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'accéder à la photo.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Photo de profil',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ListTile(
              leading: _sheetIcon(Icons.camera_alt_outlined),
              title: Text('Prendre une photo',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: _sheetIcon(Icons.photo_library_outlined),
              title: Text('Choisir depuis la galerie',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
            if (_imageBytes != null) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: _sheetIcon(Icons.delete_outline, color: Colors.red,
                    bg: const Color(0xFFFFEBEE)),
                title: Text('Supprimer la photo',
                    style: GoogleFonts.montserrat(
                        color: Colors.red, fontSize: 14,
                        fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imageBytes = null);
                },
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _sheetIcon(IconData icon,
          {Color color = AppColors.nearBlack,
           Color bg = AppColors.bgGray}) =>
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : (_email.isNotEmpty ? _email[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Modifier le profil',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack, fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 20),

              // ── Avatar ────────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showPickerSheet,
                  child: Stack(children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        gradient: (_imageBytes == null && _avatarUrl == null)
                            ? const LinearGradient(
                                colors: [AppColors.accent, AppColors.blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)
                            : null,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.memory(_imageBytes!,
                                  fit: BoxFit.cover, width: 96, height: 96))
                          : _avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.network(_avatarUrl!,
                                      fit: BoxFit.cover, width: 96, height: 96))
                              : Center(
                                  child: Text(initial,
                                      style: GoogleFonts.montserrat(
                                          color: AppColors.nearBlack,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900))),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.blue]),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: AppColors.nearBlack),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showPickerSheet,
                  child: Text('Changer la photo',
                      style: GoogleFonts.montserrat(
                          color: AppColors.blue, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Basic info ────────────────────────────────────────────────
              AppTextField(
                  label: 'Nom complet',
                  hint: 'Votre nom',
                  controller: _nameCtrl),
              const SizedBox(height: 14),

              if (_role == ProRole.seller || _role == ProRole.company) ...[
                AppTextField(
                    label: 'Nom de la boutique',
                    hint: 'Ex : Ma Super Boutique',
                    controller: _storeNameCtrl),
                const SizedBox(height: 14),
              ],

              AppTextField(
                  label: 'Téléphone',
                  hint: '05XXXXXXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),

              // ── Contact links (sellers only) ──────────────────────────────
              if (_role == ProRole.seller || _role == ProRole.company) ...[
                const SizedBox(height: 28),
                _sectionHeader(Icons.contact_phone_outlined, 'Liens de contact'),
                const SizedBox(height: 16),
                _contactField(
                  controller: _waCtrl,
                  label: 'WhatsApp',
                  hint: '+213 5XX XXX XXX',
                  color: const Color(0xFF25D366),
                  icon: Icons.chat,
                ),
                const SizedBox(height: 12),
                _contactField(
                  controller: _messengerCtrl,
                  label: 'Messenger',
                  hint: 'username ou lien',
                  color: const Color(0xFF7C3AED),
                  icon: Icons.messenger_outline,
                ),
                const SizedBox(height: 12),
                _contactField(
                  controller: _telegramCtrl,
                  label: 'Telegram',
                  hint: '@username',
                  color: const Color(0xFF7C3AED),
                  icon: Icons.send,
                ),
                const SizedBox(height: 12),
                _contactField(
                  controller: _proEmailCtrl,
                  label: 'Email professionnel',
                  hint: 'contact@boutique.com',
                  color: const Color(0xFFEA4335),
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],

              // ── Account email (locked) ────────────────────────────────────
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.gray, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Email du compte',
                          style: GoogleFonts.montserrat(
                              color: AppColors.gray, fontSize: 11)),
                      Text(_email.isNotEmpty ? _email : '—',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack, fontSize: 13)),
                    ]),
                  ),
                  const Icon(Icons.lock_outline,
                      color: AppColors.lightGray, size: 16),
                ]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: PrimaryButton(
            label: 'Enregistrer',
            loading: _loading,
            onPressed: _save,
          ),
        ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String label) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.blue]),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
    const SizedBox(width: 10),
    Text(label,
        style: GoogleFonts.montserrat(
            color: AppColors.nearBlack, fontSize: 14,
            fontWeight: FontWeight.w800)),
  ]);

  Widget _contactField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color color,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.nearBlack),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(
              fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600),
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
              fontSize: 13, color: AppColors.lightGray),
          prefixIcon: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 54),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
        ),
      );
}
