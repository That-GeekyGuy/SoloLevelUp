import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/learning_item.dart';
import '../../providers/providers.dart';
import 'learning_reader_screen.dart';

/// FR-7.1–7.2: Recommended / Done tabs over the Daily Learning catalog
/// (§5.7.1 — original, Claude-generated summaries, not licensed content).
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
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
    final itemsAsync = ref.watch(learningItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Learning')),
      body: itemsAsync.when(
        data: (items) {
          final categories = items.expand((i) => i.category).toSet().toList()
            ..sort();
          final tab = _tabController.index == 0
              ? items.where((i) => i.status != 'done')
              : items.where((i) => i.status == 'done');
          final filtered = _categoryFilter == null
              ? tab.toList()
              : tab.where((i) => i.category.contains(_categoryFilter)).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(learningItemsProvider),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.riseSecondary,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Recommended'),
                    Tab(text: 'Done'),
                  ],
                ),
                if (categories.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: _categoryFilter == null,
                          onTap: () => setState(() => _categoryFilter = null),
                        ),
                        const SizedBox(width: 8),
                        for (final c in categories) ...[
                          _CategoryChip(
                            label: c,
                            selected: _categoryFilter == c,
                            onTap: () => setState(() => _categoryFilter = c),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Nothing here yet.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _LearningCard(item: filtered[i]),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load Daily Learning: $e')),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surfaceRaised,
      selectedColor: AppColors.risePrimary.withValues(alpha: 0.35),
      side: const BorderSide(color: AppColors.surfaceBorder),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.item});
  final LearningItem item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LearningReaderScreen(item: item)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: AppColors.riseGradient),
            ),
            child: const Icon(Icons.menu_book, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.rating != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating!.toStringAsFixed(1)} (${item.ratingCount})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  item.author,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (item.status == 'in_progress')
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: item.progressPct / 100,
                strokeWidth: 3,
              ),
            )
          else if (item.status == 'done')
            const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    );
  }
}
