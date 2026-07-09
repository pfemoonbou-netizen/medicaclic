import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_user.dart';
import '../../models/delivery_models.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';
import 'smart_delivery_activation_page.dart';
import 'smart_orders_page.dart';
import 'delivery_settings_page.dart';
import 'pickup_schedule_page.dart';
import 'delivery_analytics_page.dart';
import 'shipping_labels_page.dart';
import 'fulfillment_page.dart';

// =============================================================================
// Delivery Center — Hub principal vendeur
// =============================================================================

class DeliveryCenterPage extends StatefulWidget {
  const DeliveryCenterPage({super.key});

  @override
  State<DeliveryCenterPage> createState() => _DeliveryCenterPageState();
}

class _DeliveryCenterPageState extends State<DeliveryCenterPage> {
  static const _bgDark  = Color(0xFF07080F);
  static const _cardBg  = Color(0xFF0D0F1E);
  static const _border  = Color(0xFF1C1F35);
  static const _accent  = Color(0xFF7C3AED);
  static const _green   = Color(0xFF10E8B0);
  static const _gold    = Color(0xFFFFB800);
  static const _purp    = Color(0xFF9B6CF7);
  static const _orange  = Color(0xFFFF7A35);

  SmartDeliveryRequest? _smartRequest;
  Map<String, dynamic>  _stats = {};
  List<DeliveryPartner> _partners = [];
  bool _loading = true;
  late String _sellerId;

