import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/rewards_service.dart';

/// Wrap any screen with this to get floating "+20 XP" animations.
class RewardsToastLayer extends StatefulWidget {
  final Widget child;
  const RewardsToastLayer({super.key, required this.child});

  @override
  State<RewardsToastLayer> createState() => _RewardsToastLayerState();
}

class _RewardsToastLayerState extends State<RewardsToastLayer> {
  final List<_ToastItem> _items = [];
  StreamSubscription<RewardEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = RewardsService.instance.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(RewardEvent e) {
    if (!mounted) return;
    final item = _ToastItem(event: e);
    setState(() => _items.add(item));
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _items.remove(item));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_items.isNotEmpty)
        Positioned(
          bottom: 120,
          left: 0, right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _items
                .map((i) => _ToastWidget(key: ValueKey(i), item: i))
                .toList(),
          ),
        ),
    ]);
  }
}

class _ToastItem {
  final RewardEvent event;
  _ToastItem({required this.event});
}

class _ToastWidget extends StatefulWidget {
  final _ToastItem item;
  const _ToastWidget({super.key, required this.item});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _slide;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _slide = Tween(begin: 0.0, end: -40.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade  = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e     = widget.item.event;
    final isXp  = e.isXp;
    final color = isXp ? AppColors.accent : AppColors.gold;
    final icon  = isXp ? '⭐' : '🪙';
    final label = '+${e.amount} ${isXp ? 'XP' : 'Coins'}';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(
          opacity: _fade.value,
          child: Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.montserrat(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
