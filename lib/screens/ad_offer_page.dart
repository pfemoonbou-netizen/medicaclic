import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class AdOfferPage extends StatelessWidget {
  const AdOfferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildHeroSliver(context),
          SliverToBoxAdapter(child: _buildReachStats()),
          SliverToBoxAdapter(child: _buildAudience()),
          SliverToBoxAdapter(child: _buildFormats()),
          SliverToBoxAdapter(child: _buildPackages(context)),
          SliverToBoxAdapter(child: _buildDjezzyCase()),
          SliverToBoxAdapter(child: _buildCta(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHeroSliver(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF1A1718),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1718), Color(0xFF6E1128)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            // Decorative circles
            Positioned(right: -40, top: -40,
              child: Container(width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                )),
            ),
            Positioned(left: -30, bottom: -30,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('PUBLICITÉ · ENTREPRISES',
                        style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text('Touchez vos clients\nlà où ils achètent.',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.2)),
                  const SizedBox(height: 10),
                  Text('LINCOO connecte votre marque à des millions\nd\'acheteurs algériens actifs.',
                      style: GoogleFonts.montserrat(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Reach stats ────────────────────────────────────────────────────────────

  Widget _buildReachStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        _reachStat('500K+', 'Acheteurs\nactifs', AppColors.blue),
        _divider(),
        _reachStat('1.2M+', 'Vues\n/ mois', Colors.green),
        _divider(),
        _reachStat('58', 'Wilayas\ncouvertes', AppColors.accent),
        _divider(),
        _reachStat('18–35', 'Tranche\nd\'âge cible', const Color(0xFFFFC107)),
      ]),
    );
  }

  Widget _reachStat(String value, String label, Color color) => Expanded(
        child: Column(children: [
          Text(value,
              style: GoogleFonts.montserrat(
                  color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 10, height: 1.4)),
        ]),
      );

  Widget _divider() => Container(
      height: 36, width: 1, color: AppColors.lightGray);

  // ── Audience ───────────────────────────────────────────────────────────────

  Widget _buildAudience() {
    final items = [
      ('Mode & Lifestyle', 0.68, AppColors.accent),
      ('Beauté & Cosmétique', 0.52, const Color(0xFFE91E8C)),
      ('Sport & Fitness', 0.38, AppColors.blue),
      ('Tech & Accessoires', 0.29, Colors.green),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Audience LINCOO', Icons.people_outline),
        const SizedBox(height: 14),
        ...items.map((e) {
          final (label, pct, color) = e;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(pct * 100).toInt()}%',
                    style: GoogleFonts.montserrat(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  backgroundColor: AppColors.lightGray,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Ad formats ─────────────────────────────────────────────────────────────

  Widget _buildFormats() {
    const formats = [
      _Format(Icons.view_carousel_outlined,  'Home Banner',       'Bannière en tête de fil d\'actualité',       'Top visibility'),
      _Format(Icons.slideshow_outlined,      'Stories Sponsorisées', 'Plein écran entre les stories utilisateurs', 'Max engagement'),
      _Format(Icons.grid_view_outlined,      'Produit Sponsorisé', 'Votre produit en tête des résultats shop',   'Conversion'),
      _Format(Icons.notifications_outlined,  'Push Notification', 'Notification directe aux utilisateurs ciblés', 'Reach immédiat'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Formats publicitaires', Icons.dashboard_customize_outlined),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: formats.map((f) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(f.icon, size: 22, color: AppColors.nearBlack),
              const Spacer(),
              Text(f.title,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(f.desc,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 9,
                      height: 1.4),
                  maxLines: 2),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.nearBlack,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(f.badge,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Packages ───────────────────────────────────────────────────────────────

  Widget _buildPackages(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Offres & Tarifs', Icons.workspace_premium_outlined),
        const SizedBox(height: 14),
        _packageCard(
          tag: 'STARTER',
          price: '30 000',
          period: '/ mois',
          color: AppColors.blue,
          features: [
            '1 format au choix',
            'Jusqu\'à 50 000 impressions',
            'Ciblage par wilaya',
            'Rapport mensuel PDF',
          ],
          cta: 'Démarrer',
          context: context,
        ),
        const SizedBox(height: 12),
        _packageCard(
          tag: 'BUSINESS',
          price: '80 000',
          period: '/ mois',
          color: AppColors.accent,
          features: [
            '3 formats combinés',
            'Jusqu\'à 200 000 impressions',
            'Ciblage âge + intérêts',
            'Tableau de bord temps réel',
            'Account manager dédié',
          ],
          cta: 'Choisir Business',
          context: context,
          highlight: true,
        ),
        const SizedBox(height: 12),
        _packageCard(
          tag: 'ENTERPRISE',
          price: 'Sur devis',
          period: '',
          color: AppColors.nearBlack,
          features: [
            'Tous les formats illimités',
            'Impressions garanties',
            'Campagnes multi-wilayas',
            'Intégration brand store',
            'Rapport & analytics avancés',
            'Support prioritaire 24/7',
          ],
          cta: 'Contacter l\'équipe',
          context: context,
        ),
      ]),
    );
  }

  Widget _packageCard({
    required String tag,
    required String price,
    required String period,
    required Color color,
    required List<String> features,
    required String cta,
    required BuildContext context,
    bool highlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? AppColors.nearBlack : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.nearBlack : AppColors.lightGray,
          width: highlight ? 0 : 1,
        ),
        boxShadow: highlight
            ? [BoxShadow(color: AppColors.nearBlack.withValues(alpha: 0.15),
                blurRadius: 20, offset: const Offset(0, 8))]
            : [],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: highlight ? 0.2 : 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(price,
                    style: GoogleFonts.montserrat(
                        color: highlight ? Colors.white : AppColors.nearBlack,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                if (period.isNotEmpty)
                  Text(' DA$period',
                      style: GoogleFonts.montserrat(
                          color: highlight ? Colors.white60 : AppColors.gray,
                          fontSize: 12)),
              ]),
            ]),
            if (highlight) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ Populaire',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
        // Features
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(children: [
                Icon(Icons.check_circle,
                    size: 15,
                    color: highlight ? Colors.white60 : color),
                const SizedBox(width: 10),
                Text(f,
                    style: GoogleFonts.montserrat(
                        color: highlight ? Colors.white : AppColors.nearBlack,
                        fontSize: 12)),
              ]),
            )),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      highlight ? Colors.white : AppColors.nearBlack,
                  foregroundColor:
                      highlight ? AppColors.nearBlack : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(cta,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Djezzy case study ──────────────────────────────────────────────────────

  Widget _buildDjezzyCase() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Exemple de campagne', Icons.emoji_events_outlined),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(children: [
            // Company header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1718), Color(0xFF2D0A14)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(children: [
                // Djezzy logo placeholder
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5001A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('Dz',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Djezzy',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    Text('Opérateur télécom · Algérie',
                        style: GoogleFonts.montserrat(
                            color: Colors.white54, fontSize: 11)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Campagne active',
                        style: GoogleFonts.montserrat(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),

            // Campaign info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lancement Djezzy 4G+',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Package Enterprise · 30 jours · Toutes wilayas',
                          style: GoogleFonts.montserrat(
                              color: AppColors.gray, fontSize: 11)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.nearBlack,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('ENTERPRISE',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
                ]),

                const SizedBox(height: 16),

                // KPIs
                Row(children: [
                  _kpiCard('280K', 'Acheteurs\ntouchés', const Color(0xFFE5001A)),
                  const SizedBox(width: 10),
                  _kpiCard('1.4M', 'Impressions', AppColors.blue),
                  const SizedBox(width: 10),
                  _kpiCard('8.4%', 'Engagement', Colors.green),
                  const SizedBox(width: 10),
                  _kpiCard('×3.2', 'ROI', AppColors.gold),
                ]),

                const SizedBox(height: 16),

                // Ad preview mockup
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5001A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text('Dz',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Djezzy',
                            style: GoogleFonts.montserrat(
                                color: AppColors.nearBlack,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text('Sponsorisé',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.gray, fontSize: 8)),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE5001A), Color(0xFFFF4444)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(children: [
                        Positioned(right: -20, top: -20,
                          child: Container(width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Djezzy 4G+',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900)),
                              Text('Restez connecté partout en Algérie',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white70, fontSize: 10)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Voir l\'offre',
                                    style: GoogleFonts.montserrat(
                                        color: const Color(0xFFE5001A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text('Aperçu du format Home Banner · LINCOO Ads',
                        style: GoogleFonts.montserrat(
                            color: AppColors.gray, fontSize: 9)),
                  ]),
                ),

                const SizedBox(height: 14),

                // Quote
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5001A).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE5001A).withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.format_quote,
                        color: Color(0xFFE5001A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LINCOO nous a permis de toucher une audience jeune et connectée en Algérie. Les résultats ont dépassé nos attentes en termes de notoriété et d\'engagement.',
                        style: GoogleFonts.montserrat(
                            color: AppColors.nearBlack,
                            fontSize: 12,
                            height: 1.5,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                Text('— Équipe Marketing, Djezzy Algérie',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _kpiCard(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.montserrat(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: AppColors.gray, fontSize: 9, height: 1.3)),
          ]),
        ),
      );

  // ── CTA ────────────────────────────────────────────────────────────────────

  Widget _buildCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1718), Color(0xFF6E1128)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 32),
        const SizedBox(height: 12),
        Text('Prêt à lancer votre campagne ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Notre équipe commerciale vous accompagne\nde A à Z dans votre campagne LINCOO.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                color: Colors.white60, fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.nearBlack,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Contacter l\'équipe commerciale',
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/campaigns'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white38),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Gérer mes campagnes',
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
        Icon(icon, size: 18, color: AppColors.nearBlack),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ]);
}

// ── Data ───────────────────────────────────────────────────────────────────

class _Format {
  final IconData icon;
  final String title, desc, badge;
  const _Format(this.icon, this.title, this.desc, this.badge);
}
