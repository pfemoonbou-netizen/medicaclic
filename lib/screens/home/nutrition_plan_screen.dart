import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';

class _FoodItem {
  final String name;
  final String weight;
  const _FoodItem(this.name, this.weight);
}

class _Meal {
  final String id;
  final String time;
  final String? option;
  final List<_FoodItem> items;
  final Map<String, int> macros;
  final int calories;
  final List<String> notes;
  bool done;
  _Meal({
    required this.id,
    required this.time,
    this.option,
    required this.items,
    required this.macros,
    required this.calories,
    this.notes = const [],
    this.done = false,
  });
}

const _storageKey = 'nutrition_plan_v1';

/// Suivi du programme nutritionnel (repas, macros, calories), coches
/// sauvegardees sur l'appareil.
class NutritionPlanScreen extends StatefulWidget {
  const NutritionPlanScreen({super.key});

  @override
  State<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  bool _loading = true;
  final Set<String> _openMeals = {};

  final List<_Meal> _meals = [
    _Meal(
      id: 'petit_dej',
      time: '07:00 - 08:00h',
      items: const [
        _FoodItem('Oeufs frits', '200 g'),
        _FoodItem('Kellogg\'s Corn flakes', '60 g'),
        _FoodItem('Lait (sans lactose)', '100 ml'),
      ],
      macros: const {'PRO': 36, 'LIP': 26, 'GLU': 43, 'FIBRE': 6},
      calories: 550,
      notes: const ['200 g = 4 oeufs'],
    ),
    _Meal(
      id: 'dej_option1',
      time: '12:00 - 13:00h',
      option: 'Option 1',
      items: const [
        _FoodItem('Pasta (blé complet)', '55 g'),
        _FoodItem('Tomate', '200 g'),
        _FoodItem('Blanc de poulet', '120 g'),
        _FoodItem('Courgette', '100 g'),
        _FoodItem('Persil', '20 g'),
        _FoodItem('Cheddar ou parmesan', '40 g'),
        _FoodItem('Une gousse d\'ail', ''),
        _FoodItem('1/4 càc poivre noir - 1/3 càc sel', ''),
        _FoodItem('1 càc zaatar + 1 càc basilic', ''),
      ],
      macros: const {'PRO': 42, 'LIP': 15, 'GLU': 50, 'FIBRE': 7},
      calories: 553,
    ),
    _Meal(
      id: 'dej_option2',
      time: '12:00 - 13:00h',
      option: 'Option 2',
      items: const [
        _FoodItem('Pomme de terre grillée', '300 g'),
        _FoodItem('Viande hachée', '100 g'),
        _FoodItem('Salade variée', '200 g'),
        _FoodItem('Càc huile d\'olive', ''),
      ],
      macros: const {'PRO': 29, 'LIP': 20, 'GLU': 66, 'FIBRE': 7},
      calories: 560,
      notes: const ['Le jour où tu prends ce repas, ajoute une dose de Whey avant de dormir'],
    ),
    _Meal(
      id: 'collation',
      time: '17:00h — Collation',
      items: const [
        _FoodItem('Pain Tortillas', '90 g'),
        _FoodItem('Blanc de poulet', '140 g'),
        _FoodItem('Càc huile d\'olive', ''),
        _FoodItem('Salade verte, oignon, tomate', ''),
        _FoodItem('Sauce à l\'ail*', ''),
      ],
      macros: const {'PRO': 41, 'LIP': 14, 'GLU': 54, 'FIBRE': 6},
      calories: 560,
      notes: const [
        '90 g = 1 tranche',
        '* Sauce à l\'ail : 1 pot fromage régime (35 g), une pincée de sel, 1/4 càc ail en poudre, persil',
      ],
    ),
    _Meal(
      id: 'diner_option1',
      time: '20:00 - 21:00h',
      option: 'Option 1',
      items: const [
        _FoodItem('Riz basmati cru', '45 g'),
        _FoodItem('Carottes râpées', '150 g'),
        _FoodItem('Courgettes râpées', '100 g'),
        _FoodItem('Blanc de poulet', '170 g'),
        _FoodItem('Crème légère', '50 g'),
      ],
      macros: const {'PRO': 43, 'LIP': 19, 'GLU': 56, 'FIBRE': 9},
      calories: 620,
      notes: const ['1/2 càc curcuma, 1/2 càc paprika, 1/3 càc poivron noir'],
    ),
    _Meal(
      id: 'diner_option2',
      time: 'Option 2 (Mtewwem)',
      items: const [
        _FoodItem('Pois chiche', '200 g'),
        _FoodItem('Blanc de poulet haché', '220 g'),
        _FoodItem('5 gousses d\'ail', ''),
        _FoodItem('Càs huile d\'olive', '15 ml'),
        _FoodItem('Pain complet', '30 g'),
      ],
      macros: const {'PRO': 36, 'LIP': 27, 'GLU': 43, 'FIBRE': 17},
      calories: 560,
      notes: const ['200 g = quantité correcte et suffisante'],
    ),
  ];

