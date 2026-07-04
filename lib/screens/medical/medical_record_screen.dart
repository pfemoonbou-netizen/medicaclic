import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class _Record {
  final IconData icon;
  final String title;
  final int count;
  const _Record({required this.icon, required this.title, required this.count});
}

class MedicalRecordScreen extends StatelessWidget {
  const MedicalRecordScreen({super.key, this.patientName = 'Mon dossier'});
  final String patientName;

  static const _records = [
    _Record(icon: Icons.coronavirus_outlined, title: 'Allergies', count: 4),
    _Record(icon: Icons.account_tree_outlined, title: 'Antécédents familiaux', count: 2),
    _Record(icon: Icons.monitor_heart_outlined, title: 'Diagnostics', count: 3),
    _Record(icon: Icons.medication_outlined, title: 'Traitement', count: 4),
    _Record(icon: Icons.thermostat, title: 'Symptômes', count: 2),
    _Record(icon: Icons.biotech_outlined, title: 'Analyses', count: 4),
    _Record(icon: Icons.image_search_outlined, title: 'Scanner / Imagerie', count: 2),
  ];

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
                      patientName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _RecordCard(
                record: _records[i],
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_records[i].title} — bientôt disponible')),
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
  final _Record record;
  final VoidCallback onTap;
  const _RecordCard({required this.record, required this.onTap});

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
              child: Icon(record.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(color: Color(0xFF15A196), fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.count} enregistrements',
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
