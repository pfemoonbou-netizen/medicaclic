import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/delivery_models.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';

class SmartDeliveryActivationPage extends StatefulWidget {
  const SmartDeliveryActivationPage({super.key});
  @override
  State<SmartDeliveryActivationPage> createState() => _SmartDeliveryActivationPageState();
}

class _SmartDeliveryActivationPageState extends State<SmartDeliveryActivationPage> {
  static const _bg    = Color(0xFF07080F);
  static const _card  = Color(0xFF0D0F1E);
  static const _bord  = Color(0xFF1C1F35);
  static const _acc   = Color(0xFF4F8EFF);
  static const _green = Color(0xFF10E8B0);
  static const _gold  = Color(0xFFFFB800);
  static const _purp  = Color(0xFF9B6CF7);

  int  _step = 0; // 0=intro, 1=contract, 2=conditions, 3=status
  bool _contractAccepted = false;
  bool _conditionsAccepted = false;
  bool _submitting = false;
  SmartDeliveryRequest? _request;
  late String _sellerId;
  late String _storeName;

  @override
  void initState() {
    super.initState();
    final u = UserSession.instance.current;
    _sellerId  = u.id;
    _storeName = u.displayName;
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final req = await DeliveryService.instance.mySmartRequest(_sellerId);
    if (req != null && mounted) setState(() { _request = req; _step = 3; });
  }