  static const _dailyTargets = {'Calories': 2284, 'Protéines': 162, 'Lipides': 68, 'Glucides': 210, 'Fibres': 25};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        for (final meal in _meals) {
          meal.done = saved[meal.id] as bool? ?? false;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final meal in _meals) meal.id: meal.done};
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  void _toggleDone(_Meal meal) {
    setState(() => meal.done = !meal.done);
    _save();
  }

  Future<void> _resetDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle journée ?'),
        content: const Text('Décocher tous les repas pour repartir sur une nouvelle journée ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      for (final meal in _meals) {
        meal.done = false;
      }
    });
    _save();
  }

  int get _caloriesEaten => _meals.where((m) => m.done).fold(0, (sum, m) => sum + m.calories);
  int get _mealsDone => _meals.where((m) => m.done).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('🍽️ Programme Nutrition', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                _dailySummaryCard(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _resetDay,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('🔄 Reset (nouvelle journée)', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 18),
                ..._meals.map(_mealCard),
              ],
            ),
    );
  }

  Widget _dailySummaryCard() {
    final pct = (_caloriesEaten / _dailyTargets['Calories']!).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 14)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_caloriesEaten / ${_dailyTargets['Calories']} Cal', style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('$_mealsDone/${_meals.length} repas pris aujourd\'hui', style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: const Color(0xFFEDF1F0), valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _macroChip('Protéines', _dailyTargets['Protéines']!),
              const SizedBox(width: 8),
              _macroChip('Lipides', _dailyTargets['Lipides']!),
              const SizedBox(width: 8),
              _macroChip('Glucides', _dailyTargets['Glucides']!),
              const SizedBox(width: 8),
              _macroChip('Fibres', _dailyTargets['Fibres']!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, int grams) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text('${grams}g', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _mealCard(_Meal meal) {
    final isOpen = _openMeals.contains(meal.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEDF1F0))),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isOpen ? _openMeals.remove(meal.id) : _openMeals.add(meal.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleDone(meal),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: meal.done ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: meal.done ? AppColors.primary : const Color(0xFFD1D5DB)),
                      ),
                      child: meal.done ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.option != null ? '${meal.time} · ${meal.option}' : meal.time, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${meal.items.length} aliments', style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                    child: Text('${meal.calories} Cal', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9C9C9C)),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFEDF1F0), height: 1),
                  const SizedBox(height: 12),
                  ...meal.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(color: AppColors.text, fontSize: 13))),
                            if (item.weight.isNotEmpty) Text(item.weight, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: meal.macros.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDF1F0))),
                        child: Text('${e.key} ${e.value}g', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                  if (meal.notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...meal.notes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('💡 $note', style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 11.5, fontStyle: FontStyle.italic)),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
