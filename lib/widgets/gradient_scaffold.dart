import 'package:flutter/material.dart';
import 'hover_scale.dart';

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Gradient? gradient;
  final Widget? floatingActionButton;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.gradient,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? const LinearGradient(
      colors: [Color(0xFF0EA5E9), Color(0xFF9333EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton == null
          ? null
          : HoverScale(child: floatingActionButton!),
      body: Container(
        decoration: BoxDecoration(gradient: g),
        child: SafeArea(child: body),
      ),
    );
  }
}

