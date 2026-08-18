import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/stat_tile.dart';
import '../../providers/providers.dart';

const _statIcons = {
  'wisdom': Icons.menu_book,
  'strength': Icons.fitness_center,
  'focus': Icons.center_focus_strong,
  'confidence': Icons.shield,
  'discipline': Icons.lock_clock,
};

/// FR-5.1–5.2: Current / Potential / Day 1 tabs over the six Rise Rating
/// stat tiles, all sourced from the single `v_rise_rating` row (§5.5).
class RiseRatingScreen extends ConsumerStatefulWidget {
  const RiseRatingScreen({super.key});

  @override
  ConsumerState<RiseRatingScreen> createState() => _RiseRatingScreenState();
}

class _RiseRatingScreenState extends ConsumerState<RiseRatingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratingAsync = ref.watch(riseRatingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Rise rating')),
      body: ratingAsync.when(
        data: (rating) {
          if (rating == null) {
            return const Center(child: Text('No active challenge yet.'));
          }
          final lens = switch (_tabController.index) {
            0 => rating.current,
            2 => rating.day1,
            _ => rating.potential,
          };
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(riseRatingProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                Text(
                  'Your rating reflects your current lifestyle. Increase it by completing quests daily.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.riseSecondary,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Current rating'),
                    Tab(text: 'Potential'),
                    Tab(text: 'Day 1 rating'),
                  ],
                ),
                const SizedBox(height: 20),
                StatTile(
                  label: 'Overall',
                  icon: Icons.auto_awesome,
                  value: lens.overall,
                  delta: rating.deltaFor('overall', lens),
                  color: AppColors.statOverall,
                  large: true,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: lens.asStatMap.entries.map((e) {
                    return StatTile(
                      label: _capitalize(e.key),
                      icon: _statIcons[e.key]!,
                      value: e.value,
                      delta: rating.deltaFor(e.key, lens),
                      color: AppColors.forStat(e.key),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load Rise Rating: $e')),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
