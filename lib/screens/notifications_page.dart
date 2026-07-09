import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  final List<_Notif> _notifs = [
    _Notif(Icons.local_shipping_rounded, 'Commande expédiée',
        'Votre commande #1002 est en route.', 'À l\'instant',
        false, _NotifType.order),
    _Notif(Icons.favorite_rounded, 'Nouveau like',
        'LOOLET STORE a aimé votre post.', 'Il y a 1h',
        false, _NotifType.like),
    _Notif(Icons.star_rounded, 'Avis publié',
        'Votre avis sur SUMMER LOOLET SCRAF a été validé.', 'Il y a 3h',
        true, _NotifType.review),
    _Notif(Icons.campaign_rounded, 'Promotion',
        'Soldes d\'été : -30% chez LOOLET STORE jusqu\'à dimanche !', 'Hier',
        true, _NotifType.promo),
    _Notif(Icons.person_add_rounded, 'Nouvel abonné',
        'femmedz vous suit maintenant.', 'Hier',
        true, _NotifType.follow),
    _Notif(Icons.check_circle_rounded, 'Livraison confirmée',
        'Commande #1001 livrée. Donnez votre avis.', 'Il y a 3j',
        true, _NotifType.order),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _unreadCount => _notifs.where((n) => !n.read).length;

  void _markAllRead() {
    setState(() {
      for (var n in _notifs) {
        n.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(children: [
            _buildHeader(context),
            Expanded(child: _buildList()),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 12),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.nearBlack),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notifications',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            if (_unreadCount > 0)
              Text('$_unreadCount non lues',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
          ]),
        ),
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            child: Text('Tout lire',
                style: GoogleFonts.montserrat(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _buildList() {
    final today = _notifs
        .where((n) => n.time.contains('instant') || n.time.contains('h'))
        .toList();
    final yesterday = _notifs.where((n) => n.time == 'Hier').toList();
    final earlier =
        _notifs.where((n) => n.time.contains('j')).toList();

    return ListView(
      children: [
        if (today.isNotEmpty) ...[
          _sectionLabel("Aujourd'hui"),
          ...today.map(_buildTile),
        ],
        if (yesterday.isNotEmpty) ...[
          _sectionLabel('Hier'),
          ...yesterday.map(_buildTile),
        ],
        if (earlier.isNotEmpty) ...[
          _sectionLabel('Plus tôt'),
          ...earlier.map(_buildTile),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(label,
            style: GoogleFonts.montserrat(
                color: AppColors.grayLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      );

  Widget _buildTile(_Notif n) {
    return Dismissible(
      key: Key(n.title + n.time),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.08),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => setState(() => _notifs.remove(n)),
      child: GestureDetector(
        onTap: () => setState(() => n.read = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.fromLTRB(12, 3, 12, 3),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.read ? Colors.white : AppColors.blue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.read
                  ? Colors.transparent
                  : AppColors.blue.withValues(alpha: 0.12),
            ),
            boxShadow: n.read ? AppShadows.soft : [],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: n.type.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(n.icon, color: n.type.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(n.title,
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 13,
                                fontWeight:
                                    n.read ? FontWeight.w600 : FontWeight.w800)),
                      ),
                      Text(n.time,
                          style: GoogleFonts.montserrat(
                              color: AppColors.grayLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 3),
                    Text(n.body,
                        style: GoogleFonts.montserrat(
                            color: AppColors.gray,
                            fontSize: 12,
                            height: 1.45)),
                  ]),
            ),
            if (!n.read) ...[
              const SizedBox(width: 8),
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: AppColors.blue, shape: BoxShape.circle),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

enum _NotifType { order, like, review, promo, follow }

extension _NotifTypeExt on _NotifType {
  Color get bgColor => switch (this) {
        _NotifType.order  => const Color(0xFFF3E5F5),
        _NotifType.like   => const Color(0xFFFFEBEE),
        _NotifType.review => const Color(0xFFFFF8E1),
        _NotifType.promo  => const Color(0xFFE8F5E9),
        _NotifType.follow => const Color(0xFFF3E5F5),
      };

  Color get iconColor => switch (this) {
        _NotifType.order  => AppColors.blue,
        _NotifType.like   => AppColors.error,
        _NotifType.review => AppColors.gold,
        _NotifType.promo  => AppColors.success,
        _NotifType.follow => AppColors.purple,
      };
}

class _Notif {
  final IconData icon;
  final String title, body, time;
  bool read;
  final _NotifType type;
  _Notif(this.icon, this.title, this.body, this.time, this.read, this.type);
}
