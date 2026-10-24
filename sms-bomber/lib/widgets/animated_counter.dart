import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Color color;
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Text(
        '$value',
        key: ValueKey(value),
        style: style.copyWith(color: color),
      ),
    );
  }
}