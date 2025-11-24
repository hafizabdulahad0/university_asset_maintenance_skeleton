import 'package:flutter/widgets.dart';

class HoverScale extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final Duration duration;

  const HoverScale({
    super.key,
    required this.child,
    this.hoverScale = 1.03,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final scale = _hovering ? widget.hoverScale : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}

