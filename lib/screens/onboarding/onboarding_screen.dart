import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _OnboardPage {
  final Color accent;
  final IconData icon;
  final String badgeEmoji;
  final String badgeText;
  final String title;
  final String description;
  const _OnboardPage({required this.accent, required this.icon, required this.badgeEmoji, required this.badgeText, required this.title, required this.description});
}

const _kBackground = Color(0xFF0D1714);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      accent: Color(0xFF1AA88F),
      icon: Icons.medical_services_outlined,
      badgeEmoji: '🏥',
      badgeText: '500+ Médecins',
      title: 'Des médecins de\nconfiance',
      description: 'Consultez les meilleurs spécialistes algériens. Pédiatrie, cardiologie, gynécologie et plus — disponibles près de chez vous.',
    ),
    _OnboardPage(
      accent: Color(0xFFE0588F),
      icon: Icons.family_restroom_outlined,
      badgeEmoji: '😊',
      badgeText: 'Yemma يمّا',
      title: 'La santé de\nvotre famille',
      description: 'Suivi de grossesse, carnet de vaccination bébé, communauté de mamans. Tout ce dont vous avez besoin en un seul endroit.',
    ),
    _OnboardPage(
      accent: Color(0xFF1AA88F),
      icon: Icons.home_repair_service_outlined,
      badgeEmoji: '🏠',
      badgeText: 'À domicile',
      title: 'Soins à\ndomicile',
      description: 'Infirmiers, kinésithérapeutes, gardes malades — des professionnels de santé qui se déplacent chez vous à tout moment.',
    ),
    _OnboardPage(
      accent: Color(0xFFF2994A),
      icon: Icons.medical_information_outlined,
      badgeEmoji: '🛍',
      badgeText: 'Boutique médicale',
      title: 'Équipements\ncertifiés',
      description: 'Achetez ou louez du matériel médical certifié. Tensiomètres, fauteuils roulants, orthopédie — livraison à domicile.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.go('/login');

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  void _previous() {
    _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _pages[_page].accent;
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
                    child: Text('${_page + 1}/${_pages.length}', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Passer', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_double_arrow_right, size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_page + 1) / _pages.length,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardPageView(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? accent : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLast ? 'Commencer' : 'Suivant', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Icon(isLast ? Icons.check : Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Visibility(
                visible: _page > 0,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: GestureDetector(
                  onTap: _previous,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 16, color: Colors.white54),
                      SizedBox(width: 6),
                      Text('Précédent', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: page.accent, width: 1.5),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [page.accent.withValues(alpha: 0.18), page.accent.withValues(alpha: 0.04)],
                    ),
                  ),
                  child: Center(child: Icon(page.icon, size: 96, color: page.accent.withValues(alpha: 0.85))),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: page.accent, borderRadius: BorderRadius.circular(20)),
                    child: Text('${page.badgeEmoji}  ${page.badgeText}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(page.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 14),
          Text(page.description, style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
