import 'package:flutter/material.dart';
import '../../data/influencers.dart';

/// Page profil d'un influenceur (style réseau social) : avatar, stats,
/// bio, boutons, et grille de publications.
class InfluencerProfileScreen extends StatelessWidget {
  final InfluencerInfo influencer;
  const InfluencerProfileScreen({super.key, required this.influencer});

  static const _ring = Color(0xFFC913B9);

  @override
  Widget build(BuildContext context) {
    final inf = influencer;
    // Grille : on remplit avec les vraies images si dispo, sinon placeholders.
    final tiles = List.generate(9, (i) {
      if (inf.gridImages.isNotEmpty) return inf.gridImages[i % inf.gridImages.length];
      return null;
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(inf.username, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            if (inf.verified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Color(0xFF1EA0FF), size: 18),
            ],
          ],
        ),
        centerTitle: true,
        actions: const [Icon(Icons.notifications_none), SizedBox(width: 12), Icon(Icons.more_vert), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // Avatar avec anneau
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _ring, width: 2.5)),
                  child: ClipOval(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: inf.avatar != null
                          ? Image.asset(inf.avatar!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _initial(inf))
                          : _initial(inf),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('${inf.posts}', 'Posts'),
                      _stat(formatCount(inf.followers), 'Abonnés'),
                      _stat(formatCount(inf.following), 'Abonn.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inf.username, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(inf.category, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(inf.bio, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _button('Suivre', const Color(0xFF1EA0FF), Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _button('Message', const Color(0x33EFEFEF), Colors.white)),
                const SizedBox(width: 8),
                _button('', const Color(0x33EFEFEF), Colors.white, icon: Icons.person_add_alt),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Icon(Icons.grid_on, color: Colors.white, size: 24),
          ),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          // Grille de posts
          GridView.count(
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: tiles.map((img) => _gridTile(img, inf)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _initial(InfluencerInfo inf) {
    final letter = inf.username.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    return Container(
      color: inf.color,
      alignment: Alignment.center,
      child: Text(letter.isEmpty ? '?' : letter.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _button(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: icon != null
          ? Icon(icon, color: fg, size: 18)
          : Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _gridTile(String? img, InfluencerInfo inf) {
    if (img != null) {
      return Image.asset(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => _gridPlaceholder(inf));
    }
    return _gridPlaceholder(inf);
  }

  Widget _gridPlaceholder(InfluencerInfo inf) {
    return Container(
      color: inf.color.withValues(alpha: 0.25),
      child: Icon(Icons.image_outlined, color: inf.color.withValues(alpha: 0.7), size: 32),
    );
  }
}
