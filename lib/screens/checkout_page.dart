import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/cart_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class _WebDragScroll extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// Mock: seller subscribed to Smart Delivery partner?
const _kSellerHasSmart = true;

const _kWilayas = [
  '01 - Adrar',           '02 - Chlef',            '03 - Laghouat',
  '04 - Oum El Bouaghi',  '05 - Batna',             '06 - Béjaïa',
  '07 - Biskra',          '08 - Béchar',            '09 - Blida',
  '10 - Bouira',          '11 - Tamanrasset',       '12 - Tébessa',
  '13 - Tlemcen',         '14 - Tiaret',            '15 - Tizi Ouzou',
  '16 - Alger',           '17 - Djelfa',            '18 - Jijel',
  '19 - Sétif',           '20 - Saïda',             '21 - Skikda',
  '22 - Sidi Bel Abbès',  '23 - Annaba',            '24 - Guelma',
  '25 - Constantine',     '26 - Médéa',             '27 - Mostaganem',
  "28 - M'Sila",          '29 - Mascara',           '30 - Ouargla',
  '31 - Oran',            '32 - El Bayadh',         '33 - Illizi',
  '34 - Bordj Bou Arréridj', '35 - Boumerdès',     '36 - El Tarf',
  '37 - Tindouf',         '38 - Tissemsilt',        '39 - El Oued',
  '40 - Khenchela',       '41 - Souk Ahras',        '42 - Tipaza',
  '43 - Mila',            '44 - Aïn Defla',         '45 - Naâma',
  '46 - Aïn Témouchent',  '47 - Ghardaïa',          '48 - Relizane',
  '49 - Timimoun',        '50 - Bordj Badji Mokhtar', '51 - Ouled Djellal',
  '52 - Béni Abbès',      '53 - In Salah',          '54 - In Guezzam',
  '55 - Touggourt',       '56 - Djanet',            "57 - El M'Ghair",
  '58 - El Meniaa',
];

const Map<String, List<String>> _kCommunes = {
  '16 - Alger': ['Alger Centre', 'Bab El Oued', 'El Harrach', 'Hussein Dey', 'Kouba', 'Bir Mourad Raïs', 'Bachdjarah', 'Dar El Beïda'],
  '31 - Oran': ['Oran Centre', 'Es Senia', 'Bir El Djir', 'Gdyel', 'Aïn El Turck', 'Arzew'],
  '25 - Constantine': ['Constantine Centre', 'El Khroub', 'Aïn Smara', 'Hamma Bouziane'],
  '09 - Blida': ['Blida', 'Boufarik', 'Larba', 'Meftah', 'Chiffa', 'Bougara'],
  '15 - Tizi Ouzou': ['Tizi Ouzou', 'Azazga', 'Boghni', 'Draa Ben Khedda', 'Larbaa Nath Irathen'],
  '23 - Annaba': ['Annaba', 'El Bouni', 'Sidi Amar', 'Aïn Berda', 'Berrahal'],
  '06 - Béjaïa': ['Béjaïa', 'Amizour', 'Akbou', 'Tichy', 'Souk El Tenine'],
  '19 - Sétif': ['Sétif', 'El Eulma', 'Aïn Oulmene', 'Bougaa', 'Aïn El Kebira'],
  '05 - Batna': ['Batna', 'Barika', 'Aïn Touta', 'Merouana', 'Arris'],
  '13 - Tlemcen': ['Tlemcen', 'Chetouane', 'Maghnia', 'Ghazaouet', 'Nedroma'],
  '35 - Boumerdès': ['Boumerdès', 'Khemis El Khechna', 'Bordj Menaïel', 'Thénia', 'Zemmouri'],
  '42 - Tipaza': ['Tipaza', 'Hadjout', 'Koléa', 'Cherchell', 'Aïn Tagourait'],
  '03 - Laghouat': ['Laghouat', 'Ksar El Hirane', 'Hassi Rmel', 'Aïn Madhi'],
  '07 - Biskra': ['Biskra', 'Ouled Djellal', 'Sidi Okba', 'Tolga', 'El Kantara'],
  '14 - Tiaret': ['Tiaret', 'Ksar Chellala', 'Sougueur', 'Frenda', 'Aïn Dheb'],
  '17 - Djelfa': ['Djelfa', 'Aïn Oussera', 'Messaad', 'Birine', 'Charef'],
  '18 - Jijel': ['Jijel', 'El Milia', 'Taher', 'Chekfa', 'Ziama Mansouriah'],
  '20 - Saïda': ['Saïda', 'Aïn El Hadjar', 'Sidi Boubekeur', 'Ouled Brahim'],
  '21 - Skikda': ['Skikda', 'Azzaba', 'Collo', 'El Harrouch', 'Ramdane Djamel'],
  '22 - Sidi Bel Abbès': ['Sidi Bel Abbès', 'Telagh', 'Tessala', 'Mostafa Ben Brahim'],
  '24 - Guelma': ['Guelma', 'Bouchegouf', 'Hammam Debagh', 'Oued Zenati'],
  '26 - Médéa': ['Médéa', 'Berrouaghia', 'Ksar El Boukhari', 'Tablat', 'Beni Slimane'],
  '27 - Mostaganem': ['Mostaganem', 'Aïn Tédelès', 'Stidia', 'Aïn Nouissy', 'Hadjadj'],
};

