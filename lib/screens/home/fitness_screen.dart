import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'workout_plan_screen.dart';

class Gym {
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final String priceFrom;
  final Color color;
  final String? logo;
  const Gym({required this.name, required this.address, required this.distanceKm, required this.rating, required this.priceFrom, required this.color, this.logo});
}

/// Page Fitness : recherche et liste des salles de sport les plus proches.
class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});
  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  String _query = '';

  static const List<Gym> _gyms = [
    Gym(name: 'California Gym', address: 'Alger Centre', distanceKm: 1.2, rating: 4.7, priceFrom: '20 000 DA/mois', color: Color(0xFF1E4C8C), logo: 'assets/images/influencers/gym_logo_california.jpg'),
    Gym(name: 'Fitness Park Club DZ', address: 'Hydra, Alger', distanceKm: 2.5, rating: 4.5, priceFrom: '15 000 DA/mois', color: Color(0xFFF2994A), logo: 'assets/images/influencers/gym_logo_fitness_park.jpg'),
    Gym(name: 'Gold\'s Gym', address: 'Bab Ezzouar', distanceKm: 4.1, rating: 4.6, priceFrom: '18 000 DA/mois', color: Color(0xFF7C6BE0), logo: 'assets/images/influencers/gym_logo_golds.jpg'),
    Gym(name: 'PowerHouse.DZ', address: 'Kouba, Alger', distanceKm: 3.3, rating: 4.4, priceFrom: '12 000 DA/mois', color: Color(0xFF35B8A6), logo: 'assets/images/influencers/gym_logo_powerhouse.jpg'),
  ];

  List<Gym> get _filtered {
    final q = _query.trim().toLowerCase();
    final sorted = List<Gym>.from(_gyms)..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    if (q.isEmpty) return sorted;
    return sorted.where((g) => g.name.toLowerCase().contains(q) || g.address.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gyms = _filtered;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('Fitness', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: AppColors.secondary), borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Color(0xFFA0A7B0)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une salle de sport...',
                      hintStyle: TextStyle(color: Color(0xFFA0A7B0), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutPlanScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0D0F14), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Color(0xFFFF6B35), size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mon programme de musculation', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Séances Push/Pull/Legs — suivi des poids et séries', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('${gyms.length} salle${gyms.length > 1 ? 's' : ''} de sport proche${gyms.length > 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (gyms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Aucune salle trouvée.', style: TextStyle(color: Colors.grey))),
            ),
          ...gyms.map(_gymCard),
        ],
      ),
    );
  }

  Widget _gymCard(Gym g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDF1F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 14)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: g.color.withValues(alpha: 0.12)),
              child: g.logo != null
                  ? Image.asset(
                      g.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(Icons.fitness_center, color: g.color, size: 26),
                    )
                  : Icon(Icons.fitness_center, color: g.color, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Color(0xFF9C9C9C)),
                    const SizedBox(width: 2),
                    Text('${g.address} · ${g.distanceKm} km', style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFFFB020)),
                    const SizedBox(width: 3),
                    Text('${g.rating}', style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Text('dès ${g.priceFrom}', style: TextStyle(color: g.color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
        ],
      ),
    );
  }
}
