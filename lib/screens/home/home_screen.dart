import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedicaClic'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildHomeTab() : _buildDoctorsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Doctors',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final productProvider = context.watch<ProductProvider>();
    final doctorProvider = context.watch<DoctorProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your desire\nheart solution',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _currentIndex = 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                        ),
                        child: Text(
                          'Find Doctor',
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text('👨‍⚕️', style: TextStyle(fontSize: 64)),
              ],
            ),
          ),
          // Popular Articles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trending Articles', style: AppTextStyles.heading2),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'See all',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildArticleCard(
                  title: 'Comparing the AstraZeneca and Sinovac COVID-19 Vaccines',
                  category: 'Covid-19',
                  readTime: '8 min read',
                ),
                const SizedBox(height: 12),
                _buildArticleCard(
                  title: 'The Horror Of The Swine Wave Of COVID-19',
                  category: 'Covid-19',
                  readTime: '9 min read',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Related Articles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Related Articles', style: AppTextStyles.heading2),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'See all',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildArticleCard(
                  title: 'The 25 Healthiest Fruits You Can Eat, According to a Nutritionist',
                  category: 'Health',
                  readTime: '5 min read',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Top Doctors
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Doctors', style: AppTextStyles.heading2),
                    GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                      child: Text(
                        'See all',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...doctorProvider.doctors.take(2).map(
                      (doctor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DoctorCard(
                          doctor: doctor,
                          onTap: () {},
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab() {
    return const FindDoctorsScreenContent();
  }

  Widget _buildArticleCard({
    required String title,
    required String category,
    required String readTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(category, style: AppTextStyles.bodySmall),
              ),
              const SizedBox(width: 12),
              Text(readTime, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class FindDoctorsScreenContent extends StatelessWidget {
  const FindDoctorsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorProvider = context.watch<DoctorProvider>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Find a doctor',
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recommended Doctors', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: doctorProvider.doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctorProvider.doctors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DoctorCard(
                    doctor: doctor,
                    onTap: () {},
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
