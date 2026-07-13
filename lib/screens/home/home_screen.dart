import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import 'widgets/stories_bar.dart';
import 'widgets/social_feed.dart';
import 'nearby_services_screen.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/yemma_provider.dart';
import '../../utils/app_colors.dart';
import '../pharmacy/pharmacy_screen.dart';
import '../pharmacy/pharmacy_map_screen.dart';
import '../doctors/find_doctors_screen.dart';
import '../yemma/yemma_screen.dart';
import '../yemma/yemma_theme.dart';
import '../profile/profile_screen.dart';
import '../medical/medical_record_screen.dart';
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
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    String result = '';
    try {
      final data = await supabase.from('profiles').select('name').eq('id', user.id).maybeSingle();
      final name = data?['name'] as String?;
      if (name != null && name.isNotEmpty && !name.contains('@')) result = name;
    } catch (_) {}
    if (result.isEmpty) {
      final email = user.email ?? '';
      result = email.isNotEmpty ? email.split('@').first.split('+').first : 'Bienvenue';
    }
    if (mounted) setState(() => _displayName = result);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeTab(),
      const NearbyServicesScreen(),
      ChangeNotifierProvider(create: (_) => YemmaProvider(), child: const YemmaScreen()),
      const PharmacyScreen(),
      const ProfileScreen(),
    ];
    final isYemma = _index == 2;
    final isDark = isYemma;
    final darkBackground = YemmaColors.background;
    final darkCard = YemmaColors.card;
    final darkAccent = YemmaColors.pink;
    final darkTextSecondary = YemmaColors.textSecondary;
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Autour de moi'),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/services/yemma.png',
              width: 26,
              height: 26,
              errorBuilder: (context, error, stack) => const Icon(Icons.favorite),
            ),
            label: 'Yemma يمّا',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Boutique'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
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

  void _openDoctorsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindDoctorsScreen()),
    );
  }

  void _openPharmacyMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PharmacyMapScreen()),
    );
  }

  void _openNearbyServices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NearbyServicesScreen()),
    );
  }

  void _openMedicalRecord(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicalRecordScreen(patientName: _displayName.isEmpty ? 'Mon dossier' : _displayName)),
    );
  }

  Widget _categoryTile(IconData icon, String label, VoidCallback? onTap, {String? imagePath}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x19000000), spreadRadius: -11, offset: Offset(0, 17), blurRadius: 70)],
            ),
            child: imagePath == null
                ? Icon(icon, size: 28, color: AppColors.primary)
                : Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Icon(icon, size: 28, color: AppColors.primary),
                  ),
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
    final displayName = _displayName.isEmpty ? 'Bienvenue' : _displayName;
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
              Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF282C3F), fontSize: 26, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Les meilleurs services\nmédicaux en Algérie',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(24)),
              child: Image.network(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0SWfz3vtdincMUe0zzzH%2F74ffc6ad412edc8440bf2a10c35531341ac49d0eyoung-doctor-looking-pointing-removebg-preview%201.png?alt=media&token=e08f22ac-80cc-44cd-b386-3c524b7fc19e',
                width: 105,
                height: 88,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox(width: 105, height: 88),
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
          const StoriesBar(),
          const SizedBox(height: 24),
          const SocialFeed(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Doctor', style: TextStyle(color: _darkText, fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(onTap: () => _openDoctorsScreen(context), child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 12))),
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
          const Text('Mon dossier médical', style: TextStyle(color: _darkText, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _openMedicalRecord(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.folder_shared_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consulter mon dossier', style: TextStyle(color: _darkText, fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Allergies, traitements, analyses, antécédents...', style: TextStyle(color: _gray, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
