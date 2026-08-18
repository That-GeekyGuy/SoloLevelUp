import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/quest_today.dart';

/// FR-3.3: swipe right to complete, swipe left to skip. Dismissible gives
/// touch platforms (Web mobile, Android) the swipe gesture; the two
/// trailing icon buttons are the keyboard/mouse-operable equivalent
/// required on Windows and desktop Web by NFR-4.2, so the same action is
/// always reachable without a drag gesture.
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onComplete,
    required this.onSkip,
  });

  final QuestToday quest;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final statColor = AppColors.forStat(quest.statCategory);

    return Dismissible(
      key: ValueKey(quest.questId),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.success,
        icon: Icons.check_circle,
        label: 'Complete',
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.textMuted,
        icon: Icons.arrow_forward,
        label: 'Skip',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onSkip();
        }
        return false; // state comes back from the server; don't remove locally
      },
      child: GlassCard(
        borderColor: statColor.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(quest.statCategory), color: statColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (quest.description != null)
                        Text(
                          quest.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: AppColors.emberAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'Streak ${quest.streakLen} day${quest.streakLen == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.repeat, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  quest.repeatLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < quest.difficulty ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppColors.warning,
                    );
                  }),
                ),
              ],
            ),
            if (quest.todayStatus == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSkip,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Complete'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [Icon(icon, color: color), const SizedBox(width: 8), Text(label)]
            : [Text(label), const SizedBox(width: 8), Icon(icon, color: color)],
      ),
    );
  }

  IconData _iconFor(String statCategory) {
    switch (statCategory) {
      case 'wisdom':
        return Icons.menu_book;
      case 'strength':
        return Icons.fitness_center;
      case 'focus':
        return Icons.center_focus_strong;
      case 'confidence':
        return Icons.shield;
      case 'discipline':
        return Icons.lock_clock;
      default:
        return Icons.star;
    }
  }
}
