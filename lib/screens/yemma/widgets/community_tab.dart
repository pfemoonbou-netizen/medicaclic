import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/yemma_provider.dart';
import '../yemma_theme.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _Post {
  final String author;
  final String timeAgo;
  final String text;
  int likes;
  final int views;
  final int comments;
  bool liked;
  bool saved;
  _Post({required this.author, required this.timeAgo, required this.text, this.likes = 0, this.views = 0, this.comments = 0, this.liked = false, this.saved = false});
}

class _CommunityTabState extends State<CommunityTab> {
  static const _filters = ['Suggérés', 'Abonnements', 'Récents'];
  String _filter = 'Suggérés';

  final List<_Post> _localPosts = [
    _Post(author: 'Amina B.', timeAgo: 'il y a 2h', text: 'Mon bébé de 3 mois ne dort pas la nuit 😩 Vous avez des astuces qui ont marché pour vous ?', likes: 128, views: 1200, comments: 34),
    _Post(author: 'Sara M.', timeAgo: 'il y a 5h', text: 'On commence la diversification à 6 mois. Par quels aliments avez-vous débuté ?', likes: 89, views: 830, comments: 21),
    _Post(author: 'Nawel K.', timeAgo: 'il y a 1j', text: 'Grosses douleurs de dos au 3e trimestre… comment vous soulagez-vous ? La ceinture lombaire aide-t-elle ?', likes: 210, views: 2100, comments: 56),
  ];

  String _fmtCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  void _openCompose() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Poser une question', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: YemmaColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Écris ta question à la communauté…',
                  hintStyle: const TextStyle(color: YemmaColors.textFaint),
                  filled: true,
                  fillColor: YemmaColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YemmaColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YemmaColors.border)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final t = controller.text.trim();
                    if (t.isEmpty) return;
                    setState(() => _localPosts.insert(0, _Post(author: 'Vous', timeAgo: "à l'instant", text: t)));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: YemmaColors.pink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Posts de la base (s'il y en a) convertis + posts locaux.
    final dbPosts = context.watch<YemmaProvider>().communityPosts.map(
          (p) => _Post(author: p.author, timeAgo: p.timeAgo, text: p.question, likes: p.likes, comments: p.replies),
        );
    final posts = [..._localPosts, ...dbPosts];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            // En-tête + recherche
            Row(
              children: [
                const Text('Communauté', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: YemmaColors.card, shape: BoxShape.circle, border: Border.all(color: YemmaColors.border)),
                  child: const Icon(Icons.search, color: YemmaColors.pink, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Filtres
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: YemmaColors.border)),
              child: Row(
                children: _filters.map((f) {
                  final active = f == _filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: active ? YemmaColors.pink : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                        child: Text(f, style: TextStyle(color: active ? Colors.white : YemmaColors.pink, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ...posts.map(_postCard),
          ],
        ),
        // Bouton flottant "+"
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTap: _openCompose,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: YemmaColors.pink,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: YemmaColors.pink.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _postCard(_Post p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YemmaColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: YemmaColors.pink.withValues(alpha: 0.15), child: const Icon(Icons.person, color: YemmaColors.pink, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.author, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(p.timeAgo, style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => p.saved = !p.saved),
                  child: Icon(p.saved ? Icons.bookmark : Icons.bookmark_border, color: p.saved ? YemmaColors.pink : YemmaColors.textFaint, size: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(p.text, style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 14, height: 1.4)),
          ),
          const Divider(height: 1, color: YemmaColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    p.liked = !p.liked;
                    p.likes += p.liked ? 1 : -1;
                  }),
                  child: Row(
                    children: [
                      Icon(p.liked ? Icons.favorite : Icons.favorite_border, size: 18, color: p.liked ? YemmaColors.pink : YemmaColors.textFaint),
                      const SizedBox(width: 5),
                      Text(_fmtCount(p.likes), style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                if (p.views > 0) ...[
                  const Icon(Icons.visibility_outlined, size: 18, color: YemmaColors.textFaint),
                  const SizedBox(width: 5),
                  Text(_fmtCount(p.views), style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
                  const SizedBox(width: 20),
                ],
                const Icon(Icons.chat_bubble_outline, size: 17, color: YemmaColors.textFaint),
                const SizedBox(width: 5),
                Text(_fmtCount(p.comments), style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
