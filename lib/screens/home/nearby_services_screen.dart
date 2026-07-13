import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../pharmacy/pharmacy_map_screen.dart';
import '../doctors/find_doctors_screen.dart';
import 'home_care/home_care_screen.dart';
import '../../providers/home_care_provider.dart';
import 'widgets/ambulance_sheet.dart';

/// Page "Autour de moi" : regroupe la recherche des services les plus
/// proches (pharmacies, cliniques/médecins, soins à domicile, ambulance).
class NearbyServicesScreen extends StatelessWidget {
  const NearbyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('Autour de moi', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: AppColors.secondary), borderRadius: BorderRadius.circular(24)),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: Color(0xFFA0A7B0)),
                SizedBox(width: 10),
                Text('Rechercher un service proche...', style: TextStyle(color: Color(0xFFA0A7B0), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Services les plus proches', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _serviceCard(
            icon: Icons.local_pharmacy,
            color: const Color(0xFF18A589),
            title: 'Pharmacies proches',
            subtitle: 'Trouver les pharmacies ouvertes près de vous',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyMapScreen())),
          ),
          _serviceCard(
            icon: Icons.local_hospital,
            color: const Color(0xFF3E69FE),
            title: 'Cliniques & médecins proches',
            subtitle: 'Consulter les praticiens autour de vous',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindDoctorsScreen())),
          ),
          _serviceCard(
            icon: Icons.home_repair_service,
            color: const Color(0xFFF2994A),
            title: 'Soins à domicile',
            subtitle: 'Infirmiers et services de soins à domicile',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => HomeCareProvider(), child: const HomeCareScreen()))),
          ),
          _serviceCard(
            icon: Icons.emergency,
            color: const Color(0xFFEB5757),
            title: 'Ambulance',
            subtitle: 'Appeler une ambulance en urgence',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: const Color(0x99000000),
              builder: (_) => const AmbulanceSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 12, height: 1.3)),
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
