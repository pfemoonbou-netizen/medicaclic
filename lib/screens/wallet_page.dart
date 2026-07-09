import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
class WalletPage extends StatelessWidget {
  final bool isCreator;
  const WalletPage({super.key, this.isCreator = false});

  static const _transactions = [
    _Tx('Remboursement commande #998', '+1400 DA', true, '15 juin'),
    _Tx('Paiement commande #1001', '-6300 DA', false, '12 juin'),
    _Tx('Commission affiliation', '+280 DA', true, '10 juin'),
    _Tx('Rechargement Wallet', '+5000 DA', true, '5 juin'),
    _Tx('Paiement commande #995', '-4900 DA', false, '1 juin'),
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
        title: Text('Wallet LINCOO',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: isCreator ? _buildCreatorWallet() : _buildBuyerLocked(context),
    );
  }

  Widget _buildBuyerLocked(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Locked icon
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.bgGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                size: 40, color: AppColors.gray),
          ),
          const SizedBox(height: 20),
          Text('Wallet LINCOO',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 12, color: AppColors.accent),
              const SizedBox(width: 5),
              Text('Bientôt disponible pour les acheteurs',
                  style: GoogleFonts.montserrat(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 20),
          Text(
            'Le Wallet LINCOO est actuellement réservé aux créateurs & boutiques.\nIl sera disponible pour les acheteurs très prochainement.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 32),
          // Feature preview cards (grayed out)
          Row(children: [
            _previewFeature(Icons.add_circle_outline, 'Recharger'),
            const SizedBox(width: 10),
            _previewFeature(Icons.shopping_bag_outlined, 'Payer'),
            const SizedBox(width: 10),
            _previewFeature(Icons.percent, 'Cashback'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _previewFeature(Icons.send_outlined, 'Transférer'),
            const SizedBox(width: 10),
            _previewFeature(Icons.history, 'Historique'),
            const SizedBox(width: 10),
            _previewFeature(Icons.card_giftcard_outlined, 'Cadeaux'),
          ]),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.notifications_outlined,
                  size: 18, color: Colors.white),
              label: Text('Me notifier à l\'ouverture',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nearBlack,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewFeature(IconData icon, String label) {
    return Expanded(
      child: Opacity(
        opacity: 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, size: 22, color: AppColors.nearBlack),
            const SizedBox(height: 5),
            Text(label,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildCreatorWallet() {
    return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.dark, Color(0xFF3D3B3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                Text('Solde disponible',
                    style: GoogleFonts.montserrat(
                        color: Colors.white54, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Text('5 480 DA',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('≈ 40.10 USD · 36.87 EUR',
                  style: GoogleFonts.montserrat(
                      color: Colors.white38, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),
          // Action buttons
          Row(children: [
            Expanded(child: _actionBtn(Icons.add, 'Recharger', () {})),
            const SizedBox(width: 12),
            Expanded(child: _actionBtn(Icons.send_outlined, 'Transférer', () {})),
            const SizedBox(width: 12),
            Expanded(child: _actionBtn(Icons.history, 'Historique', () {})),
          ]),
          const SizedBox(height: 24),
          Text('Moyens de rechargement',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _lockedCard(
            icon: Icons.credit_card_outlined,
            color: const Color(0xFF1976D2),
            title: 'Carte CIB',
            subtitle: 'SATIM — Réseau interbancaire algérien',
          ),
          const SizedBox(height: 10),
          _lockedCard(
            icon: Icons.credit_card_outlined,
            color: const Color(0xFFFFC107),
            title: 'Carte EDAHABIA',
            subtitle: 'Algérie Poste',
          ),
          const SizedBox(height: 24),
          Text('Transactions récentes',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._transactions.map(_txTile),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.lightGray),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text('Voir tout l\'historique',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 13)),
          ),
        ],
      );
  }

  Widget _lockedCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.7),
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

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: AppColors.nearBlack),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _txTile(_Tx tx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: tx.isCredit
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: tx.isCredit ? Colors.green : Colors.red,
              size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.label,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 13,
                    fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(tx.date,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 11)),
          ]),
        ),
        Text(tx.amount,
            style: GoogleFonts.montserrat(
                color: tx.isCredit ? Colors.green : Colors.red,
                fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Tx {
  final String label, amount, date;
  final bool isCredit;
  const _Tx(this.label, this.amount, this.isCredit, this.date);
}
