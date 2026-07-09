enum ProRole { none, buyer, seller, creator, company }
enum ProStatus { none, incomplete, pending, verified, rejected }

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final ProRole proRole;
  final ProStatus proStatus;
  final bool onboardingComplete;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.proRole = ProRole.none,
    this.proStatus = ProStatus.none,
    this.onboardingComplete = false,
  });

  /// Default demo user shown when Supabase is unavailable or user is not logged in.
  factory AppUser.demo() => const AppUser(
        id: 'demo',
        email: 'rania@example.com',
        displayName: 'Rania Sara',
        proRole: ProRole.none,
        proStatus: ProStatus.none,
        onboardingComplete: false,
      );

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        email: m['email'] as String? ?? '',
        displayName: (m['full_name'] as String?)?.isNotEmpty == true
            ? m['full_name'] as String
            : (m['nom_complet'] as String?)?.isNotEmpty == true
                ? m['nom_complet'] as String
                : 'Utilisateur',
        avatarUrl: m['avatar_url'] as String?,
        proRole: ProRole.values.firstWhere(
          (r) => r.name == m['pro_role'],
          orElse: () => ProRole.none,
        ),
        proStatus: ProStatus.values.firstWhere(
          (s) => s.name == m['pro_status'],
          orElse: () => ProStatus.none,
        ),
        onboardingComplete: m['onboarding_complete'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': displayName,
        'nom_complet': displayName,
        'avatar_url': avatarUrl,
        'pro_role': proRole.name,
        'pro_status': proStatus.name,
        'onboarding_complete': onboardingComplete,
      };

  AppUser copyWith({
    String? displayName,
    String? avatarUrl,
    ProRole? proRole,
    ProStatus? proStatus,
    bool? onboardingComplete,
  }) =>
      AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        proRole: proRole ?? this.proRole,
        proStatus: proStatus ?? this.proStatus,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );

  // ── Derived state ──────────────────────────────────────────────────────────

  bool get isGuest => id.isEmpty || id == 'demo';
  bool get needsOnboarding => !onboardingComplete && !isGuest;
  bool get isPending => proStatus == ProStatus.pending;
  bool get isVerifiedPro =>
      proStatus == ProStatus.verified && proRole != ProRole.none;

  String get proRoleLabel => switch (proRole) {
        ProRole.buyer => 'Acheteur',
        ProRole.seller => 'Vendeur',
        ProRole.creator => 'Créateur',
        ProRole.company => 'Entreprise',
        ProRole.none => 'Consommateur',
      };

  String get proStatusLabel => switch (proStatus) {
        ProStatus.incomplete => 'Profil incomplet',
        ProStatus.pending => 'En attente de vérification',
        ProStatus.verified => 'Vérifié ✓',
        ProStatus.rejected => 'Rejeté',
        ProStatus.none => '',
      };
}
