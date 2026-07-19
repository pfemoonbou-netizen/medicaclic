import 'package:flutter/material.dart';

class _MuscleGroup {
  final String name;
  final Color color;
  final IconData icon;
  const _MuscleGroup(this.name, this.color, this.icon);
}

const _pectoraux = _MuscleGroup('Pectoraux', Color(0xFF4E9BFF), Icons.accessibility_new);
const _dos = _MuscleGroup('Dos', Color(0xFF7C5CFF), Icons.rowing);
const _jambes = _MuscleGroup('Jambes', Color(0xFF2ED9A8), Icons.directions_walk);
const _bras = _MuscleGroup('Bras', Color(0xFFFF6B35), Icons.fitness_center);
const _epaules = _MuscleGroup('Épaules', Color(0xFFF2C94C), Icons.self_improvement);
const _abdos = _MuscleGroup('Abdos', Color(0xFFEC5A8D), Icons.circle);

class _Exercise {
  final String name;
  final _MuscleGroup muscle;
  final String equipment;
  final String target;
  final String instructions;
  final String photoAsset;
  const _Exercise({required this.name, required this.muscle, required this.equipment, required this.target, required this.instructions, required this.photoAsset});
}

const _exercises = [
  _Exercise(
    name: 'Curl biceps incliné haltères',
    photoAsset: 'assets/images/exercises/curl_biceps_incline.jpg',
    muscle: _bras,
    equipment: 'Haltères + banc incliné',
    target: '3 × 10-12',
    instructions:
        "Assis sur un banc incliné à 45°, bras tendus vers le bas. Remonte l'haltère en fléchissant le coude sans bouger l'épaule, contracte le biceps en haut, puis redescends lentement. Garde le coude fixe pendant tout le mouvement.",
  ),
  _Exercise(
    name: 'Extension triceps à la poulie',
    photoAsset: 'assets/images/exercises/extension_triceps_poulie.jpg',
    muscle: _bras,
    equipment: 'Poulie haute + corde ou barre',
    target: '3 × 10-12',
    instructions:
        "Debout face à la poulie haute, coudes collés au corps. Pousse la corde vers le bas jusqu'à extension complète du bras, contracte le triceps, puis remonte lentement sans décoller les coudes du buste.",
  ),
  _Exercise(
    name: 'Pompes (push-up dynamique)',
    photoAsset: 'assets/images/exercises/pompes.jpg',
    muscle: _pectoraux,
    equipment: 'Poids du corps',
    target: '3 × 12-20',
    instructions:
        "Position de planche, mains légèrement plus larges que les épaules. Descends en fléchissant les coudes à 45° du corps jusqu'à effleurer le sol, puis pousse pour remonter en gardant le corps bien gainé (abdos et fessiers serrés).",
  ),
  _Exercise(
    name: 'Développé couché',
    photoAsset: 'assets/images/exercises/developpe_couche.jpg',
    muscle: _pectoraux,
    equipment: 'Barre + banc plat',
    target: '4 × 8-10',
    instructions:
        "Allongé sur le banc, barre au-dessus de la poitrine. Descends la barre en contrôlant jusqu'à toucher légèrement le sternum, coudes à environ 75°, puis pousse pour remonter sans verrouiller brutalement les coudes.",
  ),
  _Exercise(
    name: 'Rowing barre',
    photoAsset: 'assets/images/exercises/rowing_barre.jpg',
    muscle: _dos,
    equipment: 'Barre',
    target: '3 × 8-10',
    instructions:
        "Buste penché en avant, dos droit, tire la barre vers le nombril en resserrant les omoplates. Redescends lentement en contrôlant la charge, sans arrondir le dos.",
  ),
  _Exercise(
    name: 'Tractions (tirage vertical)',
    photoAsset: 'assets/images/exercises/tractions.jpg',
    muscle: _dos,
    equipment: 'Barre de traction ou machine',
    target: '4 × 8-10',
    instructions:
        "Prise large, suspendu bras tendus. Tire le corps vers le haut jusqu'à ce que le menton dépasse la barre, en engageant le dos plus que les bras, puis redescends en contrôlant la phase excentrique.",
  ),
  _Exercise(
    name: 'Squat',
    photoAsset: 'assets/images/exercises/squat.jpg',
    muscle: _jambes,
    equipment: 'Barre ou poids du corps',
    target: '4 × 8-10',
    instructions:
        "Pieds largeur d'épaules, descends en poussant les hanches vers l'arrière comme pour t'asseoir, genoux alignés avec les pieds, jusqu'à cuisses parallèles au sol. Remonte en poussant sur les talons.",
  ),
  _Exercise(
    name: 'Fentes haltères',
    photoAsset: 'assets/images/exercises/fentes_halteres.jpg',
    muscle: _jambes,
    equipment: 'Haltères',
    target: '3 × 10-12',
    instructions:
        "Fais un grand pas en avant, descends jusqu'à ce que le genou arrière frôle le sol, buste droit. Pousse sur le talon avant pour revenir en position initiale, puis alterne les jambes.",
  ),
  _Exercise(
    name: 'Développé militaire',
    photoAsset: 'assets/images/exercises/developpe_militaire.jpg',
    muscle: _epaules,
    equipment: 'Barre ou haltères',
    target: '3 × 8-10',
    instructions:
        "Debout ou assis, pousse la charge au-dessus de la tête jusqu'à extension complète des bras, sans cambrer excessivement le dos. Redescends jusqu'aux épaules avant de répéter.",
  ),
  _Exercise(
    name: 'Élévations latérales',
    photoAsset: 'assets/images/exercises/elevations_laterales.jpg',
    muscle: _epaules,
    equipment: 'Haltères',
    target: '3 × 12-15',
    instructions:
        "Bras légèrement fléchis, lève les haltères sur les côtés jusqu'à hauteur des épaules, coudes légèrement plus hauts que les mains. Redescends lentement sans balancer le corps.",
  ),
  _Exercise(
    name: 'Gainage (planche)',
    photoAsset: 'assets/images/exercises/gainage_planche.jpg',
    muscle: _abdos,
    equipment: 'Poids du corps',
    target: '3 × 45-60 sec',
    instructions:
        "Appui sur les avant-bras et les pointes de pieds, corps aligné de la tête aux talons. Contracte les abdos et les fessiers pour éviter que le bassin ne s'affaisse ou ne monte trop.",
  ),
  _Exercise(
    name: 'Crunch',
    photoAsset: 'assets/images/exercises/crunch.jpg',
    muscle: _abdos,
    equipment: 'Poids du corps',
    target: '3 × 15-20',
    instructions:
        "Allongé, genoux fléchis, mains derrière la tête. Enroule le buste vers les genoux en expirant, en n'utilisant que les abdos (pas les bras pour tirer sur la nuque), puis redescends en contrôlant.",
  ),
];

