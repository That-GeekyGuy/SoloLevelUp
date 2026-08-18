import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

/// One Rise Rating stat tile (FR-5.2): label, icon, score, signed delta,
/// progress bar. Used for both the Overall hero tile and the five stat grid
/// tiles on the Rise Rating screen.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.delta,
    required this.color,
    this.large = false,
  });

  final String label;
  final IconData icon;
  final double value;
  final double delta;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final deltaText = delta >= 0
        ? '+${delta.round()}'
        : delta.round().toString();

    return GlassCard(
      borderColor: large ? color.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: large ? 22 : 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: large ? 12 : 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.round().toString(),
                style:
                    (large
                            ? Theme.of(context).textTheme.displayLarge
                            : Theme.of(context).textTheme.headlineMedium)
                        ?.copyWith(color: color),
              ),
              const SizedBox(width: 8),
              Text(
                deltaText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: delta >= 0 ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: large ? 12 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              minHeight: large ? 8 : 6,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
