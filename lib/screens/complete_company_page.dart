import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class CompleteCompanyPage extends StatefulWidget {
  const CompleteCompanyPage({super.key});

  @override
  State<CompleteCompanyPage> createState() => _CompleteCompanyPageState();
}

class _CompleteCompanyPageState extends State<CompleteCompanyPage> {
  final _pageCtrl = PageController();
  int _step = 0;
  static const _total = 5;

  final _raison = TextEditingController();
  final _marque = TextEditingController();
  final _handle = TextEditingController();
  final _rib = TextEditingController();
  final _repName = TextEditingController();
  final _repRole = TextEditingController();
  String _presence = 'Les deux';
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_raison, _marque, _handle, _rib, _repName, _repRole]) {
      c.dispose();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < _total - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _step++);
      return;
    }
    setState(() => _loading = true);
    try {
      await UserSession.instance.registerCompanyPending();
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

  @override
  Widget build(BuildContext context) {
    final steps = [
      _stepIdentity(),
      _stepDocs(),
      _stepRep(),
      _stepBank(),
      _stepPresence(),
    ];
    final titles = [
      'Identité entreprise',
      'Documents légaux',
      'Représentant légal',
      'Coordonnées bancaires',
      'Type de présence',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            _header(titles[_step]),
            _stepper(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                size: 20, color: AppColors.nearBlack),
            onPressed: () {
              if (_step > 0) {
                _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                setState(() => _step--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Text(title,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3)),
          ),
          Text('${_step + 1}/$_total',
              style: GoogleFonts.montserrat(
                  color: AppColors.grayLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _stepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(
          _total,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _total - 1 ? 5 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  gradient: i <= _step
                      ? const LinearGradient(
                          colors: [AppColors.accent, AppColors.blue])
                      : null,
                  color: i <= _step ? null : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepIdentity() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Identité de l\'entreprise',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          AppTextField(
              label: 'Raison sociale', hint: 'Ex : SARL LINCOO', controller: _raison),
          const SizedBox(height: 16),
          AppTextField(
              label: 'Marque / Nom commercial', hint: 'Ex : LINCOO', controller: _marque),
          const SizedBox(height: 16),
          AppTextField(
              label: 'Identifiant (@handle)', hint: '@lincoo_officiel', controller: _handle),
        ]);
  }

  Widget _stepDocs() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Documents légaux',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Vos documents sont sécurisés et traités de façon confidentielle.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 24),
          _docTile('Registre de Commerce (RC)', Icons.assignment_outlined),
          const SizedBox(height: 12),
          _docTile('NIF (Numéro d\'Identification Fiscale)', Icons.numbers_outlined),
          const SizedBox(height: 12),
          _docTile('NIS (Numéro d\'Identification Statistique)', Icons.bar_chart_outlined),
          const SizedBox(height: 12),
          _docTile('Article d\'imposition', Icons.receipt_long_outlined),
        ]);
  }

  Widget _stepRep() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Représentant légal',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          AppTextField(label: 'Nom complet', hint: 'Prénom Nom', controller: _repName),
          const SizedBox(height: 16),
          AppTextField(label: 'Fonction', hint: 'Ex : Gérant, PDG…', controller: _repRole),
          const SizedBox(height: 16),
          _docTile('Pièce d\'identité', Icons.credit_card_outlined),
        ]);
  }

  Widget _stepBank() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Coordonnées bancaires',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Pour recevoir vos paiements et remboursements.',
              style:
                  GoogleFonts.montserrat( color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 24),
          AppTextField(
              label: 'RIB compte entreprise',
              hint: '0000000000000000000000',
              controller: _rib),
        ]);
  }

  Widget _stepPresence() {
    final options = [
      _PresenceOpt('Vente de produits', Icons.shopping_bag_outlined,
          'Boutique en ligne + produits'),
      _PresenceOpt('Campagnes publicitaires', Icons.campaign_outlined,
          'Publicité & sponsoring'),
      _PresenceOpt('Les deux', Icons.all_inclusive_outlined,
          'Produits + campagnes'),
    ];

    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Type de présence',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          ...options.map((o) {
            final sel = _presence == o.label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _presence = o.label),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.dark.withValues(alpha: 0.05)
                        : Colors.transparent,
                    border: Border.all(
                        color: sel ? AppColors.dark : AppColors.lightGray,
                        width: sel ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(o.icon,
                          color: sel ? AppColors.dark : AppColors.gray,
                          size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.label,
                                  style: GoogleFonts.montserrat(
                                      color: AppColors.nearBlack,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Text(o.sub,
                                  style: GoogleFonts.montserrat(
                                      color: AppColors.gray, fontSize: 12)),
                            ]),
                      ),
                      if (sel)
                        const Icon(Icons.check_circle,
                            color: AppColors.dark, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ]);
  }

  Widget _docTile(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.gray, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 13))),
        const Icon(Icons.upload_outlined, color: AppColors.blue, size: 20),
      ]),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: PrimaryButton(
        label: _step < _total - 1 ? 'Continuer' : 'Soumettre',
        onPressed: _loading ? null : _next,
        loading: _loading,
      ),
    );
  }
}

class _PresenceOpt {
  final String label;
  final IconData icon;
  final String sub;
  const _PresenceOpt(this.label, this.icon, this.sub);
}
