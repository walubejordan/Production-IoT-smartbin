import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../theme/app_colors.dart';

/// Glass card scaffold used across dashboards/lists.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppColors.cardRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
              width: 1,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x33FFFFFF),
                Color(0x0DFFFFFF),
              ],
            ),
            boxShadow: [
              // Soft UI: light on top-left
              BoxShadow(
                color: Colors.white.withOpacity(0.75),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(-4, -4),
              ),
              // Soft UI: dark on bottom-right
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(6, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

