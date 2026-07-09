import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';

class DeliverySettingsPage extends StatefulWidget {
  const DeliverySettingsPage({super.key});
  @override
  State<DeliverySettingsPage> createState() => _DeliverySettingsPageState();
}

class _DeliverySettingsPageState extends State<DeliverySettingsPage> {
  static const _bg   = Color(0xFF07080F);
  static const _card = Color(0xFF0D0F1E);
  static const _bord = Color(0xFF1C1F35);
  static const _acc  = Color(0xFF7C3AED);
  static const _green= Color(0xFF10E8B0);

  final _addressCtrl      = TextEditingController();
  final _pickupAddrCtrl   = TextEditingController();
  final _communeCtrl      = TextEditingController();
  int?    _wilayaCode;
  String? _wilayaName;
  int     _avgPrepHours   = 24;
  double  _maxWeightKg    = 30;
  bool    _pickupEnabled  = true;
  bool    _dropoffEnabled = false;
  bool    _loading  = true;
  bool    _saving   = false;

  late String _sellerId;

  @override
  void initState() {
    super.initState();
    _sellerId = UserSession.instance.current.id;
    _load();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _pickupAddrCtrl.dispose();
    _communeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await DeliveryService.instance.mySettings(_sellerId);
    if (s != null && mounted) {
      setState(() {
        _wilayaCode       = s.wilayaCode;
        _wilayaName       = s.wilayaName;
        _addressCtrl.text = s.address ?? '';
        _pickupAddrCtrl.text = s.pickupAddress ?? '';
        _communeCtrl.text = s.commune ?? '';
        _avgPrepHours     = s.avgPrepHours;
        _maxWeightKg      = s.maxWeightKg;
        _pickupEnabled    = s.isPickupEnabled;
        _dropoffEnabled   = s.isDropoffEnabled;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DeliveryService.instance.saveSettings(
        sellerId:        _sellerId,
        wilayaCode:      _wilayaCode,
        wilayaName:      _wilayaName,
        commune:         _communeCtrl.text.trim().isEmpty ? null : _communeCtrl.text.trim(),
        address:         _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        pickupAddress:   _pickupAddrCtrl.text.trim().isEmpty ? null : _pickupAddrCtrl.text.trim(),
        avgPrepHours:    _avgPrepHours,
        maxWeightKg:     _maxWeightKg,
        isPickupEnabled:  _pickupEnabled,
        isDropoffEnabled: _dropoffEnabled,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Paramètres sauvegardés',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: _card, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e', style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: const Color(0xFFF04040),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(child: Column(children: [
      _topBar(),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
              _section('📍 Localisation'),
              _wilayaSelector(),
              const SizedBox(height: 10),
              _field('Commune', _communeCtrl, 'Ex: Bab El Oued'),
              const SizedBox(height: 10),
              _field('Adresse complète', _addressCtrl, 'Numéro, rue, cité...', maxLines: 2),
              const SizedBox(height: 24),
              _section('📦 Point de collecte'),
              _field('Adresse de ramassage (Pickup)', _pickupAddrCtrl,
                  'Adresse où le livreur vient récupérer', maxLines: 2),
              const SizedBox(height: 24),
              _section('⚙️ Préparation & Limites'),
              _prepSlider(),
              const SizedBox(height: 16),
              _weightSlider(),
              const SizedBox(height: 24),
              _section('🚚 Modes de livraison'),
              _switchRow('Ramassage (Pickup)', 'Le livreur vient chez vous', _pickupEnabled,
                  (v) => setState(() => _pickupEnabled = v)),
              const SizedBox(height: 8),
              _switchRow('Dépôt (Drop-off)', 'Vous déposez dans un point relais', _dropoffEnabled,
                  (v) => setState(() => _dropoffEnabled = v)),
              const SizedBox(height: 32),
              _saveBtn(),
            ])),
    ])),
  );

  Widget _topBar() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
      const SizedBox(width: 12),
      Text('Paramètres Livraison',
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
    ]),
  );

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(label, style: GoogleFonts.montserrat(
        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
  );

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12),
          filled: true, fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _bord)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _bord)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _acc)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);

  Widget _wilayaSelector() {
    final wilayas = _algerianWilayas();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Wilaya', style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _bord)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _wilayaCode,
            dropdownColor: _card,
            isExpanded: true,
            hint: Text('Sélectionner une wilaya',
                style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12)),
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
            items: wilayas.entries.map((e) => DropdownMenuItem(
              value: e.key,
              child: Text('${e.key} - ${e.value}'),
            )).toList(),
            onChanged: (v) => setState(() {
              _wilayaCode = v;
              _wilayaName = v != null ? wilayas[v] : null;
            }),
          ),
        ),
      ),
    ]);
  }

  Widget _prepSlider() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('Temps de préparation moyen',
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
      const Spacer(),
      Text('$_avgPrepHours h', style: GoogleFonts.montserrat(color: _acc, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
    SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _acc, thumbColor: _acc,
        inactiveTrackColor: _bord, overlayColor: _acc.withValues(alpha: 0.1),
      ),
      child: Slider(
        value: _avgPrepHours.toDouble(),
        min: 1, max: 72, divisions: 71,
        onChanged: (v) => setState(() => _avgPrepHours = v.round()),
      ),
    ),
  ]);

  Widget _weightSlider() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('Poids maximum par colis',
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
      const Spacer(),
      Text('${_maxWeightKg.toStringAsFixed(0)} kg',
          style: GoogleFonts.montserrat(color: _green, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
    SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _green, thumbColor: _green,
        inactiveTrackColor: _bord, overlayColor: _green.withValues(alpha: 0.1),
      ),
      child: Slider(
        value: _maxWeightKg,
        min: 1, max: 50, divisions: 49,
        onChanged: (v) => setState(() => _maxWeightKg = v),
      ),
    ),
  ]);

  Widget _switchRow(String title, String sub, bool value, ValueChanged<bool> onChanged) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _bord)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w700)),
          Text(sub, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: _acc, activeTrackColor: _acc.withValues(alpha: 0.4)),
      ]),
    );

  Widget _saveBtn() => GestureDetector(
    onTap: _saving ? null : _save,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_acc, Color(0xFF9B6CF7)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _saving
          ? const Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          : Text('Sauvegarder', textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w800)),
    ),
  );

  Map<int, String> _algerianWilayas() => {
    1:'Adrar',2:'Chlef',3:'Laghouat',4:'Oum El Bouaghi',5:'Batna',
    6:'Béjaïa',7:'Biskra',8:'Béchar',9:'Blida',10:'Bouira',
    11:'Tamanrasset',12:'Tébessa',13:'Tlemcen',14:'Tiaret',15:'Tizi Ouzou',
    16:'Alger',17:'Djelfa',18:'Jijel',19:'Sétif',20:'Saïda',
    21:'Skikda',22:'Sidi Bel Abbès',23:'Annaba',24:'Guelma',25:'Constantine',
    26:'Médéa',27:'Mostaganem',28:'M\'Sila',29:'Mascara',30:'Ouargla',
    31:'Oran',32:'El Bayadh',33:'Illizi',34:'Bordj Bou Arréridj',35:'Boumerdès',
    36:'El Tarf',37:'Tindouf',38:'Tissemsilt',39:'El Oued',40:'Khenchela',
    41:'Souk Ahras',42:'Tipaza',43:'Mila',44:'Aïn Defla',45:'Naâma',
    46:'Aïn Témouchent',47:'Ghardaïa',48:'Relizane',49:'Timimoun',50:'Bordj Badji Mokhtar',
    51:'Ouled Djellal',52:'Béni Abbès',53:'In Salah',54:'In Guezzam',55:'Touggourt',
    56:'Djanet',57:'El M\'Ghair',58:'El Menia',
  };
}
