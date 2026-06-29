import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';
import '../../widgets/doctor_card.dart';

class FindDoctorsScreen extends StatefulWidget {
  const FindDoctorsScreen({Key? key}) : super(key: key);
  @override
  State<FindDoctorsScreen> createState() => _FindDoctorsScreenState();
}

class _FindDoctorsScreenState extends State<FindDoctorsScreen> {
  String? _selected;

  IconData _icon(String s) {
    switch (s) {
      case 'Cardiologue': return Icons.favorite;
      case 'Pneumologue': return Icons.air;
      case 'Dermatologue': return Icons.spa;
      default: return Icons.medical_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final docs = _selected == null ? provider.doctors : provider.getDoctorsBySpecialty(_selected!);
    return Scaffold(
      appBar: AppBar(title: const Text('Trouver un medecin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(decoration: InputDecoration(hintText: 'Rechercher un medecin', prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 20),
            Text('Categorie', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Tous', Icons.people, _selected == null, () => setState(() => _selected = null)),
                  ...provider.specialties.map((s) => _chip(s, _icon(s), _selected == s, () => setState(() => _selected = s))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Medecins recommandes', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            ...docs.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: DoctorCard(doctor: d, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rendez-vous avec ${d.name}')));
            }))),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray)),
          child: Row(children: [Icon(icon, color: sel ? AppColors.white : AppColors.primary, size: 18), const SizedBox(width: 8), Text(label, style: TextStyle(color: sel ? AppColors.white : AppColors.primary, fontWeight: FontWeight.w600))]),
        ),
      ),
    );
  }
}
