import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';

// Opens the comment bottom sheet for a given post/reel.
void showCommentSheet(
  BuildContext context, {
  required String postId,
  void Function(int newCount)? onCountChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => CommentSheet(
        postId: postId, onCountChanged: onCountChanged),
  );
}

class CommentSheet extends StatefulWidget {
  final String postId;
  final void Function(int newCount)? onCountChanged;

  const CommentSheet({super.key, required this.postId, this.onCountChanged});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Step 1: load comments — no embedded profile join because
      // post_comments.user_id → auth.users, not public.profiles
      final rows = await Supabase.instance.client
          .from('post_comments')
          .select('id, content, created_at, user_id')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      final comments = List<Map<String, dynamic>>.from(rows as List);

      // Step 2: fetch profiles for the unique user_ids
      final userIds = comments
          .map((c) => c['user_id'] as String)
          .toSet()
          .toList();
      final profileMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select('id, full_name, avatar_url')
              .inFilter('id', userIds);
          for (final p in (profiles as List)) {
            profileMap[p['id'] as String] =
                Map<String, dynamic>.from(p as Map);
          }
        } catch (_) {
          // profiles table missing or inaccessible — show comments without names
        }
      }

      // Step 3: merge profile data into each comment
      final merged = comments.map((c) {
        final profile = profileMap[c['user_id'] as String];
        return {...c, 'profiles': profile};
      }).toList();

      if (mounted) {
        setState(() {
          _comments = merged;
          _loading  = false;
        });
        _scrollToBottom();
        // Sync real count to parent (reel card / feed card)
        widget.onCountChanged?.call(merged.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Erreur commentaires : $e',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _posting) return;

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Connectez-vous pour commenter',
            style: GoogleFonts.montserrat(fontSize: 13)),
        backgroundColor: AppColors.nearBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    setState(() => _posting = true);
    try {
      final client = Supabase.instance.client;
      await client.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': authUser.id,
        'content': text,
      });
      _ctrl.clear();
      await _load(); // also calls onCountChanged via _load
      // Persist count in store_posts so card shows real number next load
      try {
        await client
            .from('store_posts')
            .update({'comments_count': _comments.length})
            .eq('id', widget.postId);
      } catch (_) {
        // post_id may be a product id — ignore
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e.toString().contains('relation') || e.toString().contains('does not exist')
                ? 'Table manquante — exécutez migration_post_comments.sql dans Supabase'
                : 'Erreur : ${e.toString()}',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt   = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'À l\'instant';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}min';
    if (diff.inHours   < 24)  return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Handle ─────────────────────────────────────────────────────────
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2)),
        ),
        Text('Commentaires',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const Divider(height: 16),

        // ── Comments list ──────────────────────────────────────────────────
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.48),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2)))
              : _comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 44, color: AppColors.lightGray),
                        const SizedBox(height: 10),
                        Text('Aucun commentaire pour l\'instant.',
                            style: GoogleFonts.montserrat(
                                color: AppColors.gray, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Soyez le premier à commenter !',
                            style: GoogleFonts.montserrat(
                                color: AppColors.grayLight, fontSize: 12)),
                      ]),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _CommentTile(
                          comment: _comments[i], timeAgo: _timeAgo),
                    ),
        ),

        // ── Input row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: 1,
                maxLength: 500,
                enableSuggestions: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _post(),
                decoration: InputDecoration(
                  hintText: 'Écrire un commentaire... 😊',
                  hintStyle: GoogleFonts.montserrat(
                      color: AppColors.grayLight, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgGray,
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                style: GoogleFonts.montserrat(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _posting ? null : _post,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.blue]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _posting
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                        color: AppColors.nearBlack, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String Function(String?) timeAgo;
  const _CommentTile({required this.comment, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final profile  = comment['profiles'] as Map?;
    final name     = (profile?['full_name'] as String?) ?? 'Utilisateur';
    final avatar   = profile?['avatar_url'] as String?;
    final content  = (comment['content']  as String?) ?? '';
    final time     = timeAgo(comment['created_at'] as String?);
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              avatar != null ? NetworkImage(avatar) : null,
          backgroundColor: AppColors.accent.withValues(alpha: 0.18),
          child: avatar == null
              ? Text(initials,
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text(name,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack)),
              const SizedBox(width: 6),
              Text(time,
                  style: GoogleFonts.montserrat(
                      fontSize: 10, color: AppColors.grayLight)),
            ]),
            const SizedBox(height: 2),
            Text(content,
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.nearBlack,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