/// Bibliotheque d'exercices : illustration par groupe musculaire, muscle
/// cible, materiel et technique detaillee pour chaque exercice.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _filter = 'Tous';

  List<String> get _muscleNames => ['Tous', ..._exercises.map((e) => e.muscle.name).toSet()];

  List<_Exercise> get _filtered => _filter == 'Tous' ? _exercises : _exercises.where((e) => e.muscle.name == _filter).toList();

  void _openDetail(_Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        foregroundColor: const Color(0xFF101522),
        title: const Text('Bibliothèque d\'exercices', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _muscleNames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final name = _muscleNames[i];
                final active = name == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF101522) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? const Color(0xFF101522) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(name, style: TextStyle(color: active ? Colors.white : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: _filtered.length,
              itemBuilder: (context, i) => _exerciseCard(_filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(_Exercise exercise) {
    return GestureDetector(
      onTap: () => _openDetail(exercise),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEDF1F0))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                color: exercise.muscle.color.withValues(alpha: 0.12),
                child: Image.asset(
                  exercise.photoAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(exercise.muscle.icon, color: exercise.muscle.color, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: const TextStyle(color: Color(0xFF101522), fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: exercise.muscle.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(exercise.muscle.name, style: TextStyle(color: exercise.muscle.color, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      Text(exercise.target, style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetailSheet extends StatelessWidget {
  final _Exercise exercise;
  const _ExerciseDetailSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 180,
              alignment: Alignment.center,
              color: exercise.muscle.color.withValues(alpha: 0.12),
              child: Image.asset(
                exercise.photoAsset,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Icon(exercise.muscle.icon, color: exercise.muscle.color, size: 64),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(exercise.name, style: const TextStyle(color: Color(0xFF101522), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(Icons.accessibility_new, exercise.muscle.name, exercise.muscle.color),
              _tag(Icons.fitness_center, exercise.equipment, const Color(0xFF6B7280)),
              _tag(Icons.repeat, exercise.target, const Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Technique', style: TextStyle(color: Color(0xFF101522), fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(exercise.instructions, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