  @override
  void initState() {
    super.initState();
    final user = UserSession.instance.current;
    if (user.proRole != ProRole.seller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    _sellerId = user.id;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await DeliveryService.instance.loadRules();
    final results = await Future.wait([
      DeliveryService.instance.mySmartRequest(_sellerId),
      DeliveryService.instance.myDeliveryStats(_sellerId),
      DeliveryService.instance.loadPartners(),
    ]);
    if (mounted) {
      setState(() {
        _smartRequest = results[0] as SmartDeliveryRequest?;
        _stats        = results[1] as Map<String, dynamic>;
        _partners     = results[2] as List<DeliveryPartner>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _accent,
                    backgroundColor: _cardBg,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        const SizedBox(height: 16),
                        _smartStatusBanner(),
                        const SizedBox(height: 20),
                        _statsRow(),
                        const SizedBox(height: 24),
                        _sectionLabel('Services de livraison'),
                        const SizedBox(height: 12),
                        _deliveryServicesGrid(),
                        const SizedBox(height: 24),
                        _sectionLabel('Gestion'),
                        const SizedBox(height: 12),
                        _managementGrid(),
                        if (_partners.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _sectionLabel('Partenaires connectés'),
                          const SizedBox(height: 12),
                          _partnersList(),
                        ],
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _topBar() => Container(
    color: _cardBg,
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Delivery Center',
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w900)),
          Text('Gérez vos livraisons Lincoo',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
        ]),
      ),
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DeliverySettingsPage()))
            .then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 18),
        ),
      ),
    ]),
  );

  Widget _smartStatusBanner() {
    if (_smartRequest == null) {
      return _activationCard();
    }
    final status = _smartRequest!.status;
    final config = {
      SmartDeliveryRequestStatus.pending: {
        'color': _gold, 'icon': Icons.hourglass_top_rounded,
        'title': 'Smart Delivery en attente', 'sub': 'Votre demande est en cours de révision par l\'équipe Lincoo.',
      },
      SmartDeliveryRequestStatus.approved: {
        'color': _green, 'icon': Icons.verified_rounded,
        'title': 'Smart Delivery Activé ✓', 'sub': 'Vous pouvez recevoir et confirmer des commandes Smart Delivery.',
      },
      SmartDeliveryRequestStatus.rejected: {
        'color': const Color(0xFFF04040), 'icon': Icons.cancel_outlined,
        'title': 'Demande refusée', 'sub': _smartRequest!.adminNote ?? 'Contactez le support Lincoo.',
      },
      SmartDeliveryRequestStatus.suspended: {
        'color': _orange, 'icon': Icons.pause_circle_outline_rounded,
        'title': 'Smart Delivery suspendu', 'sub': 'Votre accès est temporairement suspendu.',
      },
    }[status]!;

    final color  = config['color'] as Color;
    final icon   = config['icon'] as IconData;
    final title  = config['title'] as String;
    final sub    = config['sub'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11),
              maxLines: 2),
        ])),
        if (status == SmartDeliveryRequestStatus.rejected)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SmartDeliveryActivationPage()))
                .then((_) => _load()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.4)),
              ),
              child: Text('Réessayer', style: GoogleFonts.montserrat(
                  color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }

  Widget _activationCard() => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SmartDeliveryActivationPage()))
        .then((_) => _load()),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A0F2C), Color(0xFF151B3D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accent, _purp]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(colors: [_accent, _purp]).createShader(r),
            child: Text('Activer Smart Delivery',
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 3),
          Text('Livraison groupée · Économies · Tracking',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      ]),
    ),
  );

  Widget _statsRow() => Row(children: [
    _statCard('${_stats['total'] ?? 0}', 'Commandes', _accent),
    const SizedBox(width: 10),
    _statCard('${_stats['pending'] ?? 0}', 'En attente', _gold),
    const SizedBox(width: 10),
    _statCard('${_stats['confirmationRate'] ?? 0}%', 'Confirmation', _green),
  ]);

  Widget _statCard(String val, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Text(val, style: GoogleFonts.montserrat(color: color, fontSize: 22,
            fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 0.8));

  Widget _deliveryServicesGrid() {
    final isApproved = _smartRequest?.status == SmartDeliveryRequestStatus.approved;
    return Column(children: [
      Row(children: [
        _serviceCard(
          icon: Icons.bolt_rounded,
          label: 'Smart Delivery',
          sub: 'Livraison groupée',
          color: _purp,
          badge: isApproved ? '✓ Actif' : null,
          badgeColor: _green,
          onTap: isApproved
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartOrdersPage()))
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartDeliveryActivationPage())).then((_) => _load()),
        ),
        const SizedBox(width: 10),
        _serviceCard(
          icon: Icons.local_shipping_outlined,
          label: 'Standard',
          sub: 'Livraison normale',
          color: _accent,
          onTap: () => _showComingSoon('Standard Delivery'),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _serviceCard(
          icon: Icons.flash_on_rounded,
          label: 'Express',
          sub: 'Livraison 24h',
          color: _orange,
          onTap: () => _showComingSoon('Express Delivery'),
        ),
        const SizedBox(width: 10),
        _serviceCard(
          icon: Icons.warehouse_rounded,
          label: 'Fulfillment',
          sub: 'Stockage & expédition',
          color: _gold,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FulfillmentPage())),
        ),
      ]),
    ]);
  }

  Widget _managementGrid() => Column(children: [
    Row(children: [
      _mgmtCard(Icons.calendar_today_rounded,    'Planning\nRamassage', _green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PickupSchedulePage()))),
      const SizedBox(width: 10),
      _mgmtCard(Icons.qr_code_rounded,           'Étiquettes\nColis', _accent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShippingLabelsPage()))),
      const SizedBox(width: 10),
      _mgmtCard(Icons.bar_chart_rounded,         'Analytiques\nLivraison', _purp,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryAnalyticsPage()))),
    ]),
  ]);

  Widget _serviceCard({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            if (badge != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? _green).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (badgeColor ?? _green).withValues(alpha: 0.3)),
                ),
                child: Text(badge, style: GoogleFonts.montserrat(
                    color: badgeColor ?? _green, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    ),
  );

  Widget _mgmtCard(IconData icon, String label, Color color, VoidCallback onTap) =>
    Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10,
                fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );

  Widget _partnersList() => Column(
    children: _partners.map((p) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delivery_dining_rounded, color: _accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(children: [
            if (p.supportsSmart)  _partnerBadge('Smart', _purp),
            if (p.supportsExpress) _partnerBadge('Express', _orange),
            if (p.supportsPickup)  _partnerBadge('Pickup', _accent),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (p.isActive ? _green : Colors.white24).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(p.isActive ? '● Connecté' : '○ Inactif',
              style: GoogleFonts.montserrat(
                  color: p.isActive ? _green : Colors.white38, fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    )).toList(),
  );

  Widget _partnerBadge(String label, Color color) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: GoogleFonts.montserrat(
        color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  );

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — Bientôt disponible',
          style: GoogleFonts.montserrat(fontSize: 13)),
      backgroundColor: _cardBg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }
}
