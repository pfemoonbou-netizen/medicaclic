import 'package:flutter/material.dart';

/// Barre de "stories" (style réseaux sociaux) pour mettre en avant des
/// influenceurs / professionnels santé. Premier cercle = ajouter sa story.
class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  static const _ring = Color(0xFFC913B9);

  // Influenceurs / comptes santé mis en avant (nom + couleur d'avatar).
  static const List<_Story> _stories = [
    _Story('dr.sarah', Color(0xFFE57399)),
    _Story('yasmine.h', Color(0xFF7C6BE0)),
    _Story('mama.care', Color(0xFF35B8A6)),
    _Story('dr.karim', Color(0xFF4C9BF5)),
    _Story('nadia.fit', Color(0xFFF2994A)),
    _Story('bébé.plus', Color(0xFFEB5757)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _addStory(),
          const SizedBox(width: 16),
          ..._stories.expand((s) => [_storyItem(s), const SizedBox(width: 16)]),
        ],
      ),
    );
  }

  Widget _addStory() {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: const Icon(Icons.person, color: Color(0xFFB0B0B0), size: 34),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EA0FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Vous', style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _storyItem(_Story s) {
    final initials = s.name.replaceAll('.', ' ').trim().isEmpty
        ? '?'
        : s.name.replaceAll(RegExp(r'[^a-zA-Z]'), '').substring(0, 1).toUpperCase();
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _ring, width: 2.5),
            ),
            child: CircleAvatar(
              backgroundColor: s.color,
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Text(s.name, style: const TextStyle(color: Colors.black, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Story {
  final String name;
  final Color color;
  const _Story(this.name, this.color);
}
