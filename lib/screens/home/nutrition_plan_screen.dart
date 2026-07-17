import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';

class _FoodItem {
  String name;
  int calories;
  _FoodItem({required this.name, required this.calories});

  Map<String, dynamic> toJson() => {'name': name, 'calories': calories};
  factory _FoodItem.fromJson(Map<String, dynamic> j) => _FoodItem(name: j['name'] as String, calories: (j['calories'] as num?)?.toInt() ?? 0);
}

class _Meal {
  String id;
  String label;
  List<_FoodItem> items;
  bool done;
  _Meal({required this.id, required this.label, required this.items, this.done = false});

  int get calories => items.fold(0, (sum, i) => sum + i.calories);

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'done': done, 'items': items.map((i) => i.toJson()).toList()};
  factory _Meal.fromJson(Map<String, dynamic> j) => _Meal(
        id: j['id'] as String,
        label: j['label'] as String,
        done: j['done'] as bool? ?? false,
        items: (j['items'] as List? ?? []).map((i) => _FoodItem.fromJson(i as Map<String, dynamic>)).toList(),
      );
}

const _storageKey = 'nutrition_plan_v2';

List<_Meal> _defaultMeals() => [
      _Meal(id: 'petit_dej', label: 'Petit-déjeuner — 07:00', items: [
        _FoodItem(name: 'Oeufs frits (200 g = 4 oeufs)', calories: 280),
        _FoodItem(name: 'Kellogg\'s Corn flakes (60 g)', calories: 220),
        _FoodItem(name: 'Lait sans lactose (100 ml)', calories: 50),
      ]),
      _Meal(id: 'dejeuner', label: 'Déjeuner — 12:00', items: [
        _FoodItem(name: 'Pasta blé complet (55 g) + tomate + poulet + courgette', calories: 553),
      ]),
      _Meal(id: 'collation', label: 'Collation — 17:00', items: [
        _FoodItem(name: 'Pain Tortillas (90 g) + poulet + salade + sauce à l\'ail', calories: 560),
      ]),
      _Meal(id: 'diner', label: 'Dîner — 20:00', items: [
        _FoodItem(name: 'Riz basmati + carottes + courgettes + poulet + crème légère', calories: 620),
      ]),
    ];

/// Programme nutritionnel entièrement personnalisable : l'utilisateur crée
/// ses propres repas et aliments ; seul le total de calories est calculé.
class NutritionPlanScreen extends StatefulWidget {
  const NutritionPlanScreen({super.key});

  @override
  State<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  bool _loading = true;
  final Set<String> _openMeals = {};
  List<_Meal> _meals = [];

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
        final saved = jsonDecode(raw) as List;
        _meals = saved.map((m) => _Meal.fromJson(m as Map<String, dynamic>)).toList();
      } catch (_) {
        _meals = _defaultMeals();
      }
    } else {
      _meals = _defaultMeals();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_meals.map((m) => m.toJson()).toList()));
  }

  int get _totalCalories => _meals.fold(0, (sum, m) => sum + m.calories);
  int get _caloriesEaten => _meals.where((m) => m.done).fold(0, (sum, m) => sum + m.calories);
  int get _mealsDone => _meals.where((m) => m.done).length;

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

  Future<void> _addMeal() async {
    final labelController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un repas'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(labelText: 'Nom du repas (ex: Brunch — 10:00)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (added != true || labelController.text.trim().isEmpty) return;
    final meal = _Meal(id: '${DateTime.now().millisecondsSinceEpoch}', label: labelController.text.trim(), items: []);
    setState(() {
      _meals.add(meal);
      _openMeals.add(meal.id);
    });
    _save();
  }

  Future<void> _deleteMeal(_Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer "${meal.label}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _meals.remove(meal);
      _openMeals.remove(meal.id);
    });
    _save();
  }

  Future<void> _addFood(_Meal meal) async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un aliment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nom de l'aliment")),
            const SizedBox(height: 12),
            TextField(controller: caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (added != true || nameController.text.trim().isEmpty) return;
    setState(() {
      meal.items.add(_FoodItem(name: nameController.text.trim(), calories: int.tryParse(caloriesController.text.trim()) ?? 0));
      _openMeals.add(meal.id);
    });
    _save();
  }

  void _deleteFood(_Meal meal, int index) {
    setState(() => meal.items.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('🍽️ Programme Nutrition', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [IconButton(onPressed: _addMeal, icon: const Icon(Icons.add_circle_outline))],
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addMeal,
                    icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
                    label: const Text('Ajouter un repas', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dailySummaryCard() {
    final pct = _totalCalories == 0 ? 0.0 : (_caloriesEaten / _totalCalories).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 14)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_caloriesEaten / $_totalCalories Cal', style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('$_mealsDone/${_meals.length} repas pris aujourd\'hui', style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: const Color(0xFFEDF1F0), valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
          ),
        ],
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
                        Text(meal.label, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${meal.items.length} aliment${meal.items.length > 1 ? 's' : ''}', style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                    child: Text('${meal.calories} Cal', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteMeal(meal),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, color: Color(0xFF9C9C9C), size: 18)),
                  ),
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
                  if (meal.items.isEmpty)
                    const Text('Aucun aliment ajouté.', style: TextStyle(color: Color(0xFF9C9C9C), fontSize: 12, fontStyle: FontStyle.italic))
                  else
                    ...meal.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(color: AppColors.text, fontSize: 13))),
                            Text('${item.calories} Cal', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () => _deleteFood(meal, entry.key),
                              child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.close, color: Color(0xFF9C9C9C), size: 16)),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _addFood(meal),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEDF1F0)), backgroundColor: const Color(0xFFF7F8FA), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('+ Ajouter un aliment', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
