import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/ad_campaign.dart';
import '../models/app_user.dart';
import '../services/user_session.dart';

class QuickAdPublishPage extends StatefulWidget {
  const QuickAdPublishPage({super.key});

  @override
  State<QuickAdPublishPage> createState() => _QuickAdPublishPageState();
}

class _QuickAdPublishPageState extends State<QuickAdPublishPage> {
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _ctaRouteCtrl    = TextEditingController(text: '/shop');
  final _ctaLabelCtrl    = TextEditingController(text: 'Découvrir');
  final _companyNameCtrl = TextEditingController();
  final _contactCtrl     = TextEditingController();

  int _exposureHoursPerDay = 1;
  int _durationDays        = 4;
  AdPaymentMethod _paymentMethod = AdPaymentMethod.baridimob;

  XFile? _selectedImage;
  String? _selectedGradientName;
  XFile? _selectedReceipt;
  bool _publishing = false;

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _gradients = [
    {
      'name': 'Glow Neon',
      'colors': [const Color(0xFF00F6FF), const Color(0xFF00B2FF)],
      'id': 'gradient:neon',
    },
    {
      'name': 'Crimson Night',
      'colors': [const Color(0xFF292526), const Color(0xFF6E1128)],
      'id': 'gradient:crimson',
    },
    {
      'name': 'Royal Purple',
      'colors': [const Color(0xFF8A2BE2), const Color(0xFF4B0082)],
      'id': 'gradient:purple',
    },
    {
      'name': 'Sunrise Orange',
      'colors': [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      'id': 'gradient:orange',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedGradientName = _gradients[0]['id'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = UserSession.instance.current;
      if (user.proRole != ProRole.company) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _ctaRouteCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _companyNameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  int get _pricePerDay => switch (_exposureHoursPerDay) {
        1  => 800,
        3  => 2000,
        6  => 3500,
        12 => 6000,
        24 => 10000,
        _  => 800,
      };

  int get _totalCost => _pricePerDay * _durationDays;

  String get _bankDetails => _paymentMethod == AdPaymentMethod.baridimob
      ? 'RIP : 007999990023456789 92'
      : 'CCP : 1234567  Clé 89';

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _selectedGradientName = null;
        });
      }
    } catch (_) {}
  }


  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final extension = _selectedImage!.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_ad.$extension';
      final path = 'campaigns/$userId/$fileName';

      await Supabase.instance.client.storage.from('product-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );

      return Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked != null) setState(() => _selectedReceipt = picked);
    } catch (_) {}
  }

  Future<String?> _uploadReceipt(String userId) async {
    if (_selectedReceipt == null) return null;
    try {
      final bytes = await _selectedReceipt!.readAsBytes();
      final extension = _selectedReceipt!.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_receipt.$extension';
      final path = '$userId/$fileName';

      await Supabase.instance.client.storage
          .from('ad-receipts')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );

      return path;
    } catch (e) {
      debugPrint('Error uploading receipt: $e');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Le titre de l\'annonce est obligatoire.');
      return;
    }
    if (_companyNameCtrl.text.trim().isEmpty) {
      _snack('Le nom de l\'entreprise est obligatoire.');
      return;
    }
    if (_selectedReceipt == null) {
      _snack('Veuillez joindre le justificatif de paiement.');
      return;
    }

    final user = UserSession.instance.current;
    if (user.isGuest) {
      _snack('Veuillez vous connecter.');
      return;
    }

    setState(() => _publishing = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(user.id);
      } else if (_selectedGradientName != null) {
        imageUrl = _selectedGradientName;
      }

      final receiptPath = await _uploadReceipt(user.id);

      final today  = DateTime.now();
      final endDate = today.add(Duration(days: _durationDays - 1));

      await Supabase.instance.client.from('ad_campaigns').insert({
        'company_id':      user.id,
        'title':           _titleCtrl.text.trim(),
        'description':     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'image_url':       imageUrl,
        'cta_label':       _ctaLabelCtrl.text.trim().isEmpty ? 'Découvrir' : _ctaLabelCtrl.text.trim(),
        'cta_route':       _ctaRouteCtrl.text.trim().isEmpty ? '/shop' : _ctaRouteCtrl.text.trim(),
        'status':          'submitted',
        'budget_dzd':      _totalCost,
        'start_date':      today.toIso8601String().split('T').first,
        'end_date':        endDate.toIso8601String().split('T').first,
        'placement':       'home_banner',
        'payment_method':  _paymentMethod.name,
        'receipt_url':     receiptPath,
        'payment_status':  'pending',
        'approval_status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demande envoyée ! En attente de validation par l\'administrateur.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final previewColors = _gradients.firstWhere(
        (g) => g['id'] == _selectedGradientName,
        orElse: () => _gradients[0])['colors'] as List<Color>;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceAlt,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Créer ma Publicité',
          style: GoogleFonts.montserrat(
            color: AppColors.nearBlack,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STEP 1: Visuel ─────────────────────────────────────────────
            _sectionLabel('1. Visuel de l\'annonce'),
            const SizedBox(height: 8),
            _buildAdPreview(previewColors),
            const SizedBox(height: 12),
            _buildMediaSelector(previewColors),
            const SizedBox(height: 16),
            _buildContentCard(),
            const SizedBox(height: 24),

            // ── STEP 2: Budget ─────────────────────────────────────────────
            _sectionLabel('2. Paramètres & Budget publicitaire'),
            const SizedBox(height: 10),
            _buildBudgetCard(),
            const SizedBox(height: 24),

            // ── STEP 3: Informations de l'entreprise ───────────────────────
            _sectionLabel('3. Informations de l\'entreprise'),
            const SizedBox(height: 10),
            _buildCompanyCard(),
            const SizedBox(height: 24),

            // ── STEP 4: Justificatif de paiement ──────────────────────────
            _sectionLabel('4. Justificatif de paiement'),
            const SizedBox(height: 8),
            _buildReceiptCard(),
            const SizedBox(height: 20),

            // ── Summary & Submit ────────────────────────────────────────────
            _buildSummaryCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Section helpers ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.montserrat(
          color: AppColors.nearBlack,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

  // ── Step 1 widgets ──────────────────────────────────────────────────────────

  Widget _buildAdPreview(List<Color> previewColors) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray, width: 1.5),
        gradient: _selectedGradientName != null
            ? LinearGradient(
                colors: previewColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _selectedImage!.path,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.dark,
                  child: const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.1),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SPONSORISÉ',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _titleCtrl.text.isEmpty
                      ? 'Titre de l\'annonce'
                      : _titleCtrl.text,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _descCtrl.text.isEmpty
                      ? 'Petite description de votre offre'
                      : _descCtrl.text,
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _ctaLabelCtrl.text.isEmpty ? 'Découvrir' : _ctaLabelCtrl.text,
                style: GoogleFonts.montserrat(
                  color: previewColors[0],
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSelector(List<Color> previewColors) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(
              'Importer image',
              style: GoogleFonts.montserrat(
                  fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.nearBlack,
              side: const BorderSide(color: AppColors.lightGray),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              maxLength: 40,
              decoration: InputDecoration(
                labelText: 'Titre de l\'annonce',
                labelStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
                counterText: '',
                border: InputBorder.none,
                prefixIcon:
                    const Icon(Icons.title, color: AppColors.grayLight),
              ),
            ),
            const Divider(color: AppColors.lightGray),
            TextField(
              controller: _descCtrl,
              onChanged: (_) => setState(() {}),
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Description (2 lignes max)',
                labelStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
                counterText: '',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.description_outlined,
                    color: AppColors.grayLight),
              ),
            ),
            const Divider(color: AppColors.lightGray),
            TextField(
              controller: _ctaLabelCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Texte du bouton (ex : Découvrir, Visiter…)',
                labelStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.smart_button_outlined,
                    color: AppColors.grayLight),
              ),
            ),
            const Divider(color: AppColors.lightGray),
            TextField(
              controller: _ctaRouteCtrl,
              decoration: InputDecoration(
                labelText: 'Chemin de redirection (ex : /shop)',
                labelStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
                border: InputBorder.none,
                prefixIcon:
                    const Icon(Icons.link, color: AppColors.grayLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Budget ──────────────────────────────────────────────────────────

  Widget _buildBudgetCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exposition par jour :',
              style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildHourPacks(),
            const Divider(height: 24, color: AppColors.lightGray),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Durée de diffusion :',
                  style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_durationDays jour(s)',
                  style: GoogleFonts.montserrat(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: _durationDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.blue,
              inactiveColor: AppColors.lightGray,
              onChanged: (val) => setState(() => _durationDays = val.round()),
            ),
            const Divider(height: 24, color: AppColors.lightGray),
            Text(
              'Moyen de paiement :',
              style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentMethodOption(AdPaymentMethod.baridimob),
                const SizedBox(width: 10),
                _buildPaymentMethodOption(AdPaymentMethod.ccp),
              ],
            ),
            const SizedBox(height: 16),
            // Bank details — shown so seller knows where to transfer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effectuez le virement vers :',
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _bankDetails,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Montant : $_totalCost DA',
                    style: GoogleFonts.montserrat(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Company info ────────────────────────────────────────────────────

  Widget _buildCompanyCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _companyNameCtrl,
              decoration: InputDecoration(
                labelText: 'Nom de l\'entreprise *',
                labelStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.business_outlined,
                    color: AppColors.grayLight),
              ),
            ),
            const Divider(color: AppColors.lightGray),
            TextField(
              controller: _contactCtrl,
              decoration: InputDecoration(
                labelText: 'Contact (téléphone ou email)',
                labelStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: AppColors.gray),
                border: InputBorder.none,
                prefixIcon:
                    const Icon(Icons.contact_phone_outlined, color: AppColors.grayLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Receipt upload ──────────────────────────────────────────────────

  Widget _buildReceiptCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _selectedReceipt != null ? AppColors.success : AppColors.lightGray,
          width: _selectedReceipt != null ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Après avoir effectué le virement, joignez ici une capture d\'écran ou photo du reçu.',
              style: GoogleFonts.montserrat(
                color: AppColors.gray,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: Icon(
                  _selectedReceipt != null
                      ? Icons.check_circle_outline
                      : Icons.upload_file_outlined,
                  size: 20,
                  color: _selectedReceipt != null
                      ? AppColors.success
                      : AppColors.nearBlack,
                ),
                label: Text(
                  _selectedReceipt != null
                      ? 'Reçu sélectionné : ${_selectedReceipt!.name}'
                      : 'Choisir le justificatif *',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _selectedReceipt != null
                        ? AppColors.success
                        : AppColors.nearBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _selectedReceipt != null
                        ? AppColors.success
                        : AppColors.lightGray,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary & Submit ────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.nearBlack, AppColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.nearBlack.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget total estimé',
                    style:
                        GoogleFonts.montserrat(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalCost DA',
                    style: GoogleFonts.montserrat(
                      color: AppColors.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_durationDays j × $_exposureHoursPerDay h/j',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Votre annonce sera examinée par un administrateur après soumission.',
            style: GoogleFonts.montserrat(
              color: Colors.white38,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _publishing ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.nearBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _publishing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.nearBlack,
                      ),
                    )
                  : Text(
                      'Soumettre la demande',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable sub-widgets ────────────────────────────────────────────────────

  Widget _buildHourPacks() {
    final packs = [
      (1, '800 DA/j', '1h / jour'),
      (3, '2K DA/j', '3h / jour'),
      (6, '3.5K DA/j', '6h / jour'),
      (12, '6K DA/j', '12h / jour'),
      (24, '10K DA/j', '24h / jour'),
    ];

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: packs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final p = packs[idx];
          final active = _exposureHoursPerDay == p.$1;
          return GestureDetector(
            onTap: () => setState(() => _exposureHoursPerDay = p.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? AppColors.blue : AppColors.lightGray,
                  width: active ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.$3,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.blue : AppColors.nearBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.$2,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodOption(AdPaymentMethod method) {
    final active = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.nearBlack : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.nearBlack : AppColors.lightGray,
            ),
          ),
          child: Center(
            child: Text(
              method.label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppColors.nearBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
