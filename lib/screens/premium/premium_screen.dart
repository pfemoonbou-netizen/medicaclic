import 'package:flutter/material.dart';

/// Écran d'abonnement Premium (version DZ, 300 DA/mois).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const _coral = Color(0xFFF4716A);
  static const _dark = Color(0xFF101522);
  static const _grey = Color(0xFF6B7280);

  static const _features = <List<String>>[
    ['insights', 'Analyse des douleurs par IA', 'Comprends tes douleurs avec des graphiques et un suivi intelligent.'],
    ['vaccines', 'Rappels de vaccins', 'Ne rate plus jamais une date : rappels automatiques pour bébé et maman.'],
    ['pro', 'Suivi Pro complet', 'Grossesse semaine par semaine, dossier médical, export PDF.'],
    ['community', 'Accès communauté', 'Discussions illimitées avec d\'autres mamans.'],
    ['doctor', 'Contenu vérifié par des médecins', 'Des conseils fiables, mis à jour régulièrement.'],
    ['share', 'Partage avec tes proches', 'Partage facilement ton suivi avec ta famille.'],
  ];

  IconData _icon(String key) {
    switch (key) {
      case 'insights':
        return Icons.insights;
      case 'vaccines':
        return Icons.vaccines;
      case 'pro':
        return Icons.workspace_premium;
      case 'community':
        return Icons.forum;
      case 'doctor':
        return Icons.verified_user;
      default:
        return Icons.ios_share;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _dark,
        title: const Text('Devenir membre', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Row(
            children: [
              Text('Passez à ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _dark)),
              Text('Premium ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _coral)),
              Text('👑', style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Débloque tout le potentiel de MedicaClic.', style: TextStyle(color: _grey, fontSize: 14)),
          const SizedBox(height: 20),

          // Carte prix
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFA7474), Color(0xFFFAB474)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _coral.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text('300 DA', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    SizedBox(width: 6),
                    Text('/mois', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                  child: const Text('✨ 7 jours d\'essai gratuit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                const Text('Annulable à tout moment.', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Ce que tu débloques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 12),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _coral.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_icon(f[0]), color: _coral, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f[1], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                          const SizedBox(height: 2),
                          Text(f[2], style: const TextStyle(fontSize: 12, color: _grey, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          const Center(child: Text('Commence par un essai gratuit de 7 jours, sans engagement.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB5B5B5), fontSize: 11))),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 Essai Premium activé ! (paiement à venir)')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: const Text('Essayer gratuitement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
