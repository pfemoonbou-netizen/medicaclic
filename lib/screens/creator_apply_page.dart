import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../services/user_session.dart';

class CreatorApplyPage extends StatefulWidget {
  const CreatorApplyPage({super.key});

  @override
  State<CreatorApplyPage> createState() => _CreatorApplyPageState();
}

class _CreatorApplyPageState extends State<CreatorApplyPage> {
  final _formKey = GlobalKey<FormState>();

  // Type
  bool _isUgc        = false;
  bool _isAffiliate  = false;
  bool _isInfluencer = false;

  // Category
  String? _category;
  static const _categories = [
    'Beauté', 'Mode', 'Tech', 'Lifestyle', 'Food',
    'Sport', 'Gaming', 'Voyage', 'Humour', 'Autre',
  ];

  // Social links
  final _insta    = TextEditingController();
  final _tiktok   = TextEditingController();
  final _youtube  = TextEditingController();
  final _why      = TextEditingController();

  // Followers
  String? _followersRange;
  static const _ranges = [
    'Moins de 1 000',
    '1 000 – 10 000',
    '10 000 – 50 000',
    '50 000 – 200 000',
    '+ 200 000',
  ];

  bool _submitting = false;

  @override
  void dispose() {
    _insta.dispose();
    _tiktok.dispose();
    _youtube.dispose();
    _why.dispose();
    super.dispose();
  }

  bool get _typeSelected => _isUgc || _isAffiliate || _isInfluencer;

  Future<void> _submit() async {
    if (!_typeSelected) {
      _err('Sélectionne au moins un type de créateur.');
      return;
    }
    if (_category == null) {
      _err('Sélectionne ta catégorie principale.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final user   = Supabase.instance.client.auth.currentUser!;
      final client = Supabase.instance.client;

      final type = [
        if (_isUgc)        'ugc',
        if (_isAffiliate)  'affiliate',
        if (_isInfluencer) 'influencer',
      ].join(',');

      // Update profile → creator pending
      await client.from('profiles').update({
        'pro_role':        'creator',
        'pro_status':      'pending',
        'creator_type':    type,
        'category':        _category,
        if (_insta.text.trim().isNotEmpty)   'instagram_url': _insta.text.trim(),
        if (_tiktok.text.trim().isNotEmpty)  'tiktok_url':    _tiktok.text.trim(),
        if (_youtube.text.trim().isNotEmpty) 'youtube_url':   _youtube.text.trim(),
        if (_why.text.trim().isNotEmpty)     'creator_bio':   _why.text.trim(),
        if (_followersRange != null)         'followers_range': _followersRange,
      }).eq('id', user.id);

      // Notify admin
      await client.from('notifications').insert({
        'user_id': user.id,
        'type':    'creator_application',
        'title':   'Nouvelle demande Creator',
        'message': '${UserSession.instance.current.displayName} a soumis une demande creator.',
      }).catchError((_) {});

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _err(e.toString());
      }
    }
  }

  void _err(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Erreur',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
        content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06070F),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 20),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (r) =>
                        AppColors.brandGradient.createShader(r),
                    child: Text('Devenir\nLincoo Creator',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remplis ce formulaire — notre équipe validera\nton profil sous 24–48h.',
                    style: GoogleFonts.montserrat(
                        color: Colors.white38, fontSize: 12, height: 1.5),
                  ),
                ]),
              ),
            ),

            // ── Type de créateur ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _section('1. Quel type de créateur es-tu ?',
                  child: Column(children: [
                _typeChip(
                  '🎥',
                  'UGC Creator',
                  'Crée du contenu pour les marques (photos, vidéos, pubs)',
                  _isUgc,
                  (v) => setState(() => _isUgc = v),
                ),
                const SizedBox(height: 8),
                _typeChip(
                  '📢',
                  'Affiliate Creator',
                  'Partage des liens et gagne des commissions sur les ventes',
                  _isAffiliate,
                  (v) => setState(() => _isAffiliate = v),
                ),
                const SizedBox(height: 8),
                _typeChip(
                  '📣',
                  'Influenceur',
                  'Promeut des marques à ta communauté',
                  _isInfluencer,
                  (v) => setState(() => _isInfluencer = v),
                ),
              ])),
            ),

            // ── Catégorie ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _section('2. Ta catégorie principale',
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _categories.map((c) {
                      final sel = _category == c;
                      return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(c,
                              style: GoogleFonts.montserrat(
                                  color: sel ? AppColors.accent : Colors.white54,
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  )),
            ),

            // ── Liens sociaux ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _section('3. Tes réseaux sociaux (optionnel)',
                  child: Column(children: [
                _socialField(_insta,   Icons.camera_alt_outlined, '@Instagram'),
                const SizedBox(height: 10),
                _socialField(_tiktok,  Icons.music_video_outlined, '@TikTok'),
                const SizedBox(height: 10),
                _socialField(_youtube, Icons.play_circle_outline,  'Chaîne YouTube'),
              ])),
            ),

            // ── Abonnés (si influenceur) ────────────────────────────────
            if (_isInfluencer)
              SliverToBoxAdapter(
                child: _section('4. Nombre d\'abonnés (total)',
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _ranges.map((r) {
                        final sel = _followersRange == r;
                        return GestureDetector(
                          onTap: () => setState(() => _followersRange = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.purple.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.purple
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(r,
                                style: GoogleFonts.montserrat(
                                    color: sel
                                        ? AppColors.purple
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ),
                        );
                      }).toList(),
                    )),
              ),

            // ── Motivation ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _section(
                  _isInfluencer
                      ? '5. Pourquoi rejoindre Lincoo Creator ?'
                      : '4. Pourquoi rejoindre Lincoo Creator ?',
                  child: TextFormField(
                    controller: _why,
                    maxLines: 4,
                    maxLength: 400,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Parle-nous de toi, de ce que tu crées et de tes objectifs…',
                      hintStyle: GoogleFonts.montserrat(
                          color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.accent),
                      ),
                      counterStyle: GoogleFonts.montserrat(
                          color: Colors.white24, fontSize: 10),
                    ),
                  )),
            ),

            // ── Submit ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                child: _submitting
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : GestureDetector(
                        onTap: _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.blue],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 20, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('Envoyer ma demande',
                                style: GoogleFonts.montserrat(
                                    color: AppColors.nearBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, {required Widget child}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _typeChip(String icon, String label, String sub, bool selected,
      ValueChanged<bool> onTap) {
    return GestureDetector(
      onTap: () => onTap(!selected),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: GoogleFonts.montserrat(
                      color: selected ? AppColors.accent : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
              Text(sub,
                  style: GoogleFonts.montserrat(
                      color: Colors.white38, fontSize: 11)),
            ]),
          ),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                  color: selected ? AppColors.accent : Colors.white24),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: Colors.black, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _socialField(
      TextEditingController ctrl, IconData icon, String hint) =>
      TextFormField(
        controller: ctrl,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 13),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
      );
}