  Future<void> _submit() async {
    if (!_contractAccepted || !_conditionsAccepted) return;
    setState(() => _submitting = true);
    try {
      await DeliveryService.instance.submitSmartRequest(
        sellerId: _sellerId, storeName: _storeName, contractSigned: true,
      );
      final req = await DeliveryService.instance.mySmartRequest(_sellerId);
      if (mounted) setState(() { _request = req; _step = 3; });
    } catch (e) {
      if (mounted) _snack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(child: Column(children: [
      _topBar(),
      Expanded(child: _body()),
    ])),
  );

  Widget _topBar() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
      const SizedBox(width: 12),
      Text('Activer Smart Delivery',
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
    ]),
  );

  Widget _body() {
    if (_step == 3) return _statusView();
    return IndexedStack(index: _step, children: [_introView(), _contractView(), _conditionsView()]);
  }

  Widget _introView() => ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 20),
    Center(child: Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_acc, _purp]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 40),
    )),
    const SizedBox(height: 24),
    Text('Lincoo Smart Delivery', textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Text('Livraison groupée intelligente pour vos commandes',
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13)),
    const SizedBox(height: 32),
    ...[
      ('⚡', 'Livraison groupée', 'Plusieurs vendeurs, une seule livraison pour l\'acheteur'),
      ('💰', 'Économies', 'Jusqu\'à 40% de réduction sur les frais vs livraison individuelle'),
      ('📦', 'Confirmation rapide', '6h pour confirmer chaque commande Smart'),
      ('🔁', 'Tracking en temps réel', 'Suivi complet du colis du ramassage à la livraison'),
      ('🎯', 'Smart Basket', 'Regroupement intelligent selon wilaya et zone'),
    ].map((e) => _featureRow(e.$1, e.$2, e.$3)),
    const SizedBox(height: 32),
    _primaryBtn('Lire le contrat', () => setState(() => _step = 1)),
  ]);

  Widget _featureRow(String emoji, String title, String sub) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _bord)),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(sub, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11)),
      ])),
    ]),
  );

  Widget _contractView() => ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 10),
    Text('Contrat Smart Delivery', style: GoogleFonts.montserrat(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text('Version 1.0 — Lincoo Algeria', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
    const SizedBox(height: 20),
    _contractBox(),
    const SizedBox(height: 16),
    _checkRow('J\'ai lu et j\'accepte le contrat Smart Delivery', _contractAccepted,
        (v) => setState(() => _contractAccepted = v ?? false)),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: _outlineBtn('Retour', () => setState(() => _step = 0))),
      const SizedBox(width: 12),
      Expanded(child: _primaryBtn('Suivant', _contractAccepted ? () => setState(() => _step = 2) : null)),
    ]),
  ]);

  Widget _conditionsView() => ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 10),
    Text('Conditions d\'utilisation', style: GoogleFonts.montserrat(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 20),
    _conditionsBox(),
    const SizedBox(height: 16),
    _checkRow('J\'accepte les conditions d\'utilisation', _conditionsAccepted,
        (v) => setState(() => _conditionsAccepted = v ?? false)),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: _outlineBtn('Retour', () => setState(() => _step = 1))),
      const SizedBox(width: 12),
      Expanded(child: _submitting
          ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
          : _primaryBtn('Envoyer la demande', (_contractAccepted && _conditionsAccepted) ? _submit : null)),
    ]),
  ]);

  Widget _statusView() {
    final req = _request;
    if (req == null) return const SizedBox();
    final config = {
      SmartDeliveryRequestStatus.pending: {
        'icon': Icons.hourglass_top_rounded, 'color': _gold,
        'title': 'Demande envoyée', 'sub': 'L\'équipe Lincoo révise votre dossier. Vous serez notifié sous 24-48h.',
      },
      SmartDeliveryRequestStatus.approved: {
        'icon': Icons.check_circle_rounded, 'color': _green,
        'title': 'Smart Delivery Activé !', 'sub': 'Félicitations ! Vous pouvez maintenant recevoir des commandes Smart Delivery.',
      },
      SmartDeliveryRequestStatus.rejected: {
        'icon': Icons.cancel_rounded, 'color': const Color(0xFFF04040),
        'title': 'Demande refusée', 'sub': req.adminNote ?? 'Votre demande a été refusée. Contactez le support.',
      },
      SmartDeliveryRequestStatus.suspended: {
        'icon': Icons.pause_circle_rounded, 'color': const Color(0xFFFF7A35),
        'title': 'Accès suspendu', 'sub': 'Votre accès Smart Delivery est temporairement suspendu.',
      },
    }[req.status]!;

    final color = config['color'] as Color;
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 90, height: 90,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Icon(config['icon'] as IconData, color: color, size: 44),
        ),
        const SizedBox(height: 24),
        Text(config['title'] as String, textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(config['sub'] as String, textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Text('Soumis le ${_fmtDate(req.createdAt)}',
            style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 11)),
        const SizedBox(height: 32),
        _primaryBtn('Retour au Delivery Center', () => Navigator.pop(context)),
      ]),
    ));
  }

  Widget _contractBox() => Container(
    padding: const EdgeInsets.all(16), height: 220,
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(13), border: Border.all(color: _bord)),
    child: SingleChildScrollView(child: Text(
      '''CONTRAT DE PARTENARIAT SMART DELIVERY — LINCOO

Article 1 — Objet
Le présent contrat régit les conditions d'utilisation du service Smart Delivery de la plateforme Lincoo par le Vendeur.

Article 2 — Obligations du Vendeur
- Confirmer ou refuser chaque commande Smart dans un délai de 6 heures.
- Préparer les commandes confirmées dans les délais convenus.
- Respecter les dimensions et poids maximaux définis par Lincoo.
- Être disponible aux créneaux de ramassage planifiés.

Article 3 — Tarification
Les frais de livraison Smart Delivery sont partagés entre les vendeurs du même groupe selon les règles en vigueur.

Article 4 — Responsabilités
Lincoo assure la coordination avec le partenaire logistique. Le Vendeur est responsable du bon emballage des produits.

Article 5 — Résiliation
Lincoo se réserve le droit de suspendre l'accès Smart Delivery en cas de non-respect répété des délais de confirmation.''',
      style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 11, height: 1.6),
    )),
  );

  Widget _conditionsBox() => Container(
    padding: const EdgeInsets.all(16), height: 220,
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(13), border: Border.all(color: _bord)),
    child: SingleChildScrollView(child: Text(
      '''CONDITIONS D'UTILISATION SMART DELIVERY

1. Délais de confirmation
Chaque commande Smart Delivery doit être confirmée ou refusée dans un délai maximum de 6 heures après réception.

2. Qualité d'emballage
Les produits doivent être correctement emballés avant le ramassage.

3. Disponibilité
Le vendeur doit maintenir ses créneaux de disponibilité à jour dans les paramètres de livraison.

4. Poids et dimensions
Les colis ne doivent pas dépasser les limites définies (30 kg max, 100×60×60 cm max).

5. Annulations
Plus de 3 refus injustifiés par mois peuvent entraîner la suspension temporaire du service.

6. Litiges
En cas de litige, Lincoo agit comme médiateur entre le vendeur et l'acheteur.''',
      style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 11, height: 1.6),
    )),
  );

  Widget _checkRow(String label, bool value, ValueChanged<bool?> onChanged) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: _acc,
          checkColor: Colors.white,
          side: const BorderSide(color: Color(0xFF1C1F35), width: 1.5)),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12)),
      )),
    ],
  );

  Widget _primaryBtn(String label, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: onTap != null
            ? const LinearGradient(colors: [_acc, _purp])
            : null,
        color: onTap == null ? const Color(0xFF1C1F35) : null,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
              color: onTap != null ? Colors.white : Colors.white38,
              fontSize: 13, fontWeight: FontWeight.w800)),
    ),
  );

  Widget _outlineBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1C1F35)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
    ),
  );

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFF0D0F1E)));
}
