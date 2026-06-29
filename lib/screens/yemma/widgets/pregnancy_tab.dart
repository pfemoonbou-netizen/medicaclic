import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/yemma_provider.dart';
import '../yemma_theme.dart';

class PregnancyTab extends StatelessWidget {
  const PregnancyTab({super.key});

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
              const Text('Aucune donnée de grossesse enregistrée pour le moment.', textAlign: TextAlign.center, style: TextStyle(color: YemmaColors.textSecondary, fontSize: 14)),
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

    final progress = yemma.pregnancyWeek / 40;
    final date = yemma.nextAppointmentDate;
    final time = date == null ? '' : '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Semaine de grossesse', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: YemmaColors.pink, width: 3)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${yemma.pregnancyWeek}', style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                        const Text('sem.', style: TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(yemma.pregnancyTrimester, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Votre bébé mesure ~${yemma.babySizeCm.toInt()}cm et pèse ${yemma.babyWeightKgEstimate}kg. Il peut entendre votre voix.',
                          style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: YemmaColors.border, valueColor: const AlwaysStoppedAnimation(YemmaColors.pink)),
              ),
              const SizedBox(height: 6),
              Text('${yemma.pregnancyWeek} / 40 semaines', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prochain RDV médical', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(radius: 24, backgroundColor: YemmaColors.background, child: Icon(Icons.person, color: YemmaColors.pink)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(yemma.nextAppointmentTitle, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(yemma.nextAppointmentDoctor, style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
                        if (date != null)
                          Text('${_weekday(date.weekday)} ${date.day}/${date.month}/${date.year} à $time', style: const TextStyle(color: YemmaColors.pink, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_today_outlined, color: YemmaColors.pink, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
        ),
      ],
    );
  }

  String _weekday(int day) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[day - 1];
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
      setState(() => _error = 'Veuillez indiquer une semaine de grossesse valide (1-42).');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<YemmaProvider>().createPregnancyInfo(
            week: week,
            trimester: _trimester,
            babySizeCm: double.tryParse(_babySize.text.trim()),
            babyWeightKg: double.tryParse(_babyWeight.text.trim()),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: YemmaColors.textFaint),
        filled: true,
        fillColor: YemmaColors.background,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trimesters.map((t) {
                final active = t == _trimester;
                return GestureDetector(
                  onTap: () => setState(() => _trimester = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: active ? YemmaColors.pink.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? YemmaColors.pink : YemmaColors.border)),
                    child: Text(t, style: TextStyle(color: active ? YemmaColors.pink : YemmaColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(controller: _babySize, keyboardType: TextInputType.number, style: const TextStyle(color: YemmaColors.textPrimary), decoration: _decoration('Taille estimée du bébé (cm) — optionnel')),
            const SizedBox(height: 14),
            TextField(controller: _babyWeight, keyboardType: TextInputType.number, style: const TextStyle(color: YemmaColors.textPrimary), decoration: _decoration('Poids estimé du bébé (kg) — optionnel')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
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
