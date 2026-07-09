import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

enum NavTab { feed, shop, reels, cart, create, dashboard, profile }

// ─────────────────────────────────────────────────────────────────────────────
// Active item accent color
const _kActive  = Color(0xFF7C3AED);
const _kInactive = Color(0xFF9DB2CE);
const _kBarBg   = Color(0xFF1C1C1E);
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomNav extends StatelessWidget {
  final NavTab activeTab;
  final String role;

  const AppBottomNav({
    super.key,
    required this.activeTab,
    this.role = 'buyer',
  });

  @override
  Widget build(BuildContext context) {
    final items      = _itemsFor(role);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 100 + safeBottom,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalW = constraints.maxWidth;
          final itemW  = totalW / items.length;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Bar background ─────────────────────────────────────────
              Positioned(
                left: 0, right: 0, top: 25,
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: _kBarBg,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Items ──────────────────────────────────────────────────
              for (int i = 0; i < items.length; i++)
                _buildItem(context, items[i], i, itemW),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, _NavItem item, int index, double itemW) {
    final isActive = activeTab == item.tab;
    final cx = itemW * index + itemW / 2; // center x of this slot

    // ── CREATE button — always elevated with gradient ──────────────────
    if (item.isCreate) {
      return Positioned(
        left: cx - 27,
        top: 1,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(context, item.route);
          },
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.nearBlack, size: 26),
              ),
            ],
          ),
        ),
      );
    }

    // ── ACTIVE item — elevated colored circle ──────────────────────────
    if (isActive) {
      return Positioned(
        left: cx - 27,
        top: 1,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
          },
          child: SizedBox(
            width: 54,
            child: Column(
              children: [
                // Circle bubble
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _kActive,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kActive.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(item.activeIcon,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: GoogleFonts.montserrat(
                    color: _kActive,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── INACTIVE item — flat icon + label inside bar ───────────────────
    return Positioned(
      left: cx - 27,
      top: 45, // bar_top(25) + 20
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (item.tab == NavTab.cart) {
            Navigator.pushNamed(context, item.route);
          } else {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
        child: SizedBox(
          width: 54,
          child: Column(
            children: [
              Icon(item.icon, color: _kInactive, size: 24),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.montserrat(
                  color: _kInactive,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_NavItem> _itemsFor(String role) {
    switch (role) {
      case 'seller':
      case 'company':
        return const [
          _NavItem(NavTab.feed,      Icons.home_outlined,      Icons.home_rounded,      '/feed',      'Home'),
          _NavItem(NavTab.shop,      Icons.storefront_outlined, Icons.storefront_rounded,'/shop',      'Boutique'),
          _NavItem(NavTab.create,    Icons.add,                Icons.add,               '/create',    '+',  isCreate: true),
          _NavItem(NavTab.dashboard, Icons.bar_chart_outlined,  Icons.bar_chart_rounded, '/dashboard', 'Stats'),
          _NavItem(NavTab.profile,   Icons.person_outline,     Icons.person_rounded,    '/profile',   'Profil'),
        ];
      case 'creator':
        return const [
          _NavItem(NavTab.feed,    Icons.home_outlined,       Icons.home_rounded,    '/feed',    'Home'),
          _NavItem(NavTab.reels,   Icons.play_circle_outline, Icons.play_circle,     '/reels',   'Reels'),
          _NavItem(NavTab.create,  Icons.add,                 Icons.add,             '/create',  '+',  isCreate: true),
          _NavItem(NavTab.shop,    Icons.shopping_bag_outlined,Icons.shopping_bag_rounded,'/shop','Shop'),
          _NavItem(NavTab.profile, Icons.person_outline,      Icons.person_rounded,  '/profile', 'Profil'),
        ];
      default:
        return const [
          _NavItem(NavTab.feed,    Icons.home_outlined,        Icons.home_rounded,        '/feed',    'Home'),
          _NavItem(NavTab.shop,    Icons.storefront_outlined,  Icons.storefront_rounded,  '/shop',    'Boutique'),
          _NavItem(NavTab.reels,   Icons.play_circle_outline,  Icons.play_circle,         '/reels',   'Reels'),
          _NavItem(NavTab.cart,    Icons.shopping_bag_outlined,Icons.shopping_bag_rounded,'/cart',    'Panier'),
          _NavItem(NavTab.profile, Icons.person_outline,       Icons.person_rounded,      '/profile', 'Profil'),
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final NavTab   tab;
  final IconData icon;
  final IconData activeIcon;
  final String   route;
  final String   label;
  final bool     isCreate;

  const _NavItem(
    this.tab,
    this.icon,
    this.activeIcon,
    this.route,
    this.label, {
    this.isCreate = false,
  });
}
