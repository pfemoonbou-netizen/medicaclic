import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../services/access_control.dart';
import 'user_scope.dart';
import 'pro_onboarding_sheet.dart';

// ── Gated ─────────────────────────────────────────────────────────────────────

/// Shows [child] only when the current user holds [capability].
/// Falls back to [fallback] (default: invisible) otherwise.
///
/// ```dart
/// Gated(
///   capability: Capability.createPost,
///   child: FloatingActionButton(...),
/// )
/// ```
class Gated extends StatelessWidget {
  final Capability capability;
  final Widget child;

  /// Shown when access is denied. Null = [SizedBox.shrink].
  final Widget? fallback;

  const Gated({
    super.key,
    required this.capability,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final user = UserScope.userOf(context);
    return AccessControl.can(user, capability)
        ? child
        : (fallback ?? const SizedBox.shrink());
  }
}

// ── GatedTap ──────────────────────────────────────────────────────────────────

/// Renders [child] unconditionally but intercepts the tap.
/// - Allowed → calls [onAllowed].
/// - Blocked + pending → shows "En cours de vérification" dialog.
/// - Blocked + needs role → opens [ProOnboardingSheet].
/// - Not authenticated → navigates to /login.
///
/// ```dart
/// GatedTap(
///   capability: Capability.createPost,
///   onAllowed: () => Navigator.pushNamed(context, '/create'),
///   child: IconButton(icon: Icon(Icons.add)),
/// )
/// ```
class GatedTap extends StatelessWidget {
  final Capability capability;
  final VoidCallback onAllowed;
  final Widget child;

  const GatedTap({
    super.key,
    required this.capability,
    required this.onAllowed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final user = UserScope.userOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (AccessControl.can(user, capability)) {
          onAllowed();
        } else {
          _handleBlocked(context, user);
        }
      },
      child: child,
    );
  }

  void _handleBlocked(BuildContext context, AppUser user) {
    switch (AccessControl.blockReason(user, capability)) {
      case BlockReason.notAuthenticated:
        Navigator.pushNamed(context, '/login');
      case BlockReason.pending:
        _showPendingDialog(context, user);
      case BlockReason.rejected:
        _showRejectedDialog(context);
      case BlockReason.needsProRole:
        ProOnboardingSheet.show(context);
    }
  }

  static void _showPendingDialog(BuildContext context, AppUser user) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFC107), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text('En cours de vérification',
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ]),
        content: Text(
          'Votre demande de compte ${user.proRoleLabel.toLowerCase()} est en cours d\'examen.\n\n'
          'Vous recevrez une notification dès que votre profil sera validé.',
          style: GoogleFonts.montserrat(
              color: const Color(0xFF787676), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.montserrat(
                    color: const Color(0xFF347EFB),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static void _showRejectedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Text('Demande rejetée',
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        content: Text(
          'Votre demande de compte pro a été rejetée.\nContactez le support pour plus d\'informations.',
          style: GoogleFonts.montserrat(
              color: const Color(0xFF787676), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/help');
            },
            child: Text('Contacter le support',
                style: GoogleFonts.montserrat(
                    color: const Color(0xFF6E1128),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── LockedBadge ───────────────────────────────────────────────────────────────

/// Overlay a small lock icon on a widget to signal it is pro-gated.
class LockedBadge extends StatelessWidget {
  final Widget child;
  final Capability capability;

  const LockedBadge({super.key, required this.capability, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = UserScope.userOf(context);
    if (AccessControl.can(user, capability)) return child;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        child,
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF292526),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.lock, color: Colors.white, size: 10),
          ),
        ),
      ],
    );
  }
}
