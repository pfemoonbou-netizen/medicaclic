import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../../providers/yemma_provider.dart';
import '../yemma_theme.dart';

class PregnancyTab extends StatefulWidget {
  const PregnancyTab({super.key});
  @override
  State<PregnancyTab> createState() => _PregnancyTabState();
}

class _PregnancyTabState extends State<PregnancyTab> {
  int _selectedWeek = 4;

  static const _weekData = <int, Map<String, dynamic>>{
    4: {'weight': '0.4 g', 'size': '0.4 cm', 'baby': "L'embryon se forme : le cœur commence à battre et les premiers organes apparaissent.", 'mom': 'Les premiers signes apparaissent : fatigue, nausées, seins sensibles. Prenez de l\'acide folique et reposez-vous.', 'tip': 'Évitez tabac et alcool, prenez vos vitamines et planifiez votre suivi prénatal chez votre médecin ou sage-femme.'},
    5: {'weight': '1 g', 'size': '0.5 cm', 'baby': "Le tube neural se ferme. Le cœur bat régulièrement.", 'mom': 'Nausées matinales possibles. Mangez léger et souvent.', 'tip': 'Commencez l\'acide folique si ce n\'est pas fait.'},
    6: {'weight': '2 g', 'size': '0.8 cm', 'baby': "Les bourgeons des bras et jambes apparaissent.", 'mom': 'Fatigue accrue, seins sensibles. C\'est normal.', 'tip': 'Buvez beaucoup d\'eau et reposez-vous.'},
    7: {'weight': '4 g', 'size': '1.3 cm', 'baby': "Le visage se dessine. Les doigts commencent à se former.", 'mom': 'Nausées et envies alimentaires fréquentes.', 'tip': 'Prenez rendez-vous pour votre première échographie.'},
    8: {'weight': '10 g', 'size': '1.6 cm', 'baby': "Tous les organes majeurs sont en place. Le bébé bouge.", 'mom': 'Votre utérus grossit. Possible constipation.', 'tip': 'Mangez des fibres et faites de l\'exercice doux.'},
    9: {'weight': '23 g', 'size': '2.3 cm', 'baby': "Les os commencent à se solidifier. Le bébé a des paupières.", 'mom': 'Changements d\'humeur possibles. Soyez patiente.', 'tip': 'Parlez à votre médecin de vos symptômes.'},
    10: {'weight': '35 g', 'size': '3.1 cm', 'baby': "Fin de la période embryonnaire. Le bébé est maintenant un fœtus.", 'mom': 'Les nausées commencent à diminuer pour certaines.', 'tip': 'Première échographie recommandée entre 11 et 13 semaines.'},
  };

  Map<String, dynamic> get _currentData => _weekData[_selectedWeek] ?? _weekData[4]!;
  String get _trimester {
    if (_selectedWeek <= 13) return '1er trimestre';
    if (_selectedWeek <= 26) return '2e trimestre';
    return '3e trimestre';
  }
  int get _daysRemaining => (40 - _selectedWeek) * 7;

  @override
  void initState() {
    super.initState();
    final yemma = context.read<YemmaProvider>();
    if (yemma.hasPregnancyInfo && yemma.pregnancyWeek >= 4 && yemma.pregnancyWeek <= 10) {
      _selectedWeek = yemma.pregnancyWeek;
    }
  }

