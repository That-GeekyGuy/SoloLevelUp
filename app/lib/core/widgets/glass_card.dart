import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The recurring card surface across every screen — a raised, softly
/// bordered panel. Named "glass" for the subtle gradient sheen, not a blur
/// (blur-per-card is expensive across three render targets; the sheen gets
/// the same read at a fraction of the cost).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.surfaceBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceRaised.withValues(alpha: 0.9),
            AppColors.surface.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: card,
    );
  }
}
