import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class Gym {
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final String priceFrom;
  final Color color;
  const Gym({required this.name, required this.address, required this.distanceKm, required this.rating, required this.priceFrom, required this.color});
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
    Gym(name: 'California Gym', address: 'Alger Centre', distanceKm: 1.2, rating: 4.7, priceFrom: '20 000 DA/mois', color: Color(0xFF1E4C8C)),
    Gym(name: 'Fitness Park', address: 'Hydra, Alger', distanceKm: 2.5, rating: 4.5, priceFrom: '15 000 DA/mois', color: Color(0xFFF2994A)),
    Gym(name: 'Gold\'s Gym', address: 'Bab Ezzouar', distanceKm: 4.1, rating: 4.6, priceFrom: '18 000 DA/mois', color: Color(0xFF7C6BE0)),
    Gym(name: 'PowerHouse', address: 'Kouba, Alger', distanceKm: 3.3, rating: 4.4, priceFrom: '12 000 DA/mois', color: Color(0xFF35B8A6)),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: g.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.fitness_center, color: g.color, size: 26),
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
