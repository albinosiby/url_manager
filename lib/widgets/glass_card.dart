import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? borderGradient;
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 18.0,
    this.opacity = 0.1,
    this.borderRadius = 20.0,
    this.borderColor,
    this.borderGradient,
    this.backgroundGradient,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderGradient = borderGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.04),
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: effectiveBorderGradient,
          ),
          padding: const EdgeInsets.all(1.2), // Border thickness
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              color: backgroundGradient == null
                  ? Colors.white.withOpacity(opacity)
                  : null,
              borderRadius: BorderRadius.circular(borderRadius - 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
