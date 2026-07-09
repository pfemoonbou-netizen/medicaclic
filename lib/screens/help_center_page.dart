import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _faqs = [
    _Faq('Comment passer une commande ?',
        'Ajoutez des articles à votre panier, puis appuyez sur "Passer la commande" et suivez les étapes de livraison et paiement.'),
    _Faq('Puis-je annuler ma commande ?',
        'Vous pouvez annuler une commande tant qu\'elle n\'a pas été expédiée par le vendeur.'),
    _Faq('Comment retourner un article ?',
        'Rendez-vous dans "Mes Commandes", sélectionnez la commande et appuyez sur "Demander un retour" dans les 7 jours.'),
    _Faq('Quand serai-je livré ?',
        'Le délai de livraison dépend de votre wilaya. Généralement entre 2 à 5 jours ouvrables.'),
    _Faq('Comment devenir vendeur ?',
        'Créez un compte, choisissez le rôle "Vendeur" et complétez votre profil avec vos documents.'),
  ];

  @override
  Widget build(BuildContext context) {
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
        title: Text('Centre d\'aide',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              const Icon(Icons.search, color: AppColors.gray, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans l\'aide…',
                    hintStyle: GoogleFonts.montserrat(
                        color: const Color(0xFFCAC9C9), fontSize: 13),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.montserrat( fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          // Quick actions
          Row(children: [
            Expanded(child: _quickBtn(context, Icons.chat_bubble_outline,
                'Chat IA', '/chatbot', AppColors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _quickBtn(context, Icons.confirmation_number_outlined,
                'Ticket', '/create-ticket', AppColors.accent)),
          ]),
          const SizedBox(height: 24),
          Text('Questions fréquentes',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._faqs.map((f) => _faqTile(f)),
          const SizedBox(height: 20),
          Text('Catégories',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...[
            ('Commandes & livraison', Icons.local_shipping_outlined),
            ('Paiement & remboursement', Icons.payment_outlined),
            ('Compte & sécurité', Icons.lock_outline),
            ('Vendeurs & boutiques', Icons.storefront_outlined),
            ('Contenu & Reels', Icons.videocam_outlined),
            ('Signaler un problème', Icons.flag_outlined),
          ].map((cat) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(cat.$2, color: AppColors.gray, size: 20),
            ),
            title: Text(cat.$1,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
            onTap: () {},
          )),
        ],
      ),
    );
  }

  Widget _quickBtn(BuildContext context, IconData icon, String label,
      String route, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.montserrat(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _faqTile(_Faq faq) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(faq.q,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(faq.a,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}