const _kDefaultCommunes = ['Centre-ville', 'Zone Urbaine', 'Zone Est', 'Zone Ouest', 'Zone Industrielle'];

// ─────────────────────────────────────────────────────────────────────────────

class CheckoutPage extends StatefulWidget {
  final bool isCreator;
  const CheckoutPage({super.key, this.isCreator = false});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  String  _deliveryType = 'home';      // 'home' | 'stopdesk'
  String  _deliveryMode = 'standard';  // 'fast' | 'standard' | 'smart'
  String  _payment      = 'cash';

  String? _homeWilaya;
  String? _homeCommune;
  String? _stopWilaya;
  String? _stopCommune;

  bool _loading = false;

  // Cart-driven totals
  List<CartItem> get _cartItems => CartService.instance.items;
  int get _subtotal    => _cartItems.fold<double>(0, (s, i) => s + i.total).toInt();
  int get _deliveryCost =>
      _deliveryMode == 'fast' ? 700 : _deliveryMode == 'smart' ? 450 : 350;
  int get _total => _subtotal + _deliveryCost;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Veuillez entrer votre nom complet'); return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showError('Veuillez entrer votre numéro de téléphone'); return false;
    }
    if (_deliveryType == 'home' && _homeWilaya == null) {
      _showError('Veuillez choisir votre wilaya'); return false;
    }
    if (_deliveryType == 'stopdesk' && _stopWilaya == null) {
      _showError('Veuillez choisir la wilaya du Stop Desk'); return false;
    }
    if (_cartItems.isEmpty) {
      _showError('Votre panier est vide'); return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ── Real order creation ────────────────────────────────────────────────────

  Future<void> _confirmOrder() async {
    if (!_validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { _showError('Session expirée — reconnectez-vous'); return; }

    setState(() => _loading = true);

    // First item determines the seller (single-seller cart)
    final first    = _cartItems.first;
    final sellerId = first.sellerId;
    final storeId  = first.storeId;

    final items = _cartItems.map((i) => {
      'product_id': i.id,
      'name':       i.name,
      'store_name': i.storeName,
      'qty':        i.qty,
      'unit_price': i.unitPrice.toInt(),
      'total':      i.total.toInt(),
      'size':       i.size,
      'color_name': i.colorName,
      'color_hex':  i.colorHex,
      if (i.imageUrl != null) 'image_url': i.imageUrl,
    }).toList();

    try {
      final row = await Supabase.instance.client
          .from('orders')
          .insert({
            'buyer_id':       user.id,
            if (sellerId != null) 'seller_id': sellerId,
            if (storeId  != null) 'store_id':  storeId,
            'items':          items,
            'subtotal':       _subtotal,
            'delivery_cost':  _deliveryCost,
            'total':          _total,
            'delivery_type':  _deliveryType,
            'delivery_mode':  _deliveryMode,
            'wilaya':  _deliveryType == 'home' ? _homeWilaya  : _stopWilaya,
            'commune': _deliveryType == 'home' ? _homeCommune : _stopCommune,
            'address':        _addressCtrl.text.trim(),
            'buyer_name':     _nameCtrl.text.trim(),
            'buyer_phone':    _phoneCtrl.text.trim(),
            'status':         'pending',
            'payment_method': _payment,
          })
          .select('id')
          .single();

      CartService.instance.clear();

      if (mounted) {
        setState(() => _loading = false);
        Navigator.of(context).pushReplacementNamed(
          '/order-tracking',
          arguments: row['id'] as String,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Erreur lors de la commande : $e');
      }
    }
  }

  String _fmtPrice(int p) =>
      p >= 1000 ? '${p ~/ 1000} ${(p % 1000).toString().padLeft(3, '0')}' : '$p';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Finaliser la commande',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // ── Coordonnées ──────────────────────────────────────────
              _sectionTitle('Coordonnées'),
              AppTextField(
                  label: 'Nom complet',
                  hint: 'Prénom Nom',
                  controller: _nameCtrl),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Téléphone',
                  hint: '05XXXXXXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),

              // ── Type de livraison ─────────────────────────────────────
              _sectionTitle('Type de livraison'),
              _deliveryTypeToggle(),
              const SizedBox(height: 14),
              ..._deliveryTypeFields(),

              // ── Mode de livraison ─────────────────────────────────────
              _sectionTitle('Mode de livraison'),
              _modeCard(
                id: 'fast',
                emoji: '⚡',
                title: 'Fast',
                duration: '1–2 jours ouvrables',
                price: 700,
                carrier: 'ZR Express / Yalidine',
              ),
              const SizedBox(height: 10),
              _modeCard(
                id: 'standard',
                emoji: '📦',
                title: 'Standard',
                duration: '3–5 jours ouvrables',
                price: 350,
                carrier: 'Algérie Poste / Colis Privé',
              ),
              if (_kSellerHasSmart) ...[
                const SizedBox(height: 10),
                _modeCard(
                  id: 'smart',
                  emoji: '🚀',
                  title: 'Smart Delivery',
                  duration: '2–3 jours ouvrables',
                  price: 450,
                  carrier: 'Partenaire LINCOO',
                  isSmart: true,
                ),
              ],

              // ── Mode de paiement ──────────────────────────────────────
              _sectionTitle('Mode de paiement'),
              _paymentOption(
                'cash',
                Icons.money_outlined,
                'Paiement à la livraison',
                'En espèces à la réception',
              ),
              if (widget.isCreator) ...[
                const SizedBox(height: 10),
                _paymentOption(
                  'wallet',
                  Icons.account_balance_wallet_outlined,
                  'Wallet LINCOO',
                  'Solde disponible : 5 480 DA',
                ),
              ],
              const SizedBox(height: 10),
              _paymentLocked(
                  Icons.credit_card_outlined, 'Carte CIB', 'SATIM — Réseau interbancaire'),
              const SizedBox(height: 10),
              _paymentLocked(
                  Icons.credit_card_outlined, 'Carte EDAHABIA', 'Algérie Poste'),

              // ── Récapitulatif ─────────────────────────────────────────
              _sectionTitle('Récapitulatif'),
              _summaryRow('Sous-total', '${_fmtPrice(_subtotal)} DA'),
              _summaryRow(
                _deliveryMode == 'fast'
                    ? 'Livraison Fast ⚡'
                    : _deliveryMode == 'smart'
                        ? 'Smart Delivery 🚀'
                        : 'Livraison Standard 📦',
                '${_fmtPrice(_deliveryCost)} DA',
              ),
              const Divider(color: AppColors.lightGray, height: 28),
              _summaryRow('Total', '${_fmtPrice(_total)} DA', bold: true),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: PrimaryButton(
            label: 'Confirmer la commande',
            loading: _loading,
            onPressed: _confirmOrder,
          ),
        ),
      ]),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(t,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      );

  // ── Delivery type toggle ───────────────────────────────────────────────────

  Widget _deliveryTypeToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
          color: AppColors.bgGray, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        _typeTab('home', Icons.home_outlined, 'À domicile'),
        _typeTab('stopdesk', Icons.store_outlined, 'Stop Desk'),
      ]),
    );
  }

  Widget _typeTab(String id, IconData icon, String label) {
    final sel = _deliveryType == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _deliveryType = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [const BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 2))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 17,
                color: sel ? AppColors.nearBlack : AppColors.gray),
            const SizedBox(width: 7),
            Text(label,
                style: GoogleFonts.montserrat(
                    color: sel ? AppColors.nearBlack : AppColors.gray,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  // ── Address fields based on delivery type ─────────────────────────────────

  List<Widget> _deliveryTypeFields() {
    if (_deliveryType == 'home') return _homeFields();
    return _stopDeskFields();
  }

  List<Widget> _homeFields() {
    return [
      Text('Wilaya',
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: _homeWilaya,
        isExpanded: true,
        onChanged: (v) => setState(() { _homeWilaya = v; _homeCommune = null; }),
        hint: Text('Choisir votre wilaya',
            style: GoogleFonts.montserrat(
                color: const Color(0xFFCAC9C9), fontSize: 14)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.nearBlack)),
        ),
        items: _kWilayas
            .map((w) => DropdownMenuItem(
                value: w,
                child: Text(w,
                    style: GoogleFonts.montserrat( fontSize: 13))))
            .toList(),
      ),
      // Commune chips — appear after wilaya is selected
      if (_homeWilaya != null) ...[
        const SizedBox(height: 14),
        Text('Commune / Quartier',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _communeChips(
          communes: _kCommunes[_homeWilaya] ?? _kDefaultCommunes,
          selected: _homeCommune,
          onSelect: (c) => setState(() => _homeCommune = c),
        ),
      ],
      const SizedBox(height: 12),
      AppTextField(
          label: 'Adresse complète',
          hint: 'Rue, quartier, point de repère…',
          controller: _addressCtrl,
          maxLines: 2),
    ];
  }

  List<Widget> _stopDeskFields() {
    final communes = _stopWilaya != null
        ? (_kCommunes[_stopWilaya] ?? _kDefaultCommunes)
        : null;

    return [
      // Wilaya picker button
      GestureDetector(
        onTap: _openWilayaPicker,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
                color: _stopWilaya != null
                    ? AppColors.nearBlack
                    : AppColors.lightGray,
                width: _stopWilaya != null ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.location_on_outlined,
                size: 20,
                color: _stopWilaya != null ? AppColors.nearBlack : AppColors.gray),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _stopWilaya ?? 'Choisir la wilaya (58 wilayas)',
                style: GoogleFonts.montserrat(
                    color: _stopWilaya != null
                        ? AppColors.nearBlack
                        : const Color(0xFFCAC9C9),
                    fontSize: 14),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.gray, size: 22),
          ]),
        ),
      ),

      if (communes != null) ...[
        const SizedBox(height: 14),
        Text('Commune / Point relais',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _communeChips(
          communes: communes,
          selected: _stopCommune,
          onSelect: (c) => setState(() => _stopCommune = c),
        ),
      ],
    ];
  }

  Widget _communeChips({
    required List<String> communes,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    return SizedBox(
      height: 38,
      child: ScrollConfiguration(
        behavior: _WebDragScroll(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: communes.length,
          itemBuilder: (_, i) {
            final c = communes[i];
            final sel = selected == c;
            return GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.nearBlack : Colors.white,
                  border: Border.all(
                      color: sel ? AppColors.nearBlack : AppColors.lightGray),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(c,
                    style: GoogleFonts.montserrat(
                        color: sel ? Colors.white : AppColors.nearBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openWilayaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WilayaPickerSheet(
        selected: _stopWilaya,
        onSelect: (w) => setState(() {
          _stopWilaya = w;
          _stopCommune = null;
        }),
      ),
    );
  }

  // ── Delivery mode card ─────────────────────────────────────────────────────

  Widget _modeCard({
    required String id,
    required String emoji,
    required String title,
    required String duration,
    required int price,
    required String carrier,
    bool isSmart = false,
  }) {
    final sel = _deliveryMode == id;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMode = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.nearBlack.withValues(alpha: 0.04)
              : Colors.white,
          border: Border.all(
              color: sel ? AppColors.nearBlack : AppColors.lightGray,
              width: sel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    if (isSmart) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6E1128)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Partenaire',
                            style: GoogleFonts.montserrat(
                                color: const Color(0xFF6E1128),
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('$duration · $carrier',
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
                ]),
          ),
          Text('$price DA',
              style: GoogleFonts.montserrat(
                  color: sel ? AppColors.nearBlack : AppColors.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          _radioCircle(sel),
        ]),
      ),
    );
  }

  // ── Payment options ────────────────────────────────────────────────────────

  Widget _paymentOption(
      String id, IconData icon, String label, String subtitle) {
    final sel = _payment == id;
    return GestureDetector(
      onTap: () => setState(() => _payment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.nearBlack.withValues(alpha: 0.04)
              : Colors.white,
          border: Border.all(
              color: sel ? AppColors.nearBlack : AppColors.lightGray,
              width: sel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon,
              color: sel ? AppColors.nearBlack : AppColors.gray, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
                ]),
          ),
          _radioCircle(sel),
        ]),
      ),
    );
  }

  Widget _paymentLocked(IconData icon, String label, String provider) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          border: Border.all(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.gray, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(provider,
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11)),
                ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, color: AppColors.gray, size: 12),
              const SizedBox(width: 4),
              Text('Bientôt',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _radioCircle(bool sel) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: sel ? AppColors.nearBlack : AppColors.lightGray,
              width: 2),
          color: sel ? AppColors.nearBlack : Colors.transparent,
        ),
        child: sel
            ? const Icon(Icons.check, color: Colors.white, size: 12)
            : null,
      );

  // ── Summary ────────────────────────────────────────────────────────────────

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.normal)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.normal)),
      ]),
    );
  }
}

// ── Wilaya Picker Bottom Sheet ─────────────────────────────────────────────

class _WilayaPickerSheet extends StatefulWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _WilayaPickerSheet({this.selected, required this.onSelect});

  @override
  State<_WilayaPickerSheet> createState() => _WilayaPickerSheetState();
}

class _WilayaPickerSheetState extends State<_WilayaPickerSheet> {
  List<String> _filtered = _kWilayas;

  void _search(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _kWilayas
          : _kWilayas
              .where((w) => w.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 8, 12),
          child: Row(children: [
            Expanded(
              child: Text('Choisir la wilaya',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20, color: AppColors.gray),
            ),
          ]),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: false,
            onChanged: _search,
            style: GoogleFonts.montserrat( fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher une wilaya…',
              hintStyle: GoogleFonts.montserrat(
                  color: const Color(0xFFCAC9C9), fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.gray, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.lightGray)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.lightGray)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.nearBlack)),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.bgGray),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final w = _filtered[i];
              final sel = w == widget.selected;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(w,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.normal)),
                trailing: sel
                    ? const Icon(Icons.check_circle,
                        color: AppColors.nearBlack, size: 20)
                    : null,
                onTap: () {
                  widget.onSelect(w);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
