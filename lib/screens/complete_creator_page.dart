import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class CompleteCreatorPage extends StatefulWidget {
  const CompleteCreatorPage({super.key});

  @override
  State<CompleteCreatorPage> createState() => _CompleteCreatorPageState();
}

class _CompleteCreatorPageState extends State<CompleteCreatorPage> {
  final _pageCtrl = PageController();
  int _step = 0;
  static const _total = 4;

  final _handle = TextEditingController();
  final _bio = TextEditingController();
  final _insta = TextEditingController();
  final _tiktok = TextEditingController();
  final _rib = TextEditingController();
  bool _affiliateOptIn = false;
  final _niches = <String>{};
  bool _loading = false;

  static const _nicheOptions = [
    'Mode', 'Beauté', 'Lifestyle', 'Food', 'Sport',
    'Tech', 'Voyage', 'Humour', 'Éducation', 'Autre',
  ];

  @override
  void dispose() {
    for (final c in [_handle, _bio, _insta, _tiktok, _rib]) {
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
      await UserSession.instance.registerCreatorPending();
      final uid = UserSession.instance.current.id;

      // Extended fields — added by migration; silent if not yet applied
      try {
        await Supabase.instance.client.from('profiles').update({
          'username_requested': _handle.text.trim().isEmpty ? null : _handle.text.trim(),
          'bio':                _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          'instagram_url':      _insta.text.trim().isEmpty ? null : _insta.text.trim(),
          'tiktok_url':         _tiktok.text.trim().isEmpty ? null : _tiktok.text.trim(),
          'niches':             _niches.toList(),
        }).eq('id', uid);
      } catch (_) {}

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
    final steps = [_stepProfile(), _stepContent(), _stepMonetisation(), _stepVerif()];
    final titles = ['Profil créateur', 'Niche & contenu', 'Monétisation', 'Vérification'];

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), AppColors.blue]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('${_step + 1}/$_total',
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
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
              padding: EdgeInsets.only(right: i < _total - 1 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  gradient: i <= _step
                      ? const LinearGradient(
                          colors: [Color(0xFF7B1FA2), AppColors.blue])
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

  Widget _stepProfile() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Votre profil créateur',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Center(
            child: Stack(children: [
              CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.bgGray,
                  child: const Icon(Icons.person, size: 48, color: AppColors.lightGray)),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: const Color(0xFF7B1FA2),
                          borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 20),
          AppTextField(
              label: 'Handle (@)',
              hint: '@mon_handle',
              controller: _handle),
          const SizedBox(height: 16),
          AppTextField(
              label: 'Bio',
              hint: 'Décrivez-vous en quelques mots…',
              controller: _bio,
              maxLines: 3),
          const SizedBox(height: 16),
          AppTextField(
              label: 'Instagram',
              hint: '@instagram',
              controller: _insta,
              prefixIcon: const Icon(Icons.link, size: 18, color: AppColors.gray)),
          const SizedBox(height: 16),
          AppTextField(
              label: 'TikTok',
              hint: '@tiktok',
              controller: _tiktok,
              prefixIcon: const Icon(Icons.link, size: 18, color: AppColors.gray)),
        ]);
  }

  Widget _stepContent() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Niche & type de contenu',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Choisissez vos catégories de contenu.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _nicheOptions.map((n) {
              final sel = _niches.contains(n);
              return GestureDetector(
                onTap: () => setState(
                    () => sel ? _niches.remove(n) : _niches.add(n)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF7B1FA2)
                        : Colors.transparent,
                    border: Border.all(
                        color: sel
                            ? const Color(0xFF7B1FA2)
                            : AppColors.lightGray),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(n,
                      style: GoogleFonts.montserrat(
                          color: sel ? Colors.white : AppColors.nearBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Mini portfolio (1-3 médias)',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.lightGray,
                            style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.gray, size: 28),
                    ),
                  ),
                ),
              );
            }),
          ),
        ]);
  }

  Widget _stepMonetisation() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Monétisation',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Optionnel — pour recevoir vos gains d\'affiliation.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 24),
          AppTextField(
              label: 'RIB / CCP', hint: 'Pour recevoir vos gains', controller: _rib),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _affiliateOptIn,
                  onChanged: (v) =>
                      setState(() => _affiliateOptIn = v ?? false),
                  activeColor: const Color(0xFF7B1FA2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Programme d\'affiliation LINCOO',
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(
                            'Gagnez une commission sur chaque vente via vos liens.',
                            style: GoogleFonts.montserrat(
                                color: AppColors.gray, fontSize: 12)),
                      ]),
                ),
              ],
            ),
          ),
        ]);
  }

  Widget _stepVerif() {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('Vérification (optionnelle)',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
              'Email et téléphone déjà vérifiés.\nAjoutez une pièce d\'identité pour obtenir le badge créateur.',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13, height: 1.6)),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 10),
            Text('Email vérifié',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 10),
            Text('Téléphone vérifié',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 14)),
          ]),
          const SizedBox(height: 24),
          _docTile('Pièce d\'identité (optionnel)', Icons.credit_card_outlined),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.workspace_premium, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Badge créateur débloqué après vérification',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack, fontSize: 13)),
              ),
            ]),
          ),
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
