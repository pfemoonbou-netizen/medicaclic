import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Seller registration – 5 steps (account already created in sign_up_page)
// Step 1: Boutique  2: Catégorie  3: Taille  4: KYC  5: Validation
// ─────────────────────────────────────────────────────────────────────────────

class CompleteSellerPage extends StatefulWidget {
  const CompleteSellerPage({super.key});
  @override
  State<CompleteSellerPage> createState() => _CompleteSellerPageState();
}

class _CompleteSellerPageState extends State<CompleteSellerPage> {
  int _step = 0;
  bool _loading = false;
  final _picker = ImagePicker();

  // ── Step 1 – Boutique ──────────────────────────────────────────────────────
  final _storeNameCtrl = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _bioCtrl       = TextEditingController();
  List<int>? _logoBytes;
  final _addressCtrl   = TextEditingController();
  String? _wilaya;

  // ── Step 2 – Catégorie ─────────────────────────────────────────────────────
  String? _category;
  String? _subcategory;

  // ── Step 3 – Taille ────────────────────────────────────────────────────────
  String? _storeSize;

  // ── Step 5 – KYC ──────────────────────────────────────────────────────────
  List<int>? _idDocBytes;
  List<int>? _selfieBytes;

  // ── Step 6 – Validation ────────────────────────────────────────────────────
  bool _acceptCgu     = false;
  bool _acceptPrivacy = false;
  bool _acceptSeller  = false;

  // ─── Static data ───────────────────────────────────────────────────────────

  static const _stepTitles = [
    'Informations de la boutique',
    "Catégorie d'activité",
    'Taille de la boutique',
    'Vérification KYC',
    'Validation',
  ];

  static const _wilayas = [
    '01 - Adrar', '02 - Chlef', '03 - Laghouat', '04 - Oum El Bouaghi',
    '05 - Batna', '06 - Béjaïa', '07 - Biskra', '08 - Béchar',
    '09 - Blida', '10 - Bouira', '11 - Tamanrasset', '12 - Tébessa',
    '13 - Tlemcen', '14 - Tiaret', '15 - Tizi Ouzou', '16 - Alger',
    '17 - Djelfa', '18 - Jijel', '19 - Sétif', '20 - Saïda',
    '21 - Skikda', '22 - Sidi Bel Abbès', '23 - Annaba', '24 - Guelma',
    '25 - Constantine', '26 - Médéa', '27 - Mostaganem', "28 - M'Sila",
    '29 - Mascara', '30 - Ouargla', '31 - Oran', '32 - El Bayadh',
    '33 - Illizi', '34 - Bordj Bou Arréridj', '35 - Boumerdès', '36 - El Tarf',
    '37 - Tindouf', '38 - Tissemsilt', '39 - El Oued', '40 - Khenchela',
    '41 - Souk Ahras', '42 - Tipaza', '43 - Mila', '44 - Aïn Defla',
    '45 - Naâma', '46 - Aïn Témouchent', '47 - Ghardaïa', '48 - Relizane',
    '49 - Timimoun', '50 - Bordj Badji Mokhtar', '51 - Ouled Djellal',
    '52 - Béni Abbès', '53 - In Salah', '54 - In Guezzam',
    '55 - Touggourt', '56 - Djanet', "57 - El M'Ghair", '58 - El Meniaa',
  ];

  static const Map<String, List<String>> _categories = {
    'Mode':         ['Femme', 'Homme', 'Enfant', 'Hijab', 'Chaussures', 'Accessoires'],
    'Beauté':       ['Maquillage', 'Soins visage', 'Parfums', 'Cheveux', 'Ongles'],
    'Électronique': ['Téléphones', 'PC & Tablettes', 'Audio', 'Gaming', 'Accessoires'],
    'Maison':       ['Décoration', 'Linge de maison', 'Cuisine', 'Jardin'],
    'Alimentation': ['Épicerie', 'Pâtisserie', 'Boissons', 'Bio'],
    'Artisanat':    ['Broderie', 'Poterie', 'Bijoux artisanaux', 'Tissage'],
    'Automobile':   ['Pièces détachées', 'Accessoires auto', 'Entretien'],
    'Sport':        ['Fitness', 'Football', 'Running', 'Arts martiaux'],
    'Services':     ['Livraison', 'Couture', 'Conseil mode', 'Photographie'],
    'Autres':       ['Livres', 'Jouets', 'Animaux', 'Fournitures'],
  };

