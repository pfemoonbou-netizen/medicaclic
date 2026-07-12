import 'package:flutter/material.dart';
import 'yemma_theme.dart';
import 'widgets/pain_tab.dart';
import 'widgets/baby_tab.dart';
import 'widgets/pregnancy_tab.dart';
import 'widgets/community_tab.dart';

class YemmaScreen extends StatefulWidget {
  const YemmaScreen({super.key});
  @override
  State<YemmaScreen> createState() => _YemmaScreenState();
}

class _YemmaScreenState extends State<YemmaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YemmaColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: YemmaColors.pink.withValues(alpha: 0.5))),
                    child: const Icon(Icons.child_care, color: YemmaColors.pink, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Yemma ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            Text('يمّا', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Text('Santé maternelle & infantile', style: TextStyle(color: YemmaColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('4.8', style: TextStyle(color: YemmaColors.pink, fontSize: 13, fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Icon(Icons.star, color: YemmaColors.pink, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: YemmaColors.border))),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: YemmaColors.pink,
                labelColor: YemmaColors.pink,
                unselectedLabelColor: YemmaColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(icon: Icon(Icons.monitor_heart_outlined, size: 18), text: 'Douleurs'),
                  Tab(icon: Icon(Icons.child_friendly_outlined, size: 18), text: 'Bébé'),
                  Tab(icon: Icon(Icons.pregnant_woman_outlined, size: 18), text: 'Grossesse'),
                  Tab(icon: Icon(Icons.forum_outlined, size: 18), text: 'Communauté'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  PainTab(),
                  BabyTab(),
                  PregnancyTab(),
                  CommunityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
