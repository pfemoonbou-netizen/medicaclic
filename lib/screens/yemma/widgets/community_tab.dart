import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/yemma_provider.dart';
import '../yemma_theme.dart';

class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<YemmaProvider>().communityPosts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: YemmaColors.border)),
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: YemmaColors.pink),
              SizedBox(width: 10),
              Expanded(child: Text('Poser une question à la communauté...', style: TextStyle(color: YemmaColors.textFaint, fontSize: 13))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...posts.map((post) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 16, backgroundColor: Colors.transparent, child: Icon(Icons.person_outline, color: YemmaColors.textFaint, size: 18)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.author, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(post.timeAgo, style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(post.question, style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 14, height: 1.3)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 16, color: YemmaColors.textFaint),
                    const SizedBox(width: 4),
                    Text('${post.likes}', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 16, color: YemmaColors.textFaint),
                    const SizedBox(width: 4),
                    Text('${post.replies} réponses', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
