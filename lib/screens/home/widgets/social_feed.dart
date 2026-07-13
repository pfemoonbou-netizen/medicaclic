import 'package:flutter/material.dart';
import '../../../data/influencers.dart';
import '../influencer_profile_screen.dart';

/// Fil de publications (style réseau social) pour les influenceurs / pros
/// santé. Cartes propres, sans images réseau (visuels dégradés + icônes).
class SocialFeed extends StatelessWidget {
  const SocialFeed({super.key});

  static const List<_Post> _posts = [
    _Post(
      user: 'forma',
      avatarColor: Color(0xFF2E4636),
      avatarImage: 'assets/images/influencers/forma_logo.jpg',
      caption: "Plonge dans l'univers de Forma 🌿 Un détoxifiant naturel qui purifie ton corps et t'aide à brûler les graisses efficacement.",
      likes: 512,
      comments: 63,
      timeAgo: 'il y a 15 min',
      imageColors: [Color(0xFF2E4636), Color(0xFF3E5C48)],
      imageIcon: Icons.eco,
      sponsored: true,
      postImages: [
        'assets/images/influencers/forma_pub2.jpg',
        'assets/images/influencers/forma_pub1.jpg',
      ],
    ),
    _Post(
      user: 'dr.sarah',
      avatarColor: Color(0xFFE57399),
      avatarImage: 'assets/images/influencers/influencer3.jpg',
      caption: "Pensez à bien vous hydrater pendant la grossesse 💧 Au moins 1,5L d'eau par jour pour vous et bébé.",
      likes: 128,
      comments: 16,
      timeAgo: 'il y a 30 min',
      imageColors: [Color(0xFFEC5A8D), Color(0xFF7C6BE0)],
      imageIcon: Icons.water_drop,
      sponsored: true,
    ),
    _Post(
      user: 'dr.karim',
      avatarColor: Color(0xFF4C9BF5),
      avatarImage: 'assets/images/influencers/influencer2.jpg',
      caption: "3 étirements simples pour soulager le mal de dos au bureau. Enregistrez ce post ! 🧘",
      likes: 205,
      comments: 27,
      timeAgo: 'il y a 2 h',
      imageColors: [Color(0xFF4C9BF5), Color(0xFF35B8A6)],
      imageIcon: Icons.self_improvement,
      sponsored: false,
    ),
    _Post(
      user: 'amine.h',
      avatarColor: Color(0xFF7C6BE0),
      avatarImage: 'assets/images/influencers/influencer1.jpg',
      caption: "Bien manger, c'est la base ! 🥗 Privilégiez les fruits, légumes et une bonne hydratation.",
      likes: 342,
      comments: 41,
      timeAgo: 'il y a 5 h',
      imageColors: [Color(0xFF35B8A6), Color(0xFF4C9BF5)],
      imageIcon: Icons.restaurant,
      sponsored: false,
    ),
    _Post(
      user: 'amine.h',
      avatarColor: Color(0xFF7C6BE0),
      avatarImage: 'assets/images/influencers/influencer1.jpg',
      caption: "Repas équilibré du soir 🥩 Protéines, légumes verts et féculents : le combo parfait pour bien récupérer.",
      likes: 289,
      comments: 34,
      timeAgo: 'il y a 8 h',
      imageColors: [Color(0xFF7C6BE0), Color(0xFF35B8A6)],
      imageIcon: Icons.dinner_dining,
      sponsored: false,
      postImages: ['assets/images/influencers/post_steak.jpg'],
    ),
    _Post(
      user: 'amine.h',
      avatarColor: Color(0xFF7C6BE0),
      avatarImage: 'assets/images/influencers/influencer1.jpg',
      caption: "Petit-déjeuner healthy 🍓 Yaourt, fruits frais et granola pour bien commencer la journée.",
      likes: 176,
      comments: 22,
      timeAgo: 'il y a 1 j',
      imageColors: [Color(0xFFE57399), Color(0xFFF2994A)],
      imageIcon: Icons.breakfast_dining,
      sponsored: false,
      postImages: ['assets/images/influencers/post_bowl.jpg'],
    ),
    _Post(
      user: 'nadia.fit',
      avatarColor: Color(0xFFF2994A),
      caption: "Séance de gainage à la maison 💪 15 minutes chaque matin pour renforcer tout le corps.",
      likes: 231,
      comments: 29,
      timeAgo: 'il y a 12 h',
      imageColors: [Color(0xFFF2994A), Color(0xFF4C9BF5)],
      imageIcon: Icons.fitness_center,
      sponsored: false,
      postImages: ['assets/images/influencers/post_plank.jpg', 'assets/images/influencers/post_yoga.jpg'],
    ),
    _Post(
      user: 'nadia.fit',
      avatarColor: Color(0xFFF2994A),
      caption: "N'oubliez pas de vous hydrater après le sport 💧 L'eau, votre meilleure alliée !",
      likes: 154,
      comments: 18,
      timeAgo: 'il y a 1 j',
      imageColors: [Color(0xFF4C9BF5), Color(0xFF35B8A6)],
      imageIcon: Icons.local_drink,
      sponsored: false,
      postImages: ['assets/images/influencers/post_water.jpg'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Publications', style: TextStyle(color: Color(0xFF101623), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._posts.map((p) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _PostCard(post: p))),
      ],
    );
  }
}

