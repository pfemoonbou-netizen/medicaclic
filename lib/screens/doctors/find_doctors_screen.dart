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
  String? _selectedSpecialty;

  @override
  Widget build(BuildContext context) {
    final doctorProvider = context.watch<DoctorProvider>();
    final filteredDoctors = _selectedSpecialty == null
        ? doctorProvider.doctors
        : doctorProvider.getDoctorsBySpecialty(_selectedSpecialty!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Find a doctor',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 24),
              // Category Title
              Text(
                'Category',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 12),
              // Category Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      label: 'All',
                      icon: Icons.people,
                      isSelected: _selectedSpecialty == null,
                      onTap: () {
                        setState(() => _selectedSpecialty = null);
                      },
                    ),
                    ...doctorProvider.specialties.map(
                      (specialty) => _buildCategoryChip(
                        label: specialty,
                        icon: _getSpecialtyIcon(specialty),
                        isSelected: _selectedSpecialty == specialty,
                        onTap: () {
                          setState(() => _selectedSpecialty = specialty);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Recommended Doctors
              Text(
                'Recommended Doctors',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              // Doctors List
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = filteredDoctors[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DoctorCard(
                      doctor: doctor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Book appointment with ${doctor.name}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGray,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSpecialtyIcon(String specialty) {
    switch (specialty) {
      case 'Cardiologue':
        return Icons.favorite;
      case 'Dentiste':
        return Icons.tooth_1;
      case 'Pneumologue':
        return Icons.lungs;
      case 'Dermatologue':
        return Icons.spa;
      default:
        return Icons.medical_services;
    }
  }
}
