import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class CompleteBuyerPage extends StatefulWidget {
  const CompleteBuyerPage({super.key});

  @override
  State<CompleteBuyerPage> createState() => _CompleteBuyerPageState();
}

class _CompleteBuyerPageState extends State<CompleteBuyerPage> {
  final _pageCtrl = PageController();
  int _step = 0;

  final _bioCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _wilaya;
  final _interests = <String>{};

  static const _categories = [
    'Mode femme', 'Mode homme', 'Enfants', 'Beauté', 'Parfums',
    'Accessoires', 'Maison', 'Sport', 'Électronique', 'Alimentation',
  ];

  static const _wilayas = [
    'Alger', 'Oran', 'Constantine', 'Annaba', 'Blida',
    'Sétif', 'Tlemcen', 'Bejaia', 'Batna', 'Tizi Ouzou',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _stepper(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_stepProfile(), _stepInterests(), _stepAddress()],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.nearBlack),
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
          const Spacer(),
          Text('Profil Acheteur · ${_step + 1}/3',
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
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
        )),
      ),
    );
  }

  Widget _stepProfile() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
      Text('Votre profil', style: GoogleFonts.montserrat(
          color: AppColors.nearBlack, fontSize: 24, fontWeight: FontWeight.w900,
          letterSpacing: -0.4)),
      const SizedBox(height: 6),
      Text('Optionnel — personnalisez votre expérience.',
          style: GoogleFonts.montserrat( color: AppColors.gray, fontSize: 13)),
      const SizedBox(height: 28),
      Center(
        child: Stack(
          children: [
            CircleAvatar(radius: 48, backgroundColor: AppColors.bgGray,
                child: const Icon(Icons.person, size: 48, color: AppColors.lightGray)),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.dark,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      AppTextField(label: 'Bio courte', hint: 'Parlez de vous en quelques mots…',
          controller: _bioCtrl, maxLines: 3),
    ]);
  }

  Widget _stepInterests() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
      Text("Centres d'intérêt", style: GoogleFonts.montserrat(
          color: AppColors.nearBlack, fontSize: 24, fontWeight: FontWeight.w900,
          letterSpacing: -0.4)),
      const SizedBox(height: 6),
      Text('Sélectionnez vos catégories préférées.',
          style: GoogleFonts.montserrat( color: AppColors.gray, fontSize: 13)),
      const SizedBox(height: 20),
      Wrap(
        spacing: 10, runSpacing: 10,
        children: _categories.map((c) {
          final sel = _interests.contains(c);
          return GestureDetector(
            onTap: () => setState(() => sel ? _interests.remove(c) : _interests.add(c)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue])
                    : null,
                color: sel ? null : Colors.white,
                border: sel ? null : Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(32),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Text(c,
                  style: GoogleFonts.montserrat(
                      color: sel ? AppColors.nearBlack : AppColors.nearBlack,
                      fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _stepAddress() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
      Text('Adresse principale', style: GoogleFonts.montserrat(
          color: AppColors.nearBlack, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Pour estimer les frais de livraison.',
          style: GoogleFonts.montserrat( color: AppColors.gray, fontSize: 13)),
      const SizedBox(height: 24),
      Text('Wilaya', style: GoogleFonts.montserrat(
          color: AppColors.nearBlack, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: _wilaya,
        hint: Text('Choisir une wilaya',
            style: GoogleFonts.montserrat( color: const Color(0xFFCAC9C9), fontSize: 14)),
        onChanged: (v) => setState(() => _wilaya = v),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.lightGray)),
        ),
        items: _wilayas.map((w) => DropdownMenuItem(value: w,
            child: Text(w, style: GoogleFonts.montserrat( fontSize: 14)))).toList(),
      ),
      const SizedBox(height: 18),
      AppTextField(label: 'Adresse détaillée', hint: 'Rue, quartier, point de repère…',
          controller: _addressCtrl, maxLines: 2),
    ]);
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: PrimaryButton(
        label: _step < 2 ? 'Continuer' : 'Terminer',
        onPressed: () {
          if (_step < 2) {
            _pageCtrl.nextPage(duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
            setState(() => _step++);
          } else {
            Navigator.pushReplacementNamed(context, '/feed');
          }
        },
      ),
    );
  }
}