  @override
  Widget build(BuildContext context) {
    final yemma = context.watch<YemmaProvider>();

    if (!yemma.hasPregnancyInfo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pregnant_woman, color: YemmaColors.textFaint, size: 40),
              const SizedBox(height: 12),
              const Text('Aucune donnée de grossesse enregistrée.', textAlign: TextAlign.center, style: TextStyle(color: YemmaColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showCreatePregnancyInfoSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Renseigner ma grossesse'),
                style: ElevatedButton.styleFrom(backgroundColor: YemmaColors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              ),
            ],
          ),
        ),
      );
    }

    final data = _currentData;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildFetusHeader(data),
        _buildWeekSelector(),
        _buildWeekInfo(),
        _buildInfoCard('👶', 'Bébé', data['baby'] as String, const Color(0xFFD4837A)),
        _buildInfoCard('🤰', 'Maman', data['mom'] as String, const Color(0xFFD4837A)),
        _buildInfoCard('💡', 'Conseil utile', data['tip'] as String, const Color(0xFFD4837A)),
        const SizedBox(height: 24),
        _buildAppointmentCard(yemma),
        const SizedBox(height: 16),
        _buildSymptomsCard(yemma),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFetusHeader(Map<String, dynamic> data) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8A49C), Color(0xFFF5C4BC), Color(0xFFFADDD6)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            top: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(data['weight'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const Text('poids', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(data['size'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const Text('taille', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          CustomPaint(size: const Size(120, 120), painter: _FetusPainter(_selectedWeek)),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      color: const Color(0xFFFADDD6),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final week = i + 4;
          final selected = week == _selectedWeek;
          return GestureDetector(
            onTap: () => setState(() => _selectedWeek = week),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFD4837A) : Colors.transparent,
                border: Border.all(color: const Color(0xFFD4837A), width: selected ? 0 : 1.5),
              ),
              alignment: Alignment.center,
              child: Text('$week', style: TextStyle(color: selected ? Colors.white : const Color(0xFFD4837A), fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWeekInfo() {
    final progress = _selectedWeek / 40;
    return Container(
      padding: const EdgeInsets.all(16),
      color: YemmaColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semaine $_selectedWeek', style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(_trimester, style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: YemmaColors.border, valueColor: const AlwaysStoppedAnimation(Color(0xFFD4837A))),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semaine $_selectedWeek / 40', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
              Text('~ $_daysRemaining jours restants', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String emoji, String title, String content, Color accentColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(YemmaProvider yemma) {
    final date = yemma.nextAppointmentDate;
    if (date == null) return const SizedBox.shrink();
    final time = '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prochain RDV médical', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            const CircleAvatar(radius: 24, backgroundColor: YemmaColors.background, child: Icon(Icons.person, color: YemmaColors.pink)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(yemma.nextAppointmentTitle, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(yemma.nextAppointmentDoctor, style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
              Text('${days[date.weekday - 1]} ${date.day}/${date.month}/${date.year} à $time', style: const TextStyle(color: YemmaColors.pink, fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_today_outlined, color: YemmaColors.pink, size: 18),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard(YemmaProvider yemma) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Symptômes du jour', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: yemma.allSymptoms.map((s) {
              final active = yemma.selectedSymptoms.contains(s);
              return GestureDetector(
                onTap: () => yemma.toggleSymptom(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? YemmaColors.pink.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? YemmaColors.pink : YemmaColors.border),
                  ),
                  child: Text(s, style: TextStyle(color: active ? YemmaColors.pink : YemmaColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCreatePregnancyInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => const _PregnancyInfoForm(),
    );
  }
}

class _FetusPainter extends CustomPainter {
  final int week;
  _FetusPainter(this.week);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = 0.6 + (week - 4) * 0.06;

    final skinPaint = Paint()..color = const Color(0xFFF5C2A8);
    final darkPaint = Paint()..color = const Color(0xFFE8A88C);
    final outlinePaint = Paint()..color = const Color(0xFFD4917A)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Body (curled shape)
    final bodyPath = Path();
    bodyPath.moveTo(0, -30);
    bodyPath.cubicTo(25, -28, 30, -10, 28, 10);
    bodyPath.cubicTo(26, 25, 15, 35, 0, 38);
    bodyPath.cubicTo(-15, 35, -26, 25, -28, 10);
    bodyPath.cubicTo(-30, -10, -25, -28, 0, -30);
    canvas.drawPath(bodyPath, skinPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Head
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -22), width: 32, height: 28), skinPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -22), width: 32, height: 28), outlinePaint);

    // Arm
    final armPath = Path();
    armPath.moveTo(14, -5);
    armPath.cubicTo(22, 0, 20, 12, 14, 16);
    canvas.drawPath(armPath, outlinePaint);

    // Leg
    final legPath = Path();
    legPath.moveTo(-5, 28);
    legPath.cubicTo(-12, 34, -18, 30, -16, 22);
    canvas.drawPath(legPath, outlinePaint);

    // Ear
    canvas.drawCircle(const Offset(-14, -24), 4, darkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FetusPainter old) => old.week != week;
}

class _PregnancyInfoForm extends StatefulWidget {
  const _PregnancyInfoForm();
  @override
  State<_PregnancyInfoForm> createState() => _PregnancyInfoFormState();
}

class _PregnancyInfoFormState extends State<_PregnancyInfoForm> {
  final _week = TextEditingController();
  final _babySize = TextEditingController();
  final _babyWeight = TextEditingController();
  String _trimester = '1er trimestre';
  bool _submitting = false;
  String? _error;

  static const _trimesters = ['1er trimestre', '2e trimestre', '3e trimestre'];

  @override
  void dispose() {
    _week.dispose();
    _babySize.dispose();
    _babyWeight.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final week = int.tryParse(_week.text.trim());
    if (week == null || week < 1 || week > 42) {
      setState(() => _error = 'Veuillez indiquer une semaine valide (1-42).');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<YemmaProvider>().createPregnancyInfo(
        week: week, trimester: _trimester,
        babySizeCm: double.tryParse(_babySize.text.trim()),
        babyWeightKg: double.tryParse(_babyWeight.text.trim()),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _submitting = false; _error = e.toString(); });
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: YemmaColors.textFaint),
    filled: true, fillColor: YemmaColors.background,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YemmaColors.border)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Renseigner ma grossesse', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _week, keyboardType: TextInputType.number, style: const TextStyle(color: YemmaColors.textPrimary), decoration: _decoration('Semaine de grossesse (1-42)')),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: _trimesters.map((t) {
              final active = t == _trimester;
              return GestureDetector(
                onTap: () => setState(() => _trimester = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: active ? YemmaColors.pink.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? YemmaColors.pink : YemmaColors.border)),
                  child: Text(t, style: TextStyle(color: active ? YemmaColors.pink : YemmaColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            TextField(controller: _babySize, keyboardType: TextInputType.number, style: const TextStyle(color: YemmaColors.textPrimary), decoration: _decoration('Taille bébé (cm) — optionnel')),
            const SizedBox(height: 14),
            TextField(controller: _babyWeight, keyboardType: TextInputType.number, style: const TextStyle(color: YemmaColors.textPrimary), decoration: _decoration('Poids bébé (kg) — optionnel')),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: YemmaColors.pink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
