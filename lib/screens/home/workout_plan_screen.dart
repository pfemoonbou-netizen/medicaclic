import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _WorkoutColors {
  static const bg = Color(0xFF0D0F14);
  static const panel = Color(0xFF161922);
  static const panel2 = Color(0xFF1E2230);
  static const line = Color(0xFF2A2F3F);
  static const text = Color(0xFFEDEFF5);
  static const muted = Color(0xFF8B92A8);
  static const accent = Color(0xFFFF6B35);
  static const push = Color(0xFF4E9BFF);
  static const pull = Color(0xFF7C5CFF);
  static const legs = Color(0xFF2ED9A8);
}

class _Exercise {
  String name;
  String target;
  String weight;
  bool done;
  _Exercise({required this.name, required this.target, this.weight = '', this.done = false});

  Map<String, dynamic> toJson() => {'name': name, 'target': target, 'weight': weight, 'done': done};
  factory _Exercise.fromJson(Map<String, dynamic> j) => _Exercise(
        name: j['name'] as String,
        target: j['target'] as String? ?? '',
        weight: j['weight'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

class _WorkoutDay {
  final String id;
  final String label;
  final String focus;
  final Color color;
  final String cardio;
  List<_Exercise> exercises;
  _WorkoutDay({required this.id, required this.label, required this.focus, required this.color, required this.cardio, required this.exercises});
}

const _storageKey = 'workout_plan_v1';

/// Suivi de séances de musculation (Push/Pull/Legs), avec poids et coches
/// sauvegardés sur l'appareil.
class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  bool _loading = true;
  final Set<String> _openDays = {};
  final Map<String, TextEditingController> _weightControllers = {};

  final List<_WorkoutDay> _days = [
    _WorkoutDay(
      id: 'lundi',
      label: 'Lundi',
      focus: 'Pectoraux, épaules, triceps (Push)',
      color: _WorkoutColors.push,
      cardio: '20 minutes de marche inclinée après la séance.',
      exercises: [
        _Exercise(name: 'Développé couché', target: '4 × 8-10'),
        _Exercise(name: 'Développé incliné haltères', target: '3 × 10-12'),
        _Exercise(name: 'Écartés à la poulie ou aux haltères', target: '3 × 12-15'),
        _Exercise(name: 'Développé militaire', target: '3 × 8-10'),
        _Exercise(name: 'Élévations latérales', target: '3 × 12-15'),
        _Exercise(name: 'Extensions triceps à la poulie', target: '3 × 10-12'),
        _Exercise(name: 'Dips (ou machine)', target: '3 × 8-12'),
      ],
    ),
    _WorkoutDay(
      id: 'mercredi',
      label: 'Mercredi',
      focus: 'Dos, biceps (Pull)',
      color: _WorkoutColors.pull,
      cardio: '20 minutes de vélo ou rameur après la séance.',
      exercises: [
        _Exercise(name: 'Tractions (ou tirage vertical)', target: '4 × 8-10'),
        _Exercise(name: 'Rowing barre', target: '3 × 8-10'),
        _Exercise(name: 'Tirage horizontal à la poulie', target: '3 × 10-12'),
        _Exercise(name: 'Tirage vertical prise serrée', target: '3 × 10-12'),
        _Exercise(name: 'Oiseau (élévations arrière)', target: '3 × 12-15'),
        _Exercise(name: 'Curl biceps haltères', target: '3 × 10-12'),
        _Exercise(name: 'Curl marteau', target: '3 × 10-12'),
      ],
    ),
    _WorkoutDay(
      id: 'vendredi',
      label: 'Vendredi',
      focus: 'Jambes (Legs)',
      color: _WorkoutColors.legs,
      cardio: '20 minutes de marche inclinée ou vélo après la séance.',
      exercises: [
        _Exercise(name: 'Squat', target: '4 × 8-10'),
        _Exercise(name: 'Presse à cuisses', target: '3 × 10-12'),
        _Exercise(name: 'Fentes haltères', target: '3 × 10-12'),
        _Exercise(name: 'Leg extension', target: '3 × 12-15'),
        _Exercise(name: 'Leg curl (ischios)', target: '3 × 12-15'),
        _Exercise(name: 'Mollets debout à la machine', target: '4 × 12-15'),
        _Exercise(name: 'Gainage (planche)', target: '3 × 45-60 sec'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _openDays.add(_days.first.id);
    _load();
  }

  @override
  void dispose() {
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _weightController(_WorkoutDay day, int index, String initial) {
    final key = '${day.id}_$index';
    return _weightControllers.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  void _clearWeightControllers() {
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    _weightControllers.clear();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        for (final day in _days) {
          final list = saved[day.id] as List?;
          if (list != null) {
            day.exercises = list.map((e) => _Exercise.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final day in _days) day.id: day.exercises.map((e) => e.toJson()).toList()};
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  int get _totalExercises => _days.fold(0, (sum, d) => sum + d.exercises.length);
  int get _totalDone => _days.fold(0, (sum, d) => sum + d.exercises.where((e) => e.done).length);

  Future<void> _resetWeek() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle semaine ?'),
        content: const Text('Décocher tous les exercices pour repartir sur une nouvelle semaine ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      for (final day in _days) {
        for (final ex in day.exercises) {
          ex.done = false;
        }
      }
    });
    _save();
  }

  Future<void> _addExercise(_WorkoutDay day) async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _WorkoutColors.panel,
        title: const Text('Ajouter un exercice', style: TextStyle(color: _WorkoutColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: _WorkoutColors.text),
              decoration: const InputDecoration(labelText: "Nom de l'exercice", labelStyle: TextStyle(color: _WorkoutColors.muted)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              style: const TextStyle(color: _WorkoutColors.text),
              decoration: const InputDecoration(labelText: 'Objectif (ex: 3 x 10-12)', labelStyle: TextStyle(color: _WorkoutColors.muted)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (added != true || nameController.text.trim().isEmpty) return;
    _clearWeightControllers();
    setState(() {
      day.exercises.add(_Exercise(name: nameController.text.trim(), target: targetController.text.trim()));
      _openDays.add(day.id);
    });
    _save();
  }

  void _deleteExercise(_WorkoutDay day, int index) {
    _clearWeightControllers();
    setState(() => day.exercises.removeAt(index));
    _save();
  }

  void _toggleDone(_WorkoutDay day, int index) {
    setState(() => day.exercises[index].done = !day.exercises[index].done);
    _save();
  }

  void _updateWeight(_WorkoutDay day, int index, String value) {
    day.exercises[index].weight = value;
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WorkoutColors.bg,
      appBar: AppBar(
        backgroundColor: _WorkoutColors.bg,
        elevation: 0,
        foregroundColor: _WorkoutColors.text,
        title: const Text('🏋️ Programme Musculation', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _WorkoutColors.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
              children: [
                Text('$_totalDone / $_totalExercises exercices cochés cette semaine', style: const TextStyle(color: _WorkoutColors.muted, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _resetWeek,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _WorkoutColors.line), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('🔄 Reset coches (nouvelle semaine)', style: TextStyle(color: _WorkoutColors.muted, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 16),
                ..._days.map(_dayCard),
              ],
            ),
    );
  }

  Widget _dayCard(_WorkoutDay day) {
    final isOpen = _openDays.contains(day.id);
    final nEx = day.exercises.length;
    final nDone = day.exercises.where((e) => e.done).length;
    final pct = nEx == 0 ? 0.0 : nDone / nEx;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: _WorkoutColors.panel, border: Border.all(color: _WorkoutColors.line), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isOpen ? _openDays.remove(day.id) : _openDays.add(day.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(width: 8, height: 28, decoration: BoxDecoration(color: day.color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.label, style: const TextStyle(color: _WorkoutColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(day.focus, style: const TextStyle(color: _WorkoutColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('$nDone/$nEx', style: const TextStyle(color: _WorkoutColors.muted, fontSize: 11)),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: _WorkoutColors.muted),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const Divider(height: 1, color: _WorkoutColors.line),
            if (nEx == 0)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun exercice ajouté — appuie sur "+ Ajouter un exercice"', style: TextStyle(color: _WorkoutColors.muted, fontStyle: FontStyle.italic, fontSize: 12)),
              )
            else
              ...day.exercises.asMap().entries.map((entry) => _exerciseRow(day, entry.key, entry.value)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _addExercise(day),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _WorkoutColors.line, style: BorderStyle.solid),
                    backgroundColor: _WorkoutColors.panel2,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('+ Ajouter un exercice', style: TextStyle(color: _WorkoutColors.muted, fontSize: 12)),
                ),
              ),
            ),
            if (day.cardio.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: _WorkoutColors.panel2, borderRadius: BorderRadius.circular(10)),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(color: _WorkoutColors.muted, fontSize: 12.5),
                    children: [
                      const TextSpan(text: '🏃 '),
                      const TextSpan(text: 'Cardio : ', style: TextStyle(color: _WorkoutColors.text, fontWeight: FontWeight.bold)),
                      TextSpan(text: day.cardio),
                    ],
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              height: 4,
              decoration: BoxDecoration(color: _WorkoutColors.line, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(decoration: BoxDecoration(color: day.color, borderRadius: BorderRadius.circular(2))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _exerciseRow(_WorkoutDay day, int index, _Exercise ex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _WorkoutColors.line))),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name, style: const TextStyle(color: _WorkoutColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(ex.target, style: const TextStyle(color: _WorkoutColors.muted, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _weightController(day, index, ex.weight),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _WorkoutColors.text, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: '--',
                hintStyle: const TextStyle(color: _WorkoutColors.muted),
                filled: true,
                fillColor: _WorkoutColors.panel2,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _WorkoutColors.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _WorkoutColors.accent)),
              ),
              onChanged: (v) => _updateWeight(day, index, v),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _toggleDone(day, index),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: ex.done ? _WorkoutColors.accent : _WorkoutColors.panel2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ex.done ? _WorkoutColors.accent : _WorkoutColors.line),
              ),
              child: ex.done ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteExercise(day, index),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, color: _WorkoutColors.muted, size: 16)),
          ),
        ],
      ),
    );
  }
}
