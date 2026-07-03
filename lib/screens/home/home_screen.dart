import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/yemma_provider.dart';
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
      ChangeNotifierProvider(create: (_) => YemmaProvider(), child: const YemmaScreen()),
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

  Widget _greetingHeader() {
    final name = context.watch<AuthProvider>().user?.name;
    final displayName = (name == null || name.isEmpty) ? 'Bienvenue' : name;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('👋', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('Bonjour !', style: TextStyle(color: Color(0xFF282C3F), fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(displayName, style: const TextStyle(color: Color(0xFF282C3F), fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _index = 4),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _promoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38A8A8), Color(0xFF1E8A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Les meilleurs services\nmédicaux en Algérie',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.25),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(24)),
              child: Image.network(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0SWfz3vtdincMUe0zzzH%2F74ffc6ad412edc8440bf2a10c35531341ac49d0eyoung-doctor-looking-pointing-removebg-preview%201.png?alt=media&token=e08f22ac-80cc-44cd-b386-3c524b7fc19e',
                width: 130,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox(width: 130, height: 110),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard({required String name, required String specialty, required String time, required String day, required String date, required List<Color> gradient}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(date, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                Text(day, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
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
          _greetingHeader(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _index = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 44,
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: _lightTeal), borderRadius: BorderRadius.circular(24)),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 18, color: _gray),
                  SizedBox(width: 10),
                  Text('Rechercher un médecin, une pharmacie...', style: TextStyle(color: _gray, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryTile(Icons.medical_services_outlined, 'Médecin', () => setState(() => _index = 1)),
                const SizedBox(width: 16),
                _categoryTile(Icons.local_pharmacy_outlined, 'Pharmacie', () => setState(() => _index = 3)),
                const SizedBox(width: 16),
                _categoryTile(Icons.favorite_outline, 'Yemma', () => setState(() => _index = 2)),
                const SizedBox(width: 16),
                _categoryTile(Icons.emergency_outlined, 'Ambulance', () => _showAmbulanceSheet(context)),
                const SizedBox(width: 16),
                _categoryTile(Icons.home_repair_service_outlined, 'Domicile', () => _openHomeCareScreen(context)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _promoBanner(),
          const SizedBox(height: 24),
          const Text('Prochains rendez-vous', style: TextStyle(color: _darkText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _appointmentCard(
                  name: 'Dr. Samuel',
                  specialty: 'Cardiologie',
                  time: '9:30',
                  day: 'Mar',
                  date: '12',
                  gradient: const [Color(0xFF38A8A8), Color(0xFF1E8A8A)],
                ),
                const SizedBox(width: 12),
                _appointmentCard(
                  name: 'Dr. Amina',
                  specialty: 'Pédiatrie',
                  time: '14:00',
                  day: 'Mer',
                  date: '13',
                  gradient: const [Color(0xFFF4890D), Color(0xFFC65C0F)],
                ),
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
