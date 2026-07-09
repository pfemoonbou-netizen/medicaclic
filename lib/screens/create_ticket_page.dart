import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  String _category = 'Commande';
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitted = false;
  bool _loading = false;

  static const _categories = [
    'Commande', 'Paiement', 'Livraison', 'Compte', 'Contenu', 'Autre',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Créer un ticket',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text('Catégorie',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final sel = _category == c;
                    return GestureDetector(
                      onTap: () => setState(() => _category = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.dark : Colors.transparent,
                          border: Border.all(
                              color: sel ? AppColors.dark : AppColors.lightGray),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Text(c,
                            style: GoogleFonts.montserrat(
                                color: sel ? Colors.white : AppColors.nearBlack,
                                fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                AppTextField(
                    label: 'Sujet',
                    hint: 'Décrivez brièvement le problème',
                    controller: _subjectCtrl),
                const SizedBox(height: 16),
                AppTextField(
                    label: 'Description',
                    hint: 'Expliquez votre problème en détail…',
                    controller: _descCtrl,
                    maxLines: 5),
                const SizedBox(height: 16),
                Text('Pièces jointes (optionnel)',
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightGray,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.attach_file,
                          color: AppColors.gray, size: 20),
                      const SizedBox(width: 10),
                      Text('Ajouter une capture d\'écran…',
                          style: GoogleFonts.montserrat(
                              color: AppColors.gray, fontSize: 13)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: PrimaryButton(
              label: 'Envoyer le ticket',
              loading: _loading,
              onPressed: _subjectCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await Future.delayed(const Duration(milliseconds: 800));
                      if (mounted) setState(() { _loading = false; _submitted = true; });
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(44),
                ),
                child: const Icon(Icons.confirmation_number_outlined,
                    color: AppColors.blue, size: 44),
              ),
              const SizedBox(height: 20),
              Text('Ticket envoyé !',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Notre équipe vous répondra dans les 24h.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 13, height: 1.6)),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Retour à l\'aide',
                onPressed: () => Navigator.pushReplacementNamed(context, '/help'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
