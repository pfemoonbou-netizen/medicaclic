import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';

class CompanyPage extends StatefulWidget {
  final String companyId;
  const CompanyPage({super.key, required this.companyId});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    _isOwner = me == widget.companyId;

    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', widget.companyId)
            .single(),
        Supabase.instance.client
            .from('ad_campaigns')
            .select('*')
            .eq('company_id', widget.companyId)
            .eq('approval_status', 'approved')
            .eq('status', 'active')
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _offers  = List<Map<String, dynamic>>.from(results[1] as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Gradient from company name ──────────────────────────────────────────────
  static const _palettes = [
    [Color(0xFF020024), Color(0xFF1E3A5F)],
    [Color(0xFF1a1a2e), Color(0xFF6E1128)],
    [Color(0xFF0f0c29), Color(0xFF302b63)],
    [Color(0xFF292526), Color(0xFF485563)],
    [Color(0xFF000428), Color(0xFF004e92)],
    [Color(0xFF200122), Color(0xFF6F0000)],
  ];

  List<Color> get _gradient {
    final name = _profile?['store_name'] ?? _profile?['full_name'] ?? 'A';
    return _palettes[name.codeUnitAt(0) % _palettes.length];
  }

  String get _companyName =>
      _profile?['store_name'] ?? _profile?['full_name'] ?? _profile?['nom_complet'] ?? 'Entreprise';

  String get _initial => _companyName.isNotEmpty ? _companyName[0].toUpperCase() : 'E';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _profile == null
              ? _errorView()
              : _body(),
    );
  }

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.business_outlined, size: 52, color: AppColors.lightGray),
          const SizedBox(height: 12),
          Text('Page introuvable',
              style: GoogleFonts.montserrat(color: AppColors.gray, fontSize: 15)),
          const SizedBox(height: 16),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Retour', style: GoogleFonts.montserrat(color: AppColors.blue))),
        ]),
      );

  Widget _body() {
    final p = _profile!;
    final bio      = (p['bio'] ?? p['description'] ?? '') as String;
    final category = (p['category'] ?? '') as String;
    final wilaya   = (p['wilaya'] ?? '') as String;
    final phone    = (p['telephone'] ?? '') as String;
    final email    = (p['email'] ?? '') as String;
    final website  = (p['website'] ?? '') as String;
    final isVerified = (p['pro_status'] == 'verified');

    return CustomScrollView(
      slivers: [
        // ── Hero header ──────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: _gradient[0],
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: Colors.black26, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isOwner)
              IconButton(
                icon: Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                      color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 16),
                ),
                onPressed: () => Navigator.pushNamed(context, '/edit-company',
                    arguments: widget.companyId),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(children: [
              // gradient bg
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // decorative circles
              Positioned(
                right: -40, top: -40,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: -30, bottom: 0,
                child: Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // bottom fade
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.surfaceAlt.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // logo + name centred
              Positioned(
                left: 0, right: 0, bottom: 24,
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _initial,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      _companyName,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.accent, size: 20),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  if (category.isNotEmpty || wilaya.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (category.isNotEmpty) _headerChip(category),
                        if (category.isNotEmpty && wilaya.isNotEmpty)
                          const SizedBox(width: 6),
                        if (wilaya.isNotEmpty)
                          _headerChip('📍 $wilaya'),
                      ],
                    ),
                ]),
              ),
            ]),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // À propos
              if (bio.isNotEmpty) ...[
                _section('À propos', Icons.info_outline_rounded),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text(bio,
                      style: GoogleFonts.montserrat(
                        color: AppColors.gray,
                        fontSize: 13.5,
                        height: 1.6,
                      )),
                ),
                const SizedBox(height: 24),
              ],

              // Nos Offres
              _section(
                'Nos Offres & Services',
                Icons.local_offer_outlined,
                trailing: Text(
                  '${_offers.length} offre${_offers.length != 1 ? 's' : ''}',
                  style: GoogleFonts.montserrat(
                      color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              if (_offers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _emptyOffers(),
                )
              else
                ..._offers.map((o) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _offerCard(o),
                    )),
              const SizedBox(height: 24),

              // Contact
              if (phone.isNotEmpty || email.isNotEmpty || website.isNotEmpty) ...[
                _section('Contact', Icons.contact_phone_outlined),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    if (phone.isNotEmpty)
                      _contactTile(Icons.phone_outlined, phone, AppColors.success,
                          onTap: () {}),
                    if (email.isNotEmpty)
                      _contactTile(Icons.email_outlined, email, AppColors.blue,
                          onTap: () {}),
                    if (website.isNotEmpty)
                      _contactTile(Icons.language_outlined, website, AppColors.accent,
                          onTap: () {}),
                  ]),
                ),
                const SizedBox(height: 24),
              ],

              // Owner: edit button
              if (_isOwner) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, '/quick-ad-publish'),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text('Publier une nouvelle offre',
                          style: GoogleFonts.montserrat(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _headerChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _section(String title, IconData icon, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          if (trailing != null) trailing,
        ]),
      );

  Widget _offerCard(Map<String, dynamic> offer) {
    final title       = (offer['title'] ?? '') as String;
    final description = (offer['description'] ?? '') as String;
    final imageUrl    = offer['image_url'] as String?;
    final ctaLabel    = offer['cta_label'] as String?;
    final hasImage    = imageUrl != null && !imageUrl.startsWith('gradient:');

    final gradients = {
      'gradient:neon':    [const Color(0xFFB06AFF), const Color(0xFF8B5CF6)],
      'gradient:crimson': [const Color(0xFF292526), const Color(0xFF6E1128)],
      'gradient:purple':  [const Color(0xFF8A2BE2), const Color(0xFF4B0082)],
      'gradient:orange':  [const Color(0xFFFF512F), const Color(0xFFDD2476)],
    };

    final bgColors = (!hasImage && imageUrl != null)
        ? (gradients[imageUrl] ?? [const Color(0xFF1a1a2e), const Color(0xFF16213e)])
        : [const Color(0xFF1a1a2e), const Color(0xFF16213e)];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // visual
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: hasImage
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBox(bgColors))
                : _gradientBox(bgColors),
          ),
        ),
        // content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 12.5, height: 1.5)),
            ],
            if (ctaLabel != null && ctaLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ctaLabel,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _gradientBox(List<Color> colors) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
      );

  Widget _emptyOffers() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Icon(Icons.local_offer_outlined,
              size: 36, color: AppColors.lightGray),
          const SizedBox(height: 8),
          Text('Aucune offre disponible pour le moment',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _contactTile(IconData icon, String value, Color color,
          {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.lightGray),
          ]),
        ),
      );
}