class _PostCard extends StatefulWidget {
  final _Post post;
  const _PostCard({required this.post});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;
  bool _saved = false;
  int _page = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openProfile(BuildContext context, String username) {
    final inf = influencerByName(username);
    if (inf == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => InfluencerProfileScreen(influencer: inf)));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final likeCount = p.likes + (_liked ? 1 : 0);
    final initial = p.user.replaceAll(RegExp(r'[^a-zA-Z]'), '').substring(0, 1).toUpperCase();
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [BoxShadow(color: Color(0x11000000), offset: Offset(0, 2), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => _openProfile(context, p.user),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: p.avatarImage != null
                          ? Image.asset(p.avatarImage!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _initialAvatar(p.avatarColor, initial))
                          : _initialAvatar(p.avatarColor, initial),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p.user, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold))),
                  const Icon(Icons.more_horiz, color: Colors.black54),
                ],
              ),
            ),
          ),
          // Image (carrousel de photos réelles, ou dégradé + icône)
          if (p.postImages.isNotEmpty)
            AspectRatio(
              aspectRatio: 0.85,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: p.postImages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Image.asset(
                      p.postImages[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => Container(
                        color: p.imageColors.first,
                        child: Icon(p.imageIcon, color: Colors.white.withValues(alpha: 0.9), size: 72),
                      ),
                    ),
                  ),
                  if (p.postImages.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.postImages.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 8 : 6,
                            height: active ? 8 : 6,
                            decoration: BoxDecoration(color: active ? const Color(0xFF31B5FF) : Colors.white70, shape: BoxShape.circle),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            )
          else
            AspectRatio(
              aspectRatio: 1.2,
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: p.imageColors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Center(child: Icon(p.imageIcon, color: Colors.white.withValues(alpha: 0.9), size: 72)),
              ),
            ),
          // Sponsored CTA
          if (p.sponsored)
            Container(
              width: double.infinity,
              color: const Color(0xFF1EA0FF),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Row(
                children: [
                  Expanded(child: Text('En savoir plus', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                  Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ],
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _liked = !_liked),
                  child: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? const Color(0xFFEB5757) : Colors.black87, size: 26),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.mode_comment_outlined, color: Colors.black87, size: 24),
                const SizedBox(width: 16),
                const Icon(Icons.send_outlined, color: Colors.black87, size: 24),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _saved = !_saved),
                  child: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, color: Colors.black87, size: 24),
                ),
              ],
            ),
          ),
          // Likes + caption + comments
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$likeCount J\'aime', style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.3),
                    children: [
                      TextSpan(text: '${p.user} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: p.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Voir les ${p.comments} commentaires', style: const TextStyle(color: Color(0xFF6E6E6E), fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundColor: Color(0xFFDDDDDD), child: Icon(Icons.person, size: 14, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Ajouter un commentaire...', style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 14))),
                    const Text('❤️  🙌', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.timeAgo, style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar(Color color, String initial) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _Post {
  final String user;
  final Color avatarColor;
  final String? avatarImage;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final List<Color> imageColors;
  final IconData imageIcon;
  final bool sponsored;
  final List<String> postImages;
  const _Post({
    required this.user,
    required this.avatarColor,
    this.avatarImage,
    this.postImages = const [],
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.imageColors,
    required this.imageIcon,
    required this.sponsored,
  });
}
