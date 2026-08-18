import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/achievement.dart';

/// `achievements` (global catalog) merged client-side with the current
/// user's `user_achievements` (FR-6.1–6.3). Two queries rather than a
/// PostgREST embed because the join direction we need — "every catalog row,
/// annotated with whether *I* unlocked it" — isn't a foreign-key embed
/// PostgREST can express in one call; both queries are RLS-scoped (0010).
class AchievementRepository {
  AchievementRepository(this._client);
  final SupabaseClient _client;

  Future<List<Achievement>> getAchievements() async {
    final catalog = await _client
        .from('achievements')
        .select()
        .order('sort_order');
    final unlocked = await _client
        .from('user_achievements')
        .select('achievement_id, unlocked_at');

    final unlockedMap = <String, String>{
      for (final row in unlocked as List)
        (row as Map<String, dynamic>)['achievement_id'] as String:
            row['unlocked_at'] as String,
    };

    return (catalog as List).map((row) {
      final json = Map<String, dynamic>.from(row as Map<String, dynamic>);
      json['unlocked_at'] = unlockedMap[json['id']];
      return Achievement.fromJson(json);
    }).toList();
  }
}
