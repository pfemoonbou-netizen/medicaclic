import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';
import '../../utils/app_colors.dart';

class _PremiumTag extends StatelessWidget {
  const _PremiumTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFFD54A), borderRadius: BorderRadius.circular(20)),
      child: const Text('PREMIUM', style: TextStyle(color: Color(0xFF5B3B00), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class MedicalCategoryScreen extends StatefulWidget {
  const MedicalCategoryScreen({super.key, required this.categoryKey, required this.title});
  final String categoryKey;
  final String title;

  @override
  State<MedicalCategoryScreen> createState() => _MedicalCategoryScreenState();
}

class _MedicalCategoryScreenState extends State<MedicalCategoryScreen> {
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final rows = await supabase
          .from('medical_records')
          .select()
          .eq('user_id', user.id)
          .eq('category', widget.categoryKey)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _docs = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showImportSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Importer une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _importPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
              title: const Text('Importer un PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _importPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _importPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _upload(bytes, picked.name, 'image');
  }

  Future<void> _importPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    await _upload(bytes, file.name, 'pdf');
  }

  Future<void> _upload(Uint8List bytes, String fileName, String fileType) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _uploading = true);
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : (fileType == 'pdf' ? 'pdf' : 'jpg');
      final safeName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '${user.id}/${widget.categoryKey}/$safeName';
      await supabase.storage.from('medical-documents').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: fileType == 'pdf' ? 'application/pdf' : 'image/jpeg'),
          );
      await supabase.from('medical_records').insert({
        'user_id': user.id,
        'category': widget.categoryKey,
        'title': fileName,
        'file_path': path,
        'file_type': fileType,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document importé ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDoc(Map<String, dynamic> doc) async {
    final path = doc['file_path'] as String?;
    if (path == null) return;
    try {
      final signed = await supabase.storage.from('medical-documents').createSignedUrl(path, 3600);
      await launchUrl(Uri.parse(signed), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d\'ouvrir: $e')));
      }
    }
  }

  void _analyzeWithAI(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Analyse IA', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'L\'analyse automatique de vos résultats par intelligence artificielle est une fonctionnalité Premium.\n\nElle sera disponible très bientôt : l\'IA lira votre analyse et vous expliquera les résultats en langage simple.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _uploading ? null : _showImportSheet,
        icon: _uploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add, color: Colors.white),
        label: const Text('Importer', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _aiBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _docs.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _docCard(_docs[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _aiBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () {
          if (_docs.isEmpty) {
            _showImportSheet();
          } else {
            _analyzeWithAI(_docs.first);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF7B4DFF), Color(0xFF9C6BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Analyser avec l\'IA', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        _PremiumTag(),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('Importez votre analyse, l\'IA vous l\'explique en langage simple.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 72, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Aucun document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            const Text(
              'Importez une photo ou un PDF de votre analyse avec le bouton "Importer".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF727272), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docCard(Map<String, dynamic> doc) {
    final isPdf = doc['file_type'] == 'pdf';
    final title = (doc['title'] as String?) ?? 'Document';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppColors.primary, size: 20),
                onPressed: () => _openDoc(doc),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _analyzeWithAI(doc),
              icon: const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              label: const Text('Analyser avec l\'IA  ·  Premium', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