  static const _storeSizes = [
    'Débutant',
    'Petite boutique',
    'Moyenne entreprise',
    'Grande entreprise',
    'Marque officielle',
    'Expert / Professionnel',
  ];

  static const _storeSizeIcons = <IconData>[
    Icons.emoji_events_outlined,
    Icons.store_outlined,
    Icons.business_outlined,
    Icons.domain_outlined,
    Icons.verified_outlined,
    Icons.workspace_premium_outlined,
  ];

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final c in [
      _storeNameCtrl, _usernameCtrl, _addressCtrl, _bioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (!_validate()) return;
    if (_step < 4) {
      setState(() => _step++);
      return;
    }
    setState(() => _loading = true);
    try {
      await UserSession.instance.registerSellerPending();
      final uid = UserSession.instance.current.id;

      // Core fields — always exist in schema
      await Supabase.instance.client.from('profiles').update({
        'store_name': _storeNameCtrl.text.trim(),
        'wilaya':     _wilaya,
        'category':   _category,
      }).eq('id', uid);

      // Extended fields — added by migration; silent if not yet applied
      try {
        await Supabase.instance.client.from('profiles').update({
          'username_requested': _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
          'bio':                _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          'address':            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          'subcategory':        _subcategory,
          'business_size':      _storeSize,
        }).eq('id', uid);
      } catch (_) {}

      await UserSession.instance.ensureSellerStore(
        ownerId: uid,
        storeName: _storeNameCtrl.text.trim(),
        wilaya: _wilaya,
        category: _category,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/feed');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription : $e',
                style: GoogleFonts.montserrat(fontSize: 13)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validate() {
    switch (_step) {
      case 0:
        if (_storeNameCtrl.text.trim().isEmpty) {
          _err('Le nom de la boutique est obligatoire.');
          return false;
        }
        if (_wilaya == null) {
          _err('Veuillez sélectionner votre wilaya.');
          return false;
        }
        return true;
      case 1:
        if (_category == null) {
          _err('Veuillez choisir une catégorie principale.');
          return false;
        }
        return true;
      case 2:
        if (_storeSize == null) {
          _err('Veuillez indiquer la taille de votre boutique.');
          return false;
        }
        return true;
      case 4:
        if (!_acceptCgu || !_acceptPrivacy || !_acceptSeller) {
          _err('Veuillez accepter toutes les conditions pour continuer.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Image picker ─────────────────────────────────────────────────────────

  Future<List<int>?> _pick() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    final bytes = await f?.readAsBytes();
    return bytes?.toList();
  }

  // ─── Terms detail dialog ──────────────────────────────────────────────────

  void _showTermsDetail(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: AppColors.nearBlack, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.nearBlack)),
                ),
              ]),
              const SizedBox(height: 4),
              const Divider(color: AppColors.lightGray, height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: SingleChildScrollView(
                  child: Text(content,
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: AppColors.gray, height: 1.65)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nearBlack,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text('Compris',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  Widget _card(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _label(String text, {bool req = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text, style: GoogleFonts.montserrat(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray)),
      if (req)
        Text(' *', style: GoogleFonts.montserrat(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
    ]),
  );

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: GoogleFonts.montserrat(
        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.nearBlack)),
  );

  Widget _tf(TextEditingController ctrl, String hint, {
    String? prefixText,
    IconData? icon,
    TextInputType kb = TextInputType.text,
    int lines = 1,
    List<TextInputFormatter>? fmt,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: kb,
        maxLines: lines,
        inputFormatters: fmt,
        style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.nearBlack),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
          prefixText: prefixText,
          prefixStyle: GoogleFonts.montserrat(
              fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w700),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: AppColors.gray) : null,
          filled: true,
          fillColor: AppColors.bgGray,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        ),
      ),
    );

  Widget _photoBox(List<int>? bytes, String hint, IconData icon, VoidCallback onTap,
      {double height = 110}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray, width: 1.5),
        ),
        child: bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                    Uint8List.fromList(bytes),
                    fit: BoxFit.cover, width: double.infinity))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 28, color: AppColors.gray),
                const SizedBox(height: 6),
                Text(hint, style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.gray)),
              ]),
      ),
    );

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [AppColors.accent, AppColors.blue])
              : null,
          color: selected ? null : AppColors.bgGray,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.lightGray),
        ),
        child: Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? AppColors.nearBlack : AppColors.gray)),
      ),
    );

  Widget _infoBanner(String text, {Color? bg, Color? border, Color? iconColor}) =>
    Container(
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bg ?? AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border ?? AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, color: iconColor ?? AppColors.accent, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.montserrat(
            fontSize: 11, color: AppColors.gray, height: 1.5))),
      ]),
    );

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomNav(),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    child: Column(children: [
      Row(children: [
        GestureDetector(
          onTap: _back,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 14,
                color: AppColors.nearBlack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Étape ${_step + 1} sur 5',
              style: GoogleFonts.montserrat(
                  fontSize: 10, color: AppColors.grayLight,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_stepTitles[_step],
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w900,
                  color: AppColors.nearBlack, letterSpacing: -0.3)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.blue]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_step + 1}/5',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ),
      ]),
      const SizedBox(height: 12),
      Row(
        children: List.generate(5, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                gradient: active || done
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue])
                    : null,
                color: active || done ? null : AppColors.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    ]),
  );

  Widget _buildBottomNav() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    child: Row(children: [
      if (_step > 0) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: _back,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.lightGray, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Retour',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: _loading ? null : _next,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.blue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.nearBlack, strokeWidth: 2))
                : Text(_step == 4 ? 'Créer ma boutique' : 'Continuer',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontWeight: FontWeight.w800, fontSize: 14))),
          ),
        ),
      ),
    ]),
  );

  Widget _buildCurrentStep() {
    return switch (_step) {
      0 => _step1(),
      1 => _step2(),
      2 => _step4(),
      3 => _step5(),
      _ => _step6(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1 – Informations de la boutique
  // ─────────────────────────────────────────────────────────────────────────

  Widget _step1() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title('Votre boutique'),
    _label('Nom de la boutique', req: true),
    _tf(_storeNameCtrl, 'ex: LOOLET STORE', icon: Icons.storefront_outlined),
    _label("Nom d'utilisateur boutique"),
    _tf(_usernameCtrl, '@handle', prefixText: '@'),
    _label('Logo de la boutique'),
    _photoBox(_logoBytes, 'Ajouter votre logo', Icons.camera_alt_outlined, () async {
      final b = await _pick();
      if (b != null) setState(() => _logoBytes = b);
    }, height: 110),
    _label('Adresse physique (optionnelle)'),
    _tf(_addressCtrl, 'Rue, quartier, ville...', icon: Icons.location_on_outlined),
    _label('Bio de la boutique'),
    _tf(
      _bioCtrl,
      'Ex : Votre boutique de mode tendance en Algérie.',
      icon: Icons.edit_outlined,
      lines: 3,
    ),
    _label('Wilaya', req: true),
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _wilaya,
        isExpanded: true,
        hint: Text('Sélectionner votre wilaya',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray)),
        items: _wilayas.map((w) => DropdownMenuItem(
          value: w,
          child: Text(w,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: AppColors.nearBlack)),
        )).toList(),
        onChanged: (v) => setState(() => _wilaya = v),
        dropdownColor: Colors.white,
        style: GoogleFonts.montserrat(
            fontSize: 13, color: AppColors.nearBlack),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.map_outlined,
              size: 18, color: AppColors.gray),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: AppColors.bgGray,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    ),
  ]));

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 – Catégorie d'activité
  // ─────────────────────────────────────────────────────────────────────────

  Widget _step2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('Catégorie principale *'),
      Wrap(
        children: _categories.keys.map((cat) =>
          _chip(cat, _category == cat, () =>
              setState(() { _category = cat; _subcategory = null; })),
        ).toList(),
      ),
    ])),
    if (_category != null)
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('Sous-catégorie'),
        Wrap(
          children: (_categories[_category] ?? []).map((sub) =>
            _chip(sub, _subcategory == sub,
                () => setState(() => _subcategory = sub)),
          ).toList(),
        ),
      ])),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3 – Taille de la boutique
  // ─────────────────────────────────────────────────────────────────────────

  Widget _step4() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title('Taille de votre boutique *'),
    Text('Aidez-nous à personnaliser votre expérience.',
        style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.gray)),
    const SizedBox(height: 16),
    ...List.generate(_storeSizes.length, (i) {
      final sel = _storeSize == _storeSizes[i];
      return GestureDetector(
        onTap: () => setState(() => _storeSize = _storeSizes[i]),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue])
                : null,
            color: sel ? null : AppColors.bgGray,
            borderRadius: BorderRadius.circular(12),
            border: sel ? null : Border.all(color: AppColors.lightGray),
          ),
          child: Row(children: [
            Icon(_storeSizeIcons[i], size: 22,
                color: sel ? AppColors.nearBlack : AppColors.gray),
            const SizedBox(width: 14),
            Expanded(child: Text(_storeSizes[i],
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.nearBlack))),
            if (sel)
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: AppColors.nearBlack.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: 13, color: AppColors.nearBlack),
              ),
          ]),
        ),
      );
    }),
  ]));

  // ─────────────────────────────────────────────────────────────────────────
  // Step 5 – Vérification KYC
  // ─────────────────────────────────────────────────────────────────────────

  Widget _step5() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title("Vérification d'identité (KYC)"),
      _infoBanner(
        'La vérification KYC garantit la sécurité de la plateforme et renforce '
        'la confiance de vos acheteurs. Vos documents sont traités de manière confidentielle.',
        bg: const Color(0xFFFFF8E1),
        border: const Color(0xFFFFCC02),
        iconColor: const Color(0xFFF9A825),
      ),
      _label("Carte d'identité nationale ou Passeport", req: true),
      _photoBox(_idDocBytes, 'Photographier votre document',
          Icons.badge_outlined, () async {
        final b = await _pick();
        if (b != null) setState(() => _idDocBytes = b);
      }, height: 150),
      _label('Selfie (visage visible)', req: true),
      _photoBox(_selfieBytes, 'Prendre un selfie clair',
          Icons.face_outlined, () async {
        final b = await _pick();
        if (b != null) setState(() => _selfieBytes = b);
      }, height: 150),
    ])),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('Statut de vérification'),
      Row(children: [
        Container(
          width: 12, height: 12,
          decoration: const BoxDecoration(
              color: Color(0xFFFFC107), shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text('Vérification en attente',
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.nearBlack)),
      ]),
      const SizedBox(height: 8),
      Text(
        'Après soumission, notre équipe examinera vos documents sous 24 à 48h. '
        'Vous serez notifié par e-mail dès validation.',
        style: GoogleFonts.montserrat(
            fontSize: 12, color: AppColors.gray, height: 1.5),
      ),
    ])),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // Step 6 – Validation & récapitulatif
  // ─────────────────────────────────────────────────────────────────────────

  Widget _step6() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('Récapitulatif'),
      _summaryRow(Icons.storefront_outlined, 'Boutique',
          _storeNameCtrl.text.trim().isEmpty
              ? '—' : _storeNameCtrl.text.trim()),
      _summaryRow(Icons.alternate_email, 'Handle',
          _usernameCtrl.text.trim().isEmpty
              ? '—' : '@${_usernameCtrl.text.trim()}'),
      _summaryRow(Icons.map_outlined, 'Wilaya', _wilaya ?? '—'),
      _summaryRow(Icons.category_outlined, 'Catégorie',
          _category == null ? '—'
              : (_subcategory != null
                  ? '$_category › $_subcategory' : _category!)),
      _summaryRow(Icons.business_outlined, 'Taille', _storeSize ?? '—'),
      _summaryRow(Icons.verified_user_outlined, 'KYC',
          (_idDocBytes != null && _selfieBytes != null)
              ? 'Documents fournis ✓' : 'À compléter après validation'),
    ])),

    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title("Conditions d'utilisation"),
      _checkRow(
        "J'accepte les Conditions d'utilisation",
        _acceptCgu,
        (v) => setState(() => _acceptCgu = v ?? false),
        detailTitle: "Conditions d'utilisation",
        detailContent:
          "En utilisant LINCOO, vous acceptez de respecter les présentes conditions d'utilisation.\n\n"
          "1. Éligibilité\nLa plateforme est ouverte à toute personne physique ou morale légalement autorisée à exercer une activité commerciale en Algérie.\n\n"
          "2. Comportement\nTout contenu trompeur, frauduleux ou illicite est strictement interdit. LINCOO se réserve le droit de suspendre immédiatement tout compte contrevenant.\n\n"
          "3. Modifications\nLINCOO peut modifier ces conditions à tout moment. La poursuite de l'utilisation de la plateforme après modification vaut acceptation des nouvelles conditions.\n\n"
          "4. Responsabilité\nLINCOO ne saurait être tenu responsable des dommages directs ou indirects résultant de l'utilisation de la plateforme.",
      ),
      _checkRow(
        "J'accepte la Politique de confidentialité",
        _acceptPrivacy,
        (v) => setState(() => _acceptPrivacy = v ?? false),
        detailTitle: "Politique de confidentialité",
        detailContent:
          "LINCOO s'engage à protéger vos données personnelles conformément aux lois en vigueur.\n\n"
          "1. Données collectées\nNous collectons votre nom, adresse e-mail, numéro de téléphone, photos de profil et de couverture, ainsi que les données d'activité sur la plateforme.\n\n"
          "2. Utilisation des données\nVos données sont utilisées uniquement pour faire fonctionner la plateforme et améliorer nos services. Elles ne sont jamais vendues à des tiers.\n\n"
          "3. Conservation\nVos données sont conservées aussi longtemps que votre compte est actif. Vous pouvez en demander la suppression à tout moment via notre support.\n\n"
          "4. Sécurité\nNos données sont stockées sur des serveurs sécurisés avec chiffrement SSL. Seule l'équipe LINCOO habilitée y a accès.",
      ),
      _checkRow(
        "J'accepte la Politique vendeur",
        _acceptSeller,
        (v) => setState(() => _acceptSeller = v ?? false),
        detailTitle: "Politique vendeur",
        detailContent:
          "En tant que vendeur sur LINCOO, vous vous engagez à respecter les règles suivantes :\n\n"
          "1. Produits conformes\nVous vous engagez à vendre uniquement des produits conformes à leur description, de qualité acceptable et légaux en Algérie. La vente de contrefaçons est strictement interdite.\n\n"
          "2. Livraison\nVous devez respecter les délais de livraison annoncés et informer l'acheteur en cas de retard. Tout retard non communiqué peut entraîner un avertissement.\n\n"
          "3. Service client\nVous êtes tenu de répondre aux réclamations clients dans un délai de 48h et de traiter les litiges de bonne foi.\n\n"
          "4. Sanctions\nEn cas de violations répétées, LINCOO peut suspendre ou supprimer définitivement votre boutique sans préavis.",
      ),
    ])),

    _infoBanner(
      'Après création, votre boutique sera soumise à vérification KYC. '
      'Vous serez notifié par e-mail dès que votre compte sera validé.',
    ),
  ]);

  // ─── Shared sub-widgets ───────────────────────────────────────────────────

  Widget _summaryRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppColors.accent),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 10, color: AppColors.gray)),
        Text(value,
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.nearBlack)),
      ]),
    ]),
  );

  Widget _checkRow(
    String label,
    bool value,
    ValueChanged<bool?> onChanged, {
    String? detailTitle,
    String? detailContent,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: AppColors.nearBlack,
                        height: 1.4)),
                if (detailTitle != null && detailContent != null)
                  GestureDetector(
                    onTap: () =>
                        _showTermsDetail(detailTitle, detailContent),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('Voir les détails →',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppColors.blue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.blue)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
}
