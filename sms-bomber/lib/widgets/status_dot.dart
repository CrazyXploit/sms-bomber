import 'package:flutter/material.dart';

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, required this.color, this.size = 10});
  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return SizedBox(
          width: widget.size * 2.2,
          height: widget.size * 2.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 2.2 * _c.value,
                height: widget.size * 2.2 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color
                      .withOpacity((1 - _c.value) * 0.35),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}