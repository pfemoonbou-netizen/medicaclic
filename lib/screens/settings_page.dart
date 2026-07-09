import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _promoEmails = false;
  bool _darkMode = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('is_admin')
          .eq('id', session.user.id)
          .maybeSingle();
      if (mounted && row != null) {
        setState(() => _isAdmin = row['is_admin'] as bool? ?? false);
      }
    } catch (_) {}
  }

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
        title: Text('Paramètres',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _section('Compte', [
            _navTile(context, Icons.person_outline, 'Modifier le profil',
                '/edit-profile',
                iconBg: const Color(0xFFF3E5F5), iconColor: AppColors.blue),
            _navTile(context, Icons.lock_outline, 'Changer le mot de passe',
                '/forgot-password',
                iconBg: const Color(0xFFF3E5F5), iconColor: AppColors.purple),
            _navTile(context, Icons.language_outlined, 'Langue', null,
                iconBg: const Color(0xFFE8F5E9), iconColor: AppColors.success,
                trailing: Text('Français',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 13))),
            _navTile(context, Icons.phone_android_outlined, 'Numéro de téléphone', null,
                iconBg: const Color(0xFFFFF8E1), iconColor: AppColors.gold),
          ]),
          _section('Notifications', [
            _switchTile(Icons.notifications_outlined, 'Notifications push',
                _notifications, (v) => setState(() => _notifications = v),
                iconBg: const Color(0xFFF3E5F5), iconColor: AppColors.blue),
            _switchTile(Icons.email_outlined, 'Emails promotionnels',
                _promoEmails, (v) => setState(() => _promoEmails = v),
                iconBg: const Color(0xFFF3E5F5), iconColor: AppColors.purple),
          ]),
          _section('Apparence & Sécurité', [
            _switchTile(Icons.dark_mode_outlined, 'Mode sombre',
                _darkMode, (v) => setState(() => _darkMode = v),
                iconBg: const Color(0xFF1A1A2E), iconColor: Colors.white),
          ]),
          _section('Commerce', [
            _navTile(context, Icons.account_balance_wallet_outlined,
                'Wallet & paiements', '/wallet',
                iconBg: const Color(0xFFE8F5E9), iconColor: AppColors.success),
            _navTile(context, Icons.local_shipping_outlined,
                'Adresses de livraison', null,
                iconBg: const Color(0xFFFFF8E1), iconColor: AppColors.warning),
          ]),
          _section('Aide & Informations', [
            _navTile(context, Icons.help_outline, 'Centre d\'aide', '/help',
                iconBg: const Color(0xFFF3E5F5), iconColor: AppColors.blue),
            _navTile(context, Icons.privacy_tip_outlined,
                'Politique de confidentialité', null,
                iconBg: const Color(0xFFF3E5F5), iconColor: AppColors.purple),
            _navTile(context, Icons.gavel_outlined,
                'Conditions d\'utilisation', null,
                iconBg: const Color(0xFFE8F5E9), iconColor: AppColors.success),
            _navTile(context, Icons.info_outline, 'À propos de LINCOO', null,
                iconBg: AppColors.surfaceAlt, iconColor: AppColors.grayLight,
                trailing: Text('v1.0.0',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 12))),
          ]),
          if (_isAdmin)
            _section('Administration', [
              _adminTile(context),
            ]),
          _section('Zone sensible', [
            _actionTile(
              context,
              Icons.pause_circle_outline,
              'Désactiver mon compte',
              Colors.orange,
              () => _confirmDeactivate(context),
            ),
            _actionTile(
              context,
              Icons.delete_outline,
              'Supprimer mon compte',
              Colors.red,
              () => _confirmDelete(context),
            ),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _confirmLogout(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Se déconnecter',
                        style: GoogleFonts.montserrat(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
        child: Text(title.toUpperCase(),
            style: GoogleFonts.montserrat(
                color: AppColors.grayLight,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: children
              .asMap()
              .entries
              .map((e) => Column(children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(height: 1, indent: 68, color: AppColors.lightGray),
                  ]))
              .toList(),
        ),
      ),
    ]);
  }

  Widget _navTile(BuildContext context, IconData icon, String title,
      String? route,
      {Color iconBg = AppColors.surfaceAlt,
      Color iconColor = AppColors.nearBlack,
      Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.lightGray, size: 20),
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
    );
  }

  Widget _switchTile(IconData icon, String title, bool value,
      ValueChanged<bool> onChanged,
      {Color iconBg = AppColors.surfaceAlt,
      Color iconColor = AppColors.nearBlack}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.dark,
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.lightGray),
      ),
    );
  }

  Widget _adminTile(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFB06AFF), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.admin_panel_settings, color: Color(0xFF020024), size: 18),
      ),
      title: Text('Dashboard Admin',
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 13, fontWeight: FontWeight.w700)),
      subtitle: Text('Validation des comptes & KYC',
          style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
      onTap: () => Navigator.pushNamed(context, '/admin'),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String title,
      Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.montserrat(
              color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.lightGray, size: 20),
      onTap: onTap,
    );
  }

  void _confirmDeactivate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2))),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.pause_circle_outline,
                color: Colors.orange, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Désactiver mon compte',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(
            'Votre compte sera temporairement masqué.\n'
            'Vos données et commandes seront conservées.\n'
            'Vous pourrez le réactiver à tout moment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Compte désactivé. Vous avez été déconnecté.',
                        style: GoogleFonts.getFont('Montserrat')),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Désactiver mon compte',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 14)),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    String? reason;
    final reasons = [
      'Compte inactif',
      'Je crée un nouveau compte',
      'Problème de confidentialité',
      'Mauvaise expérience',
      'Autre',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2))),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_outlined,
                  color: Colors.red, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Supprimer mon compte',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'Cette action est irréversible.\n'
              'Toutes vos données, commandes et points\nseront définitivement supprimés.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Reason selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Motif de suppression',
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 13)),
                  value: reason,
                  items: reasons
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r,
                                style: GoogleFonts.montserrat(
                                    fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => reason = v),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: reason == null
                    ? null
                    : () {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Compte supprimé. À bientôt.',
                                style: GoogleFonts.getFont('Montserrat')),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.red.withValues(alpha: 0.3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Supprimer définitivement',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(sheetCtx),
              child: Text('Annuler',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Déconnexion',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?',
            style: GoogleFonts.montserrat( fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(
                    color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
            child: Text('Déconnecter',
                style: GoogleFonts.montserrat(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
