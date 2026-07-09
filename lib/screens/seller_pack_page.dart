import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/pack_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pack catalogue
// ─────────────────────────────────────────────────────────────────────────────

class _PackDef {
  final String       id;
  final String       emoji;
  final String       name;
  final String       tagline;
  final int          priceDzd;       // monthly price for starter, annual for essentiel/pro
  final bool         isAnnual;
  final double       commissionRate;
  final Color        color;
  final List<String> features;
  final List<String> locked;
  final bool         popular;

  const _PackDef({
    required this.id,
    required this.emoji,
    required this.name,
    required this.tagline,
    required this.priceDzd,
    required this.isAnnual,
    required this.commissionRate,
    required this.color,
    required this.features,
    required this.locked,
    this.popular = false,
  });

  String get commissionLabel {
    final pct = (commissionRate * 100).toStringAsFixed(0);
    return '$pct% / vente';
  }

  String get billingLabel => isAnnual ? 'DZD/an' : 'DZD/mois';

  // Equivalent monthly for annual packs
  String? get monthlyEquiv {
    if (!isAnnual) return null;
    final m = priceDzd ~/ 12;
    return '≈ ${_fmtStatic(m)} DA/mois';
  }

  static String _fmtStatic(int n) {
    if (n >= 1000) {
      final k = n ~/ 1000;
      final r = n % 1000;
      return r == 0 ? '$k 000' : '$k ${r.toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

const _packs = [
  _PackDef(
    id: 'starter',
    emoji: '🛍️',
    name: 'Starter',
    tagline: 'Commencez à vendre sans engagement annuel',
    priceDzd: 1500,
    isAnnual: false,
    commissionRate: 0.05,
    color: Color(0xFF6B7280),
    features: [
      '1 boutique',
      '15 produits max',
      'Gestion des commandes',
      'Suivi livraisons',
      'Ma Crédibilité — Consultation',
      'Support FAQ',
    ],
    locked: [
      'Messages clients',
      'Stats basiques',
      'Dashboard avancé + Delivery Analytics',
      'Pickup Schedule & Shipping Labels',
      'Reels produits',
      'Boost placement Feed',
      'Outils IA (Automatisations, Coach IA)',
    ],
  ),
  _PackDef(
    id: 'essentiel',
    emoji: '⭐',
    name: 'Essentiel',
    tagline: 'L\'outil pro pour gérer votre boutique',
    priceDzd: 20000,
    isAnnual: true,
    commissionRate: 0.03,
    color: Color(0xFF7C3AED),
    features: [
      'Tout du Starter',
      '300 produits max',
      '1 boutique',
      'Messages clients',
      'Stats basiques',
      'Suivi livraisons',
      'Pickup Schedule',
      'Shipping Labels',
      'Boost placement Feed — Achat à l\'unité',
      'Ma Crédibilité — Consultation',
      'Support Standard — 48h',
    ],
    locked: [
      'Dashboard avancé + Delivery Analytics',
      'Reels produits',
      'Boost Feed inclus (3/mois)',
      'Outils IA (Automatisations, Coach IA)',
      'Badge Pro vérifié',
    ],
    popular: true,
  ),
  _PackDef(
    id: 'pro',
    emoji: '💎',
    name: 'Pro',
    tagline: 'Performance maximale pour scaler',
    priceDzd: 40000,
    isAnnual: true,
    commissionRate: 0.03,
    color: Color(0xFFA855F7),
    features: [
      'Tout de l\'Essentiel',
      'Produits illimités',
      'Jusqu\'à 3 boutiques',
      'Dashboard avancé + Delivery Analytics',
      'Reels produits',
      'Boost placement Feed — 3/mois inclus + à l\'unité',
      'Outils IA (Automatisations, Coach IA)',
      'Ma Crédibilité — Consultation + Badge Pro vérifié',
      'Support Prioritaire — 12h',
    ],
    locked: [],
  ),
];

// Light theme colors
const _pageBg   = Color(0xFFF5F4F0);
const _cardBg   = Color(0xFFFFFFFF);
const _border   = Color(0xFFE5E3DD);
const _textPri  = Color(0xFF1A1A1A);
const _textSec  = Color(0xFF6B7280);
const _textMut  = Color(0xFFAAABAD);

// ─────────────────────────────────────────────────────────────────────────────

class SellerPackPage extends StatefulWidget {
  const SellerPackPage({super.key});

  @override
  State<SellerPackPage> createState() => _SellerPackPageState();
}

class _SellerPackPageState extends State<SellerPackPage> {
  int  _step = 0; // 0 = choose, 1 = payment
  bool _saving   = false;
  int  _selected = 1;
  String? _paymentRef;

  String _fmt(int n) {
    if (n >= 1000) {
      final k = n ~/ 1000;
      final r = n % 1000;
      return r == 0 ? '$k 000' : '$k ${r.toString().padLeft(3, '0')}';
    }
    return '$n';
  }

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);

    final pack = _packs[_selected];
    final ref  = 'LINC-${pack.id.toUpperCase()}-${Random().nextInt(999999).toString().padLeft(6, '0')}';

    try {
      await Supabase.instance.client.from('seller_packs').insert({
        'seller_id':   user.id,
        'pack_type':   pack.id,
        'status':      'pending_payment',
        'price_dzd':   pack.priceDzd,
        'payment_ref': ref,
      });
      PackService.instance.clear();
      if (mounted) setState(() { _paymentRef = ref; _step = 1; _saving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e', style: GoogleFonts.montserrat(fontSize: 12)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: _step == 0 ? _buildChooser() : _buildPayment(),
      ),
    );
  }

  // ── Step 0 ─────────────────────────────────────────────────────────────────

  Widget _buildChooser() {
    final pack = _packs[_selected];
    return Column(children: [
      _buildHeader(),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text('Choisissez le plan qui correspond à vos ambitions',
            style: GoogleFonts.montserrat(color: _textSec, fontSize: 12),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: _packs.length,
          itemBuilder: (_, i) => _packCard(i),
        ),
      ),
      _buildCta(pack),
    ]);
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPri, size: 16),
        ),
      ),
      const Spacer(),
      Column(children: [
        Text('Lincoo Packs',
            style: GoogleFonts.montserrat(color: _textPri, fontSize: 18, fontWeight: FontWeight.w900)),
        Container(
          margin: const EdgeInsets.only(top: 2),
          height: 2, width: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ]),
      const Spacer(),
      const SizedBox(width: 36),
    ]),
  );

  Widget _packCard(int i) {
    final p   = _packs[i];
    final sel = _selected == i;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selected = i); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(
            color: sel ? p.color : _border,
            width: sel ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: sel
              ? [BoxShadow(color: p.color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(p.name,
                        style: GoogleFonts.montserrat(
                            color: sel ? p.color : _textPri,
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    if (p.popular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('POPULAIRE',
                            style: GoogleFonts.montserrat(
                                color: Colors.white, fontSize: 8,
                                fontWeight: FontWeight.w900, letterSpacing: .5)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  // Commission badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.commissionRate == 0
                          ? Colors.green.withValues(alpha: 0.10)
                          : p.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(p.commissionLabel,
                        style: GoogleFonts.montserrat(
                            color: p.commissionRate == 0
                                ? Colors.green.shade700
                                : p.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text(p.tagline,
                      style: GoogleFonts.montserrat(color: _textSec, fontSize: 11)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmt(p.priceDzd),
                    style: GoogleFonts.montserrat(
                        color: sel ? p.color : _textPri,
                        fontSize: 18, fontWeight: FontWeight.w900)),
                Text(p.billingLabel,
                    style: GoogleFonts.montserrat(color: _textMut, fontSize: 10)),
                if (p.monthlyEquiv != null)
                  Text(p.monthlyEquiv!,
                      style: GoogleFonts.montserrat(color: _textMut, fontSize: 9)),
              ]),
            ]),

            // Feature list
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: sel ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const Divider(color: _border, height: 1),
                  const SizedBox(height: 12),
                  ...p.features.map((f) => _featureRow(f, true, p.color)),
                  if (p.locked.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...p.locked.map((f) => _featureRow(f, false, p.color)),
                  ],
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _featureRow(String text, bool included, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(
        included ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
        size: 15,
        color: included ? color : _textMut,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: GoogleFonts.montserrat(
                color: included ? _textPri : _textMut,
                fontSize: 12,
                fontWeight: included ? FontWeight.w600 : FontWeight.w400)),
      ),
    ]),
  );

  Widget _buildCta(_PackDef pack) => Container(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    child: Column(children: [
      // Stats row
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ctaStat('✓ Paiement', 'Virement bancaire'),
          _ctaDivider(),
          _ctaStat('⏱ Activation', '24–48h'),
          _ctaDivider(),
          _ctaStat('📞 Support', 'Inclus'),
        ]),
      ),
      // Button
      GestureDetector(
        onTap: _saving ? null : _submit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            color: pack.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: pack.color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Commander ${pack.name} — ${_fmt(pack.priceDzd)} ${pack.billingLabel}',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    ]),
  );

  Widget _ctaStat(String label, String val) => Column(children: [
    Text(label, style: GoogleFonts.montserrat(color: _textSec, fontSize: 10, fontWeight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text(val, style: GoogleFonts.montserrat(color: _textPri, fontSize: 11, fontWeight: FontWeight.w800)),
  ]);

  Widget _ctaDivider() => Container(width: 1, height: 28, color: _border);

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  Widget _buildPayment() {
    final pack = _packs[_selected];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(children: [
        // Header
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _cardBg, border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPri, size: 16),
            ),
          ),
          const Spacer(),
          Text('Finaliser la commande',
              style: GoogleFonts.montserrat(color: _textPri, fontSize: 16, fontWeight: FontWeight.w800)),
          const Spacer(),
          const SizedBox(width: 36),
        ]),

        const SizedBox(height: 32),

        // Success badge
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: pack.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: pack.color.withValues(alpha: 0.3), width: 2),
          ),
          child: Center(child: Text(pack.emoji, style: const TextStyle(fontSize: 38))),
        ),
        const SizedBox(height: 16),
        Text('Commande ${pack.name} enregistrée !',
            style: GoogleFonts.montserrat(color: _textPri, fontSize: 18, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Effectuez le virement et envoyez votre preuve de paiement',
            style: GoogleFonts.montserrat(color: _textSec, fontSize: 12),
            textAlign: TextAlign.center),

        const SizedBox(height: 28),
        _payCard(pack),
        const SizedBox(height: 20),
        _stepCard('1', 'Effectuez le virement',
            'Montant : ${_fmt(pack.priceDzd)} DZD\nVirement bancaire au RIB ci-dessus', pack.color),
        const SizedBox(height: 8),
        _stepCard('2', 'Notez votre référence',
            'Référence : ${_paymentRef ?? ''}\nIndiquez-la dans le libellé du virement', pack.color),
        const SizedBox(height: 8),
        _stepCard('3', 'Activation automatique',
            'Après vérification admin (24–48h), votre pack s\'activera automatiquement', pack.color),
        const SizedBox(height: 28),

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, height: 54,
            decoration: BoxDecoration(
              color: pack.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: pack.color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: Text('Retour au profil',
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _payCard(_PackDef pack) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _cardBg,
      border: Border.all(color: pack.color.withValues(alpha: 0.25), width: 1.5),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.account_balance_rounded, color: pack.color, size: 20),
        const SizedBox(width: 10),
        Text('Informations de paiement',
            style: GoogleFonts.montserrat(color: _textPri, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 16),
      _infoRow('Bénéficiaire', 'LINCOO SPA'),
      _infoRow('Banque', 'CPA — Crédit Populaire d\'Algérie'),
      _infoRow('RIB', '007 00700 0007007007 07'),
      const Divider(color: _border, height: 24),
      _infoRow('Montant', '${_fmt(pack.priceDzd)} DZD', highlight: true, color: pack.color),
      _infoRow('Pack', pack.name, highlight: true, color: pack.color),
      _infoRow('Référence', _paymentRef ?? '', highlight: true, color: pack.color, copyable: true),
    ]),
  );

  Widget _infoRow(String label, String value,
      {bool highlight = false, Color? color, bool copyable = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.montserrat(color: _textSec, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.montserrat(
                    color: highlight ? (color ?? _textPri) : _textPri,
                    fontSize: 12,
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w500)),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Référence copiée',
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white)),
                  backgroundColor: color ?? AppColors.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Icon(Icons.copy_rounded, size: 14, color: color?.withValues(alpha: 0.7)),
            ),
        ]),
      );

  Widget _stepCard(String num, String title, String desc, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardBg,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(num,
              style: GoogleFonts.montserrat(
                  color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.montserrat(
                  color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(desc,
              style: GoogleFonts.montserrat(color: _textSec, fontSize: 11, height: 1.5)),
        ]),
      ),
    ]),
  );
}
