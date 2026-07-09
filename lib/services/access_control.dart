import '../models/app_user.dart';

// ── Capability catalogue ──────────────────────────────────────────────────────

enum Capability {
  // Consumer — every authenticated user
  viewFeed,
  viewReels,
  viewStories,
  likePost,
  savePost,
  commentPost,
  followUser,
  addToCart,
  purchase,
  viewProductDetails,

  // Content creation — seller / creator / company VERIFIED
  createPost,
  createReel,
  createStory,

  // Store & product management — seller VERIFIED
  manageStore,
  manageProducts,
  viewDashboard,
  viewAnalytics,

  // Advertising — company VERIFIED
  launchAd,
  manageCampaigns,
}

// ── Block reason returned when access is denied ───────────────────────────────

enum BlockReason { notAuthenticated, needsProRole, pending, rejected }

// ── Access control matrix ─────────────────────────────────────────────────────

class AccessControl {
  AccessControl._();

  static const _consumerCaps = {
    Capability.viewFeed,
    Capability.viewReels,
    Capability.viewStories,
    Capability.likePost,
    Capability.savePost,
    Capability.commentPost,
    Capability.followUser,
    Capability.addToCart,
    Capability.purchase,
    Capability.viewProductDetails,
  };

  static const _contentCaps = {
    Capability.createPost,
    Capability.createReel,
    Capability.createStory,
  };

  static const _storeCaps = {
    Capability.manageStore,
    Capability.manageProducts,
    Capability.viewDashboard,
    Capability.viewAnalytics,
  };

  static const _adCaps = {
    Capability.launchAd,
    Capability.manageCampaigns,
  };

  // Content-creation roles
  static const _creatorRoles = {ProRole.seller, ProRole.creator, ProRole.company};

  /// Returns true if [user] holds [cap].
  static bool can(AppUser user, Capability cap) {
    // Guests can only VIEW content
    if (user.isGuest) {
      return const {Capability.viewFeed, Capability.viewReels, Capability.viewStories}
          .contains(cap);
    }

    // Every authenticated user is a consumer
    if (_consumerCaps.contains(cap)) return true;

    // Content creation — seller / creator / company verified
    if (_contentCaps.contains(cap)) {
      return _isVerified(user, _creatorRoles);
    }

    // Store management — seller verified only
    if (_storeCaps.contains(cap)) {
      return _isVerified(user, {ProRole.seller});
    }

    // Advertising — company or seller verified
    if (_adCaps.contains(cap)) {
      return _isVerified(user, {ProRole.company, ProRole.seller});
    }

    return false;
  }

  /// Returns the reason an action is blocked (call only when [can] returned false).
  static BlockReason blockReason(AppUser user, Capability cap) {
    if (user.isGuest) return BlockReason.notAuthenticated;
    if (user.proStatus == ProStatus.pending) return BlockReason.pending;
    if (user.proStatus == ProStatus.rejected) return BlockReason.rejected;
    return BlockReason.needsProRole;
  }

  static bool _isVerified(AppUser user, Set<ProRole> roles) =>
      roles.contains(user.proRole) && user.proStatus == ProStatus.verified;
}
