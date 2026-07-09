import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/app_user.dart';
import '../services/rewards_service.dart';
import '../services/user_session.dart';
import '../widgets/primary_button.dart';

class CreateContentPage extends StatefulWidget {
  const CreateContentPage({super.key});

  @override
  State<CreateContentPage> createState() => _CreateContentPageState();
}

class _CreateContentPageState extends State<CreateContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── Store data ─────────────────────────────────────────────────────────────
  String? _storeId;
  String? _storeError;
  List<Map<String, dynamic>> _myProducts = [];
  bool _storeLoading = true;

  // ── Reel state ──────────────────────────────────────────────────────────────
  final _reelCaption = TextEditingController();
  Uint8List? _reelMediaBytes;
  String     _reelMediaType = '';
  String     _reelFileName  = '';
  bool       _reelIsVideo   = false;
  String?    _reelProductId;
  bool       _reelPublishing = false;

  // ── Story state ─────────────────────────────────────────────────────────────
  final _storyCaption = TextEditingController();
  Uint8List? _storyMediaBytes;
  String     _storyMediaType  = '';
  bool       _storyIsVideo    = false;
  bool       _storyPublishing = false;

  // ── Post state ──────────────────────────────────────────────────────────────
  final _postCaption = TextEditingController();
  Uint8List? _postImgBytes;
  String?    _postProductId;
  bool       _postPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadStore();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _reelCaption.dispose();
    _storyCaption.dispose();
    _postCaption.dispose();
    super.dispose();
  }

  // ── Load seller store (auto-create if missing) ─────────────────────────────
  Future<void> _loadStore() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      if (mounted) setState(() => _storeLoading = false);
      return;
    }
    final client = Supabase.instance.client;
    try {
      final appUser = UserSession.instance.current;
      final isSeller = appUser.proRole == ProRole.seller ||
          appUser.proRole == ProRole.company ||
          appUser.proRole == ProRole.creator;

      final store = isSeller
          ? await UserSession.instance.ensureSellerStore(
              ownerId: authUser.id,
              storeName: appUser.displayName.isNotEmpty ? appUser.displayName : 'Ma boutique',
              wilaya: null,
              category: null,
            )
          : null;

      if (store != null) {
        _storeId = store['id'] as String?;
        if (_storeId != null) {
          final prods = await client
              .from('products')
              .select('id, name, price, promo_price, images')
              .eq('store_id', _storeId!)
              .order('created_at', ascending: false)
              .limit(50);
          _myProducts =
              List<Map<String, dynamic>>.from(prods as List);
        }
      }
    } catch (e) {
      // Store the error so _buildStoreError() can display it
      _storeError = e.toString();
    }
    if (mounted) setState(() => _storeLoading = false);
  }

  // ── Image / video picker (image_picker — works on web, Android, iOS) ─────────
  final _picker = ImagePicker();

  Future<void> _pickReelImage() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _reelMediaBytes = bytes;
      _reelMediaType  = 'image/jpeg';
      _reelFileName   = file.name;
      _reelIsVideo    = false;
    });
  }

  Future<void> _pickReelVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _reelMediaBytes = bytes;
      _reelMediaType  = 'video/mp4';
      _reelFileName   = file.name;
      _reelIsVideo    = true;
    });
  }

  Future<void> _pickStoryImage() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _storyMediaBytes = bytes;
      _storyMediaType  = 'image/jpeg';
      _storyIsVideo    = false;
    });
  }

  Future<void> _pickStoryVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _storyMediaBytes = bytes;
      _storyMediaType  = 'video/mp4';
      _storyIsVideo    = true;
    });
  }

  Future<void> _pickPostImage() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() => _postImgBytes = bytes);
  }

  // ── Upload to Supabase Storage ──────────────────────────────────────────────
  Future<String?> _upload(Uint8List bytes, String path, String contentType) async {
    await Supabase.instance.client.storage
        .from('product-images')
        .uploadBinary(path, bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true));
    return Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(path);
  }

  String _ext(String mime) {
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('png'))  return 'png';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('mp4'))  return 'mp4';
    if (mime.contains('webm')) return 'webm';
    if (mime.contains('mov'))  return 'mov';
    return 'bin';
  }

  // ── Publish reel ────────────────────────────────────────────────────────────
  Future<void> _publishReel() async {
    if (_storeId == null) {
      _showError('Boutique introuvable',
          'Votre boutique vendeur n\'a pas pu être chargée. Vérifiez votre connexion et réessayez.');
      return;
    }
    setState(() => _reelPublishing = true);
    try {
      String? coverUrl;
      String? videoUrl;

      if (_reelMediaBytes != null) {
        final ts   = DateTime.now().microsecondsSinceEpoch;
        final ext  = _ext(_reelMediaType);
        final path = '$_storeId/reels/$ts.$ext';
        final url  = await _upload(
            _reelMediaBytes!, path,
            _reelMediaType.isNotEmpty ? _reelMediaType : 'image/jpeg');
        if (_reelIsVideo) {
          videoUrl = url;
        } else {
          coverUrl = url;
        }
      }

      await Supabase.instance.client.from('store_posts').insert({
        'store_id': _storeId!,
        'post_type': 'reel',
        if (_reelCaption.text.trim().isNotEmpty)
          'caption': _reelCaption.text.trim(),
        if (coverUrl != null) 'cover_url': coverUrl,
        if (videoUrl != null) 'media_urls': [videoUrl],
        if (_reelProductId != null) 'product_id': _reelProductId,
      });

      // Award XP + Coins for publishing a reel
      RewardsService.instance
        ..awardXp(XpReward.publishReel, 'Reel publié')
        ..awardCoins(CoinsReward.publishReel, 'Reel publié');

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _reelPublishing = false);
        _showError('Erreur de publication', e.toString());
      }
    }
  }

  // ── Publish post ────────────────────────────────────────────────────────────
  Future<void> _publishPost() async {
    if (_storeId == null) {
      _showError('Boutique introuvable',
          'Votre boutique vendeur n\'a pas pu être chargée.');
      return;
    }
    if (_postCaption.text.trim().isEmpty && _postImgBytes == null) {
      _showError('Contenu requis', 'Ajoutez une image ou une légende.');
      return;
    }
    setState(() => _postPublishing = true);
    try {
      String? imgUrl;
      if (_postImgBytes != null) {
        final ts   = DateTime.now().microsecondsSinceEpoch;
        final path = '$_storeId/posts/$ts.jpg';
        imgUrl = await _upload(_postImgBytes!, path, 'image/jpeg');
      }
      await Supabase.instance.client.from('store_posts').insert({
        'store_id': _storeId!,
        'post_type': _postProductId != null ? 'commercial' : 'classic',
        if (_postCaption.text.trim().isNotEmpty)
          'caption': _postCaption.text.trim(),
        if (imgUrl != null) 'media_urls': [imgUrl],
        if (imgUrl != null) 'cover_url': imgUrl,
        if (_postProductId != null) 'product_id': _postProductId,
      });

      // First post bonus + coins
      RewardsService.instance.awardXp(XpReward.firstPost, 'Post publié');

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _postPublishing = false);
        _showError('Erreur de publication', e.toString());
      }
    }
  }

  // ── Publish story ───────────────────────────────────────────────────────────
  Future<void> _publishStory() async {
    if (_storeId == null) {
      _showError('Boutique introuvable',
          'Votre boutique vendeur n\'a pas pu être chargée.');
      return;
    }
    if (_storyMediaBytes == null) {
      _showError('Média requis', 'Ajoutez une image ou une vidéo pour votre story.');
      return;
    }
    setState(() => _storyPublishing = true);
    try {
      final ts   = DateTime.now().microsecondsSinceEpoch;
      final ext  = _ext(_storyMediaType);
      final path = '$_storeId/stories/$ts.$ext';
      final url  = await _upload(
          _storyMediaBytes!, path,
          _storyMediaType.isNotEmpty ? _storyMediaType : 'image/jpeg');

      final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 24));

      await Supabase.instance.client.from('store_posts').insert({
        'store_id':   _storeId!,
        'post_type':  'story',
        'expires_at': expiresAt.toIso8601String(),
        if (_storyCaption.text.trim().isNotEmpty)
          'caption': _storyCaption.text.trim(),
        if (_storyIsVideo)
          'media_urls': [url]
        else ...{
          'cover_url':  url,
          'media_urls': [url],
        },
      });

      // Award Coins for story
      RewardsService.instance.awardCoins(CoinsReward.publishStory, 'Story publiée');

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _storyPublishing = false);
        _showError('Erreur de publication', e.toString());
      }
    }
  }

  void _showError(String title, String detail) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(detail,
            style: GoogleFonts.montserrat(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack)),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.nearBlack, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Créer du contenu',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.nearBlack,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.nearBlack,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Reel'),
            Tab(text: 'Post'),
            Tab(text: 'Story'),
          ],
        ),
      ),
      body: _storeLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildReelTab(),
                _buildPostTab(),
                _buildStoryTab(),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Reel tab
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildReelTab() {
    final hasMedia = _reelMediaBytes != null;

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_storeId == null) _noStoreCard(),

      // ── Media zone ───────────────────────────────────────────────────────────
      Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.nearBlack,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasMedia
            ? Stack(fit: StackFit.expand, children: [
                // Preview
                _reelIsVideo
                    ? _videoPlaceholder()
                    : Image.memory(_reelMediaBytes!, fit: BoxFit.cover),
                // Dark gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // Filename + change button
                Positioned(
                  bottom: 10, left: 12, right: 12,
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _reelFileName.isNotEmpty
                            ? _reelFileName
                            : (_reelIsVideo ? 'Vidéo sélectionnée' : 'Image sélectionnée'),
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _reelMediaBytes = null;
                        _reelMediaType  = '';
                        _reelFileName   = '';
                        _reelIsVideo    = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white30),
                        ),
                        child: Text('Changer',
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_outlined,
                      size: 52, color: Colors.white38),
                  const SizedBox(height: 10),
                  Text('Image ou vidéo de couverture',
                      style: GoogleFonts.montserrat(
                          color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton.icon(
                      onPressed: _pickReelImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.nearBlack,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: Text('Image',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _pickReelVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.videocam_outlined, size: 16),
                      label: Text('Vidéo',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text('Depuis votre PC ou téléphone',
                      style: GoogleFonts.montserrat(
                          color: Colors.white24, fontSize: 10)),
                ],
              ),
      ),

      const SizedBox(height: 16),

      // ── Caption ─────────────────────────────────────────────────────────────
      _textField(
        controller: _reelCaption,
        hint: 'Description du Reel…',
        maxLines: 3,
        maxLength: 300,
      ),

      const SizedBox(height: 12),

      // ── Product picker ───────────────────────────────────────────────────────
      if (_myProducts.isNotEmpty) ...[
        _label('Produit lié (optionnel)'),
        const SizedBox(height: 8),
        _ProductPicker(
          products: _myProducts,
          selectedId: _reelProductId,
          onChanged: (id) => setState(() => _reelProductId = id),
        ),
        const SizedBox(height: 16),
      ],

      // ── Publish ──────────────────────────────────────────────────────────────
      _reelPublishing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : PrimaryButton(
              label: 'Publier le Reel',
              onPressed: _storeId == null ? null : _publishReel,
            ),

      const SizedBox(height: 24),
    ]);
  }

  Widget _videoPlaceholder() => Stack(fit: StackFit.expand, children: [
        Container(color: const Color(0xFF0D0D1A)),
        const Center(
          child: Icon(Icons.play_circle_fill_rounded,
              color: Colors.white38, size: 64),
        ),
      ]);

  // ─────────────────────────────────────────────────────────────────────────────
  // Post tab
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPostTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_storeId == null) _noStoreCard(),

      // Image zone
      Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        clipBehavior: Clip.hardEdge,
        child: _postImgBytes != null
            ? Stack(children: [
                Image.memory(_postImgBytes!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _postImgBytes = null),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined,
                    size: 44, color: AppColors.gray),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickPostImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.nearBlack,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 16),
                  label: Text('Choisir une photo',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ]),
      ),

      const SizedBox(height: 16),

      _textField(
          controller: _postCaption,
          hint: 'Rédigez une légende…',
          maxLines: 4,
          maxLength: 500),

      const SizedBox(height: 12),

      if (_myProducts.isNotEmpty) ...[
        _label('Taguer un produit (optionnel)'),
        const SizedBox(height: 8),
        _ProductPicker(
          products: _myProducts,
          selectedId: _postProductId,
          onChanged: (id) => setState(() => _postProductId = id),
        ),
        const SizedBox(height: 16),
      ],

      _postPublishing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : PrimaryButton(
              label: 'Publier le Post',
              onPressed: _storeId == null ? null : _publishPost,
            ),

      const SizedBox(height: 24),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Story tab
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStoryTab() {
    final hasMedia = _storyMediaBytes != null;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_storeId == null) _noStoreCard(),

      // ── Media zone ───────────────────────────────────────────────────────────
      Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.nearBlack,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasMedia
            ? Stack(fit: StackFit.expand, children: [
                _storyIsVideo
                    ? _videoPlaceholder()
                    : Image.memory(_storyMediaBytes!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 12, right: 12,
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _storyIsVideo ? 'Vidéo sélectionnée' : 'Image sélectionnée',
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _storyMediaBytes = null;
                        _storyMediaType  = '';
                        _storyIsVideo    = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text('Changer',
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.auto_stories_outlined,
                    size: 52, color: Colors.white38),
                const SizedBox(height: 10),
                Text('Image ou vidéo (24h)',
                    style: GoogleFonts.montserrat(
                        color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton.icon(
                    onPressed: _pickStoryImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.nearBlack,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: Text('Image',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _pickStoryVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.videocam_outlined, size: 16),
                    label: Text('Vidéo',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text('Depuis votre PC ou téléphone',
                    style: GoogleFonts.montserrat(
                        color: Colors.white24, fontSize: 10)),
              ]),
      ),

      const SizedBox(height: 16),

      _textField(
        controller: _storyCaption,
        hint: 'Ajouter un texte à votre story…',
        maxLines: 2,
        maxLength: 150,
      ),

      const SizedBox(height: 16),

      _storyPublishing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : PrimaryButton(
              label: 'Publier la Story',
              onPressed: _storeId == null ? null : _publishStory,
            ),

      const SizedBox(height: 24),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _noStoreCard() {
    final hasError = _storeError != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (hasError ? AppColors.error : AppColors.warning)
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (hasError ? AppColors.error : AppColors.warning)
                .withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(hasError ? Icons.error_outline : Icons.warning_amber_rounded,
              color: hasError ? AppColors.error : AppColors.warning,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasError
                  ? 'Erreur de chargement de la boutique'
                  : 'Boutique vendeur requise',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        if (_storeError != null) ...[
          const SizedBox(height: 6),
          Text(_storeError!,
              style: GoogleFonts.montserrat(
                  color: AppColors.error, fontSize: 11)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _storeLoading = true;
                _storeError   = null;
              });
              _loadStore();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.nearBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Réessayer',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            'Complétez votre profil vendeur pour pouvoir publier du contenu.',
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 11),
          ),
        ],
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.montserrat(
          color: AppColors.nearBlack,
          fontSize: 13,
          fontWeight: FontWeight.w700));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required int maxLength,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        // Emojis & suggestions enabled — no input formatter restrictions
        enableSuggestions: true,
        enableIMEPersonalizedLearning: true,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.montserrat(color: AppColors.grayLight, fontSize: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.nearBlack)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(14),
          counterStyle: GoogleFonts.montserrat(
              color: AppColors.grayLight, fontSize: 11),
        ),
        // Use system font fallback so emojis render correctly
        style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Product picker dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _ProductPicker extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ProductPicker({
    required this.products,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          hint: Text('Aucun produit (optionnel)',
              style: GoogleFonts.montserrat(
                  color: AppColors.grayLight, fontSize: 13)),
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.nearBlack),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Aucun produit',
                  style: GoogleFonts.montserrat(
                      color: AppColors.grayLight, fontSize: 13)),
            ),
            ...products.map((p) {
              final name  = p['name']  as String? ?? '';
              final price = (p['price'] as num?)?.toStringAsFixed(0) ?? '';
              return DropdownMenuItem<String?>(
                value: p['id'] as String?,
                child: Text('$name · $price DA',
                    style: GoogleFonts.montserrat(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
