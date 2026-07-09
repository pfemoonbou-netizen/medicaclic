import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// ── Shimmer base ──────────────────────────────────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.35, end: 0.9).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: AppColors.lightGray.withValues(alpha: _anim.value),
        ),
      ),
    );
  }
}

// ── Feed post card skeleton ───────────────────────────────────────────────────
class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            SkeletonLoader(width: 42, height: 42, radius: 21),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SkeletonLoader(width: 130, height: 12),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 10),
              ]),
            ),
            SkeletonLoader(width: 60, height: 28, radius: 14),
          ]),
        ),
        SkeletonLoader(height: 300, radius: 0),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonLoader(width: 180, height: 14),
            SizedBox(height: 8),
            SkeletonLoader(width: 120, height: 11),
          ]),
        ),
      ]),
    );
  }
}

// ── Store card skeleton ───────────────────────────────────────────────────────
class SkeletonStoreCard extends StatelessWidget {
  const SkeletonStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonLoader(width: 44, height: 44, radius: 22),
          SizedBox(height: 8),
          SkeletonLoader(width: 70, height: 10),
          SizedBox(height: 5),
          SkeletonLoader(width: 50, height: 8),
          SizedBox(height: 8),
          SkeletonLoader(width: 56, height: 22, radius: 11),
        ],
      ),
    );
  }
}
