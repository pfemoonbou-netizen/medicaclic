import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';
import '../widgets/primary_button.dart';

class PendingVerificationPage extends StatefulWidget {
  const PendingVerificationPage({super.key});

  @override
  State<PendingVerificationPage> createState() => _PendingVerificationPageState();
}

class _PendingVerificationPageState extends State<PendingVerificationPage> {
  Timer? _timer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    // Vérifie toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _pollStatus());
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pollStatus() async {
    if (_dialogShown) return;
    try {
      final userId = UserSession.instance.current.id;
      if (userId == 'demo' || userId.isEmpty) return;

      final row = await Supabase.instance.client
          .from('profiles')
          .select('pro_status')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted || row == null) return;
      final status = row['pro_status'] as String? ?? 'none';

      if (status == 'verified' && !_dialogShown) {
        _dialogShown = true;
        _timer?.cancel();
        await UserSession.instance.onAdminVerified();
        if (mounted) _showApprovedAndNavigate();
      } else if (status == 'rejected' && !_dialogShown) {
        _dialogShown = true;
        _timer?.cancel();
        if (mounted) _showRejectedDialog();
      }
    } catch (_) {}
  }

  void _showApprovedAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: AppColors.accent, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Compte approuvé !',
              style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.nearBlack),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Votre boutique est maintenant active. Bienvenue sur LINCOO !',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: AppColors.gray, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/store');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Accéder à ma boutique',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontWeight: FontWeight.w800,
                      fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          ),
        ]),
      ),
    );
  }

  void _showRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Demande refusée',
              style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.nearBlack),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Votre dossier n\'a pas été approuvé. Vérifiez vos documents et réessayez.',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: AppColors.gray, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/complete-seller');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Soumettre à nouveau',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontWeight: FontWeight.w800,
                      fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 50, color: AppColors.gold),
            ),
            const SizedBox(height: 28),
            Text('En cours de vérification',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 24,
                    fontWeight: FontWeight.w900, letterSpacing: -0.3)),
            const SizedBox(height: 12),
            Text(
                'Votre dossier est en cours d\'examen par notre équipe.\nDélai estimé : 24 à 72 heures.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 14, height: 1.65)),
            const SizedBox(height: 36),
            _statusTile(Icons.send_outlined, 'Dossier soumis',
                'Reçu — en attente d\'examen', done: true),
            _statusTile(Icons.manage_search_outlined, 'Vérification en cours',
                'Notre équipe examine vos documents', active: true),
            _statusTile(Icons.verified_outlined, 'Validation',
                'Vous recevrez une notification'),
            const Spacer(),
            PrimaryButton(
              label: 'Contacter le support',
              onPressed: () => Navigator.pushNamed(context, '/help'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/feed'),
              child: Text('Explorer l\'application',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue, fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _statusTile(IconData icon, String title, String sub,
      {bool done = false, bool active = false}) {
    final Color fg = done
        ? AppColors.success
        : active
            ? AppColors.gold
            : AppColors.lightGray;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: active
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.30))
              : null,
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: fg),
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
                  Text(sub,
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 11.5)),
                ]),
          ),
          if (done)
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 16),
            ),
          if (active)
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2.5,
                  backgroundColor:
                      AppColors.gold.withValues(alpha: 0.20)),
            ),
        ]),
      ),
    );
  }
}
