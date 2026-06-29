import 'package:flutter/material.dart';
import '../providers/doctor_provider.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback? onTap;
  const DoctorCard({Key? key, required this.doctor, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(radius: 26, backgroundColor: AppColors.secondary, child: Text(doctor.image, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
        title: Text(doctor.name, style: AppTextStyles.heading3),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.specialty, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.star, size: 14, color: Colors.orange), const SizedBox(width: 4), Text('${doctor.rating}', style: AppTextStyles.bodySmall), const SizedBox(width: 12), const Icon(Icons.location_on, size: 14, color: AppColors.primary), const SizedBox(width: 4), Text('${doctor.distance}km', style: AppTextStyles.bodySmall)]),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Book', style: TextStyle(color: AppColors.white, fontSize: 12)),
        ),
      ),
    );
  }
}
