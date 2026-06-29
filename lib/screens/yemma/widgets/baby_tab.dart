import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/yemma_provider.dart';
import '../yemma_theme.dart';
import 'pain_tab.dart' show formatFrDate;

class BabyTab extends StatelessWidget {
  const BabyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final yemma = context.watch<YemmaProvider>();

    if (!yemma.hasBabyProfile) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.child_care, color: YemmaColors.textFaint, size: 40),
              const SizedBox(height: 12),
              const Text('Aucun profil bébé enregistré pour le moment.', textAlign: TextAlign.center, style: TextStyle(color: YemmaColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showCreateBabyProfileSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer le profil de mon bébé'),
                style: ElevatedButton.styleFrom(backgroundColor: YemmaColors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
          child: Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: YemmaColors.background, child: Icon(Icons.child_care, color: YemmaColors.pink, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(yemma.babyName, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${yemma.babyAgeLabel}\nNée le ${formatFrDate(yemma.babyBirthDate)}', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text('♀ ${yemma.babyGender}', style: const TextStyle(color: YemmaColors.pink, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: YemmaColors.textSecondary, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: YemmaColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: YemmaColors.border)),
          child: Column(
            children: [
              Row(
                children: [
                  _metric(Icons.straighten, '${yemma.babyWeightKg}', 'kg', 'Poids', '+${yemma.babyWeightDeltaKg} ce mois'),
                  _metric(Icons.height, '${yemma.babyHeightCm.toInt()}', 'cm', 'Taille', '+${yemma.babyHeightDeltaCm.toInt()} cm'),
                  _metric(Icons.face_outlined, yemma.babyHeadCircumference, '', 'P. Crânien', 'Normal'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18, color: YemmaColors.pink),
                  label: const Text('Ajouter une mesure', style: TextStyle(color: YemmaColors.pink)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: YemmaColors.border, style: BorderStyle.solid),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Carnet de vaccinations', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('${yemma.vaccinesDone}/${yemma.vaccines.length} faits', style: const TextStyle(color: YemmaColors.pink, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...yemma.vaccines.map((v) {
                final barColor = v.done ? YemmaColors.green : (v.dueSoon ? YemmaColors.orange : YemmaColors.blue);
                final statusIcon = v.done ? Icons.check_circle : (v.dueSoon ? Icons.warning_amber_rounded : Icons.circle_outlined);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: YemmaColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(left: BorderSide(color: barColor, width: 4)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: barColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${v.ageLabel} — ${formatFrDate(v.date)}', style: const TextStyle(color: YemmaColors.textFaint, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (!v.done)
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(side: BorderSide(color: barColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          child: Text('Planifier', style: TextStyle(color: barColor, fontSize: 12)),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String value, String unit, String label, String delta) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: YemmaColors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: YemmaColors.pink, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: YemmaColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          if (unit.isNotEmpty) Text(unit, style: const TextStyle(color: YemmaColors.textFaint, fontSize: 10)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: YemmaColors.textSecondary, fontSize: 11)),
          Text(delta, style: const TextStyle(color: YemmaColors.green, fontSize: 10)),
        ],
      ),
    );
  }

  void _showCreateBabyProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => const _BabyProfileForm(),
    );
  }
}

class _BabyProfileForm extends StatefulWidget {
  const _BabyProfileForm();
  @override
  State<_BabyProfileForm> createState() => _BabyProfileFormState();
}

class _BabyProfileFormState extends State<_BabyProfileForm> {
  final _name = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Fille';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _birthDate == null) {
      setState(() => _error = 'Veuillez renseigner le nom et la date de naissance.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<YemmaProvider>().createBabyProfile(name: _name.text.trim(), birthDate: _birthDate!, gender: _gender);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

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
            const Text('Créer le profil de mon bébé', style: TextStyle(color: YemmaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              style: const TextStyle(color: YemmaColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Prénom du bébé',
                hintStyle: const TextStyle(color: YemmaColors.textFaint),
                filled: true,
                fillColor: YemmaColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YemmaColors.border)),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: YemmaColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: YemmaColors.border)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: YemmaColors.textFaint, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _birthDate == null ? 'Date de naissance' : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                      style: TextStyle(color: _birthDate == null ? YemmaColors.textFaint : YemmaColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = 'Fille'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _gender == 'Fille' ? YemmaColors.pink.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gender == 'Fille' ? YemmaColors.pink : YemmaColors.border)),
                      child: Text('♀ Fille', style: TextStyle(color: _gender == 'Fille' ? YemmaColors.pink : YemmaColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = 'Garçon'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _gender == 'Garçon' ? YemmaColors.blue.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gender == 'Garçon' ? YemmaColors.blue : YemmaColors.border)),
                      child: Text('♂ Garçon', style: TextStyle(color: _gender == 'Garçon' ? YemmaColors.blue : YemmaColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
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
