import 'package:flutter/material.dart';
import '../yemma_theme.dart';

/// Suivi de grossesse semaine par semaine (style maquette corail) :
/// sélecteur de semaines, poids/taille du bébé, trimestre, progression,
/// et cartes Bébé / Maman / Conseil utile.
class PregnancyTracker extends StatefulWidget {
  final int currentWeek;
  final DateTime? dueDate;
  const PregnancyTracker({super.key, required this.currentWeek, this.dueDate});

  @override
  State<PregnancyTracker> createState() => _PregnancyTrackerState();
}

class _WeekInfo {
  final double weightG;
  final double lengthCm;
  const _WeekInfo(this.weightG, this.lengthCm);
}

class _PregnancyTrackerState extends State<PregnancyTracker> {
  static const _coral = Color(0xFFF4716A);
  static const _darkCard = Color(0xFFC76060);
  static const _darkerCard = Color(0xFF884242);

  late int _selected;
  late final ScrollController _weeksController;

  // Poids (g) et taille (cm) moyens du fœtus par semaine.
  static const Map<int, _WeekInfo> _data = {
    4: _WeekInfo(0.4, 0.4), 5: _WeekInfo(0.5, 0.6), 6: _WeekInfo(0.7, 0.9),
    7: _WeekInfo(0.9, 1.2), 8: _WeekInfo(1, 1.6), 9: _WeekInfo(2, 2.3),
    10: _WeekInfo(4, 3.1), 11: _WeekInfo(7, 4.1), 12: _WeekInfo(14, 5.4),
    13: _WeekInfo(23, 7.4), 14: _WeekInfo(43, 8.7), 15: _WeekInfo(70, 10.1),
    16: _WeekInfo(100, 11.6), 17: _WeekInfo(140, 13), 18: _WeekInfo(190, 14.2),
    19: _WeekInfo(240, 15.3), 20: _WeekInfo(300, 16.4), 21: _WeekInfo(360, 26.7),
    22: _WeekInfo(430, 27.8), 23: _WeekInfo(500, 28.9), 24: _WeekInfo(600, 30),
    25: _WeekInfo(660, 34.6), 26: _WeekInfo(760, 35.6), 27: _WeekInfo(875, 36.6),
    28: _WeekInfo(1005, 37.6), 29: _WeekInfo(1150, 38.6), 30: _WeekInfo(1320, 39.9),
    31: _WeekInfo(1500, 41.1), 32: _WeekInfo(1700, 42.4), 33: _WeekInfo(1920, 43.7),
    34: _WeekInfo(2150, 45), 35: _WeekInfo(2380, 46.2), 36: _WeekInfo(2620, 47.4),
    37: _WeekInfo(2860, 48.6), 38: _WeekInfo(3080, 49.8), 39: _WeekInfo(3290, 50.7),
    40: _WeekInfo(3460, 51.2),
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.currentWeek.clamp(4, 40);
    // Centre le sélecteur sur la semaine actuelle.
    _weeksController = ScrollController(initialScrollOffset: (_selected - 4) * 56.0 - 120);
  }

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  String _babyText(int w) {
    if (w <= 7) return 'L\'embryon se forme : le cœur commence à battre et les premiers organes apparaissent.';
    if (w <= 11) return 'L\'embryon ressemble de plus en plus à un petit humain. La tête représente presque la moitié du corps et le visage se dessine.';
    if (w <= 15) return 'C\'est maintenant un fœtus ! Les ongles poussent, il bouge les bras et les jambes et peut sucer son pouce.';
    if (w <= 19) return 'Ses oreilles se développent : il commence à entendre votre voix. Ses mouvements deviennent perceptibles.';
    if (w <= 23) return 'Il est très actif ! Ses empreintes digitales sont formées et il alterne des phases de sommeil et d\'éveil.';
    if (w <= 27) return 'Ses poumons se développent et il ouvre les yeux. Il réagit à la lumière et aux sons.';
    if (w <= 31) return 'Il grossit vite et stocke de la graisse. Son cerveau se développe intensément.';
    if (w <= 35) return 'Il se met souvent tête en bas pour préparer la naissance. Il a moins de place pour bouger.';
    return 'Bébé est prêt à naître ! Ses poumons sont matures et il descend dans le bassin.';
  }

