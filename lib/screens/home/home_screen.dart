import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/app_colors.dart';
import '../pharmacy/pharmacy_screen.dart';
import '../doctors/find_doctors_screen.dart';
import '../yemma/yemma_screen.dart';
import '../yemma/yemma_theme.dart';
import '../pharmacy/boutique_theme.dart';
import '../profile/profile_screen.dart';
import 'widgets/ambulance_sheet.dart';
import 'home_care/home_care_screen.dart';
import '../../providers/home_care_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeTab(),
      const FindDoctorsScreen(),
      const YemmaScreen(),
      const PharmacyScreen(),
      const ProfileScreen(),
    ];
    final isYemma = _index == 2;
    final isBoutique = _index == 3;
    final isDark = isYemma || isBoutique;
    final darkBackground = isYemma ? YemmaColors.background : BoutiqueColors.background;
    final darkCard = isYemma ? YemmaColors.card : BoutiqueColors.card;
    final darkAccent = isYemma ? YemmaColors.pink : BoutiqueColors.accent;
    final darkTextSecondary = isYemma ? YemmaColors.textSecondary : BoutiqueColors.textSecondary;
    return Scaffold(
      appBar: _index == 0 ? AppBar(title: const Text('MedicaClic')) : null,
      backgroundColor: isDark ? darkBackground : null,
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? darkCard : null,
        selectedItemColor: isDark ? darkAccent : AppColors.primary,
        unselectedItemColor: isDark ? darkTextSecondary : null,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Médecins'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yemma يمّا'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Boutique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  static const _lightTeal = Color(0xFFE8F3F1);
  static const _gray = Color(0xFFA0A7B0);
  static const _darkText = Color(0xFF101623);

  void _showAmbulanceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => const AmbulanceSheet(),
    );
  }

  void _openHomeCareScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangeNotifierProvider(create: (_) => HomeCareProvider(), child: const HomeCareScreen())),
    );
  }

  Widget _categoryTile(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x19000000), spreadRadius: -11, offset: Offset(0, 17), blurRadius: 70)],
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _gray, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _topDoctorCard(Doctor doctor) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: _lightTeal),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 35, backgroundColor: AppColors.secondary, child: Text(doctor.image, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18))),
          const SizedBox(height: 10),
          Text(doctor.name, style: const TextStyle(color: Color(0xFF3B4453), fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(doctor.specialty, style: const TextStyle(color: _gray, fontSize: 9, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: _lightTeal, borderRadius: BorderRadius.circular(2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star, size: 8, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text('${doctor.rating}', style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.location_on, size: 8, color: _gray),
              const SizedBox(width: 2),
              Text('${doctor.distance}km', style: const TextStyle(color: _gray, fontSize: 8, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _homeTab() {
    final doctors = context.watch<DoctorProvider>().doctors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: _lightTeal), borderRadius: BorderRadius.circular(24)),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: _gray),
                SizedBox(width: 10),
                Text('Search doctor, drugs, articles...', style: TextStyle(color: _gray, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryTile(Icons.medical_services_outlined, 'Doctor', () => setState(() => _index = 1)),
                const SizedBox(width: 16),
                _categoryTile(Icons.local_pharmacy_outlined, 'Pharmacy', () => setState(() => _index = 3)),
                const SizedBox(width: 16),
                _categoryTile(Icons.local_hospital_outlined, 'Hospital', null),
                const SizedBox(width: 16),
                _categoryTile(Icons.emergency_outlined, 'Ambulance', () => _showAmbulanceSheet(context)),
                const SizedBox(width: 16),
                _categoryTile(Icons.home_repair_service_outlined, 'Domicile', () => _openHomeCareScreen(context)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _lightTeal, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Early protection for\nyour family health', style: TextStyle(color: _darkText, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Learn more', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.family_restroom, size: 64, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Doctor', style: TextStyle(color: _darkText, fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(onTap: () => setState(() => _index = 1), child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 173,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: doctors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 13),
              itemBuilder: (context, i) => _topDoctorCard(doctors[i]),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Health article', style: TextStyle(color: _darkText, fontSize: 16, fontWeight: FontWeight.w600)),
              const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: _lightTeal), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.article_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('The 25 Healthiest Fruits You Can Eat, According to a Nutritionist', style: TextStyle(color: Color(0xFF565656), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Text('Jun 10, 2021', style: TextStyle(color: _gray, fontSize: 10, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: _gray, fontSize: 10)),
                            const SizedBox(width: 8),
                            const Text('5min read', style: TextStyle(color: _gray, fontSize: 10, fontWeight: FontWeight.w500)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [


                    
                    Icon(Icons.favorite_border, size: 18, color: _gray),
                    Icon(Icons.chat_bubble_outline, size: 18, color: _gray),
                    Icon(Icons.bookmark_border, size: 18, color: _gray),
                    Icon(Icons.share_outlined, size: 18, color: _gray),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
