import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import '../../utils/app_colors.dart';

class _Category {
  final String key;
  final IconData icon;
  final String title;
  const _Category(this.key, this.icon, this.title);
}

const _categories = [
  _Category('allergies', Icons.coronavirus_outlined, 'Allergies'),
  _Category('family_history', Icons.account_tree_outlined, 'Antécédents familiaux'),
  _Category('diagnoses', Icons.monitor_heart_outlined, 'Diagnostics'),
  _Category('treatment', Icons.medication_outlined, 'Traitement'),
  _Category('symptoms', Icons.thermostat, 'Symptômes'),
  _Category('lab_tests', Icons.biotech_outlined, 'Analyses'),
  _Category('imaging', Icons.image_search_outlined, 'Scanner / Imagerie'),
];

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key, this.patientName = 'Mon dossier'});
  final String patientName;

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final rows = await supabase.from('medical_records').select('category').eq('user_id', user.id);
      final counts = <String, int>{};
      for (final row in rows as List) {
        final cat = row['category'] as String?;
        if (cat != null) counts[cat] = (counts[cat] ?? 0) + 1;
      }
      if (mounted) {
        setState(() {
          _counts = counts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Mon dossier médical',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 46, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.patientName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadCounts,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final count = _counts[cat.key] ?? 0;
                        return _RecordCard(
                          icon: cat.icon,
                          title: cat.title,
                          count: count,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${cat.title} — bientôt disponible')),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;
  const _RecordCard({required this.icon, required this.title, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF15A196), fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count enregistrement${count > 1 ? 's' : ''}',
                    style: const TextStyle(color: Color(0xFF727272), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA0A6)),
          ],
        ),
      ),
    );
  }
}