  String _momText(int w) {
    if (w <= 7) return 'Les premiers signes apparaissent : fatigue, nausées, seins sensibles. Prenez de l\'acide folique et reposez-vous.';
    if (w <= 11) return 'Votre ventre ne se voit pas encore, mais vous pourriez avoir du mal à fermer votre jean préféré. Les nausées peuvent continuer.';
    if (w <= 15) return 'Les nausées diminuent souvent et l\'énergie revient. C\'est le bon moment pour la première échographie.';
    if (w <= 19) return 'Votre ventre s\'arrondit. Vous sentirez bientôt (ou déjà) les premiers mouvements du bébé.';
    if (w <= 23) return 'Vous ressentez clairement ses mouvements. Attention au dos : adoptez de bonnes postures.';
    if (w <= 27) return 'Des douleurs lombaires et des jambes lourdes peuvent apparaître. Buvez beaucoup d\'eau et surélevez vos jambes.';
    if (w <= 31) return 'Le ventre pèse : dormez sur le côté gauche avec un coussin. Surveillez votre tension.';
    if (w <= 35) return 'Les contractions d\'entraînement (Braxton Hicks) peuvent survenir. Préparez votre valise de maternité.';
    return 'C\'est bientôt le grand jour ! Restez attentive aux contractions régulières et à la perte des eaux.';
  }

  String _adviceText(int w) {
    if (w <= 13) return 'Évitez tabac et alcool, prenez vos vitamines et planifiez votre suivi prénatal chez votre médecin ou sage-femme.';
    if (w <= 27) return 'Marchez régulièrement, mangez équilibré (fer, calcium) et faites vos échographies de suivi aux dates prévues.';
    return 'Reposez-vous, préparez l\'arrivée de bébé et n\'hésitez pas à appeler votre médecin au moindre doute.';
  }

  @override
  Widget build(BuildContext context) {
    final info = _data[_selected] ?? const _WeekInfo(0, 0);
    final trimester = _selected <= 13 ? '1er trimestre' : (_selected <= 27 ? '2e trimestre' : '3e trimestre');
    final daysLeft = (40 - _selected) * 7;
    final due = widget.dueDate;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          // ---- Zone haute dégradée : stats bébé + sélecteur de semaines ----
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFAB91), Color(0x5EFFDFD2)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBadge('${info.weightG < 1000 ? info.weightG.toStringAsFixed(info.weightG < 10 ? 1 : 0) : (info.weightG / 1000).toStringAsFixed(1)}${info.weightG < 1000 ? ' g' : ' kg'}', 'poids'),
                    SizedBox(
                      width: 110,
                      height: 120,
                      // Image au fond transparent : le foetus se pose
                      // directement sur le degrade corail, sans rectangle.
                      child: Image.asset(
                        'assets/images/yemma/foetus.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Image.asset(
                          'assets/images/foetus.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.child_care, color: Colors.white, size: 64),
                        ),
                      ),
                    ),
                    _statBadge('${info.lengthCm.toStringAsFixed(1)} cm', 'taille'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    controller: _weeksController,
                    scrollDirection: Axis.horizontal,
                    itemCount: 37, // semaines 4 → 40
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final week = i + 4;
                      final isSelected = week == _selected;
                      final isCurrent = week == widget.currentWeek;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = week),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? _coral : Colors.transparent,
                                border: Border.all(color: _coral, width: 1.4),
                              ),
                              child: Center(
                                child: Text('$week', style: TextStyle(color: isSelected ? Colors.white : _coral, fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            if (isCurrent)
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text('actuelle', style: TextStyle(color: _coral, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ---- Bandeau : semaine + trimestre + progression + accouchement ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _darkCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Semaine $_selected', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(trimester, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _selected / 40,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      due != null ? 'Accouchement prévu : ${due.day}/${due.month}/${due.year}' : 'Semaine $_selected / 40',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text('~ $daysLeft jours restants', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // ---- Carte Bébé ----
          _infoCard('👶 Bébé', _babyText(_selected), _darkerCard),
          // ---- Carte Maman ----
          _infoCard('🤰 Maman', _momText(_selected), _darkCard),
          // ---- Conseil utile ----
          _infoCard('💡 Conseil utile', _adviceText(_selected), _darkerCard),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(16),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}
