import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../data/repositories/achievement_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/learning_repository.dart';
import '../data/repositories/quest_repository.dart';
import '../data/repositories/rise_rating_repository.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/learning_item.dart';
import '../models/metric_total.dart';
import '../models/quest_today.dart';
import '../models/rise_rating.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);
final questRepositoryProvider = Provider(
  (ref) => QuestRepository(ref.watch(supabaseClientProvider)),
);
final riseRatingRepositoryProvider = Provider(
  (ref) => RiseRatingRepository(ref.watch(supabaseClientProvider)),
);
final achievementRepositoryProvider = Provider(
  (ref) => AchievementRepository(ref.watch(supabaseClientProvider)),
);
final learningRepositoryProvider = Provider(
  (ref) => LearningRepository(ref.watch(supabaseClientProvider)),
);

/// Drives the auth gate in app_router.dart (FR-1.2: same account, all
/// platforms — this stream is what makes sign-in state reactive without a
/// manual refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

final activeChallengeProvider = FutureProvider<Challenge?>((ref) async {
  return ref.watch(questRepositoryProvider).getActiveChallenge();
});

/// Today screen (FR-3.3–3.4). `.refresh()` (via ref.invalidate) is called
/// after every swipe so the list, tab counts, and metric strip stay in sync
/// with what the server just recomputed.
final todayQuestsProvider = FutureProvider<List<QuestToday>>((ref) async {
  return ref.watch(questRepositoryProvider).getTodayQuests();
});

final metricTotalsProvider = FutureProvider<List<MetricTotal>>((ref) async {
  final challenge = await ref.watch(activeChallengeProvider.future);
  if (challenge == null) return [];
  return ref.watch(questRepositoryProvider).getMetricTotals(challenge.id);
});

final riseRatingProvider = FutureProvider<RiseRating?>((ref) async {
  return ref.watch(riseRatingRepositoryProvider).getRiseRating();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  return ref.watch(achievementRepositoryProvider).getAchievements();
});

final learningItemsProvider = FutureProvider<List<LearningItem>>((ref) async {
  return ref.watch(learningRepositoryProvider).getLearningItems();
});
