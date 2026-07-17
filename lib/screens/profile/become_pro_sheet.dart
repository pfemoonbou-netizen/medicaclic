import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'profile_theme.dart';

/// Debloque simplement la publication de contenu sur la page profil —
/// aucune inscription business (pas de vendeur / prestataire) requise ici.
class BecomeProSheet extends StatefulWidget {
  const BecomeProSheet({super.key});

  @override
  State<BecomeProSheet> createState() => _BecomeProSheetState();
}

class _BecomeProSheetState extends State<BecomeProSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ProfileProvider>().becomeCreator();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: ProfileColors.border, borderRadius: BorderRadius.circular(2))),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: ProfileColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_outlined, color: ProfileColors.accent, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Devenir un compte Pro', style: TextStyle(color: ProfileColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Débloquez la publication de contenu sur votre page : conseils, actualités, photos... Aucune inscription business n\'est requise.',
            style: TextStyle(color: ProfileColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: ProfileColors.red, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Devenir créateur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
