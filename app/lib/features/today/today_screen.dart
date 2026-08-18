import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/challenge.dart';
import '../../models/metric_total.dart';
import '../../models/quest_today.dart';
import '../../providers/providers.dart';
import 'widgets/quest_card.dart';

/// FR-2.2–2.3, FR-3.3–3.4, FR-4.1: the home screen — day counter, metrics
/// rollup strip, and the To-dos / Done / Skipped quest tabs.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _act(String questId, String action) async {
    await ref.read(questRepositoryProvider).logQuestAction(questId, action);
    ref.invalidate(todayQuestsProvider);
    ref.invalidate(metricTotalsProvider);
    ref.invalidate(riseRatingProvider);
    ref.invalidate(achievementsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(activeChallengeProvider);
    final questsAsync = ref.watch(todayQuestsProvider);
    final metricsAsync = ref.watch(metricTotalsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayQuestsProvider);
            ref.invalidate(metricTotalsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: challengeAsync.when(
                    data: (challenge) => _Header(challenge: challenge),
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Could not load challenge: $e'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: metricsAsync.when(
                    data: (metrics) => _MetricStrip(metrics: metrics),
                    loading: () => const SizedBox(height: 40),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: questsAsync.maybeWhen(
                  data: (quests) => _QuestTabs(
                    controller: _tabController,
                    todo: quests
                        .where((q) => q.todayStatus == 'pending')
                        .length,
                    done: quests.where((q) => q.todayStatus == 'done').length,
                    skipped: quests
                        .where((q) => q.todayStatus == 'skipped')
                        .length,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
              questsAsync.when(
                data: (quests) {
                  final filtered = _filterFor(quests, _tabController.index);
                  if (filtered.isEmpty) {
                    return const SliverPadding(
                      padding: EdgeInsets.only(top: 40),
                      sliver: SliverToBoxAdapter(
                        child: Center(child: Text('Nothing here yet.')),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final q = filtered[i];
                        return QuestCard(
                          quest: q,
                          onComplete: () => _act(q.questId, 'done'),
                          onSkip: () => _act(q.questId, 'skipped'),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SliverPadding(
                  padding: EdgeInsets.only(top: 60),
                  sliver: SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Could not load today\'s quests: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<QuestToday> _filterFor(List<QuestToday> quests, int tabIndex) {
    final status = switch (tabIndex) {
      1 => 'done',
      2 => 'skipped',
      _ => 'pending',
    };
    return quests.where((q) => q.todayStatus == status).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challenge});
  final Challenge? challenge;

  @override
  Widget build(BuildContext context) {
    final challenge = this.challenge;
    if (challenge == null) {
      return const Text('No active challenge yet.');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day ${challenge.currentDay}/${challenge.lengthDays}',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 4),
              Text(
                challenge.isFirstDayOfWeek
                    ? 'First day of week ${challenge.currentWeek}. Let\'s do it.'
                    : 'Week ${challenge.currentWeek}. Keep going.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        // Day navigation is a placeholder for now — v_today_quests (SRS
        // §5) only serves *today*; reviewing past/future days (FR-2.3)
        // needs a date-parameterized read path, tracked as a follow-up.
        Opacity(
          opacity: 0.35,
          child: Row(
            children: const [
              Icon(Icons.chevron_left),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics});
  final List<MetricTotal> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = metrics[i];
          return Chip(
            backgroundColor: AppColors.surfaceRaised,
            side: const BorderSide(color: AppColors.surfaceBorder),
            label: Text(m.formatted),
          );
        },
      ),
    );
  }
}

class _QuestTabs extends StatelessWidget {
  const _QuestTabs({
    required this.controller,
    required this.todo,
    required this.done,
    required this.skipped,
  });

  final TabController controller;
  final int todo;
  final int done;
  final int skipped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.riseSecondary,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        tabs: [
          Tab(text: 'To-dos ($todo)'),
          Tab(text: 'Done ($done)'),
          Tab(text: 'Skipped ($skipped)'),
        ],
      ),
    );
  }
}
