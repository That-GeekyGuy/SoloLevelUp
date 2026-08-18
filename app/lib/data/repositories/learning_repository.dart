import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/learning_item.dart';

/// `learning_items` (global catalog, §5.7.1) merged with the current user's
/// `user_learning_progress` (FR-7.1–7.5).
class LearningRepository {
  LearningRepository(this._client);
  final SupabaseClient _client;

  Future<List<LearningItem>> getLearningItems() async {
    final catalog = await _client
        .from('learning_items')
        .select()
        .eq('is_active', true)
        .order('created_at');
    final progress = await _client.from('user_learning_progress').select();

    final progressMap = <String, Map<String, dynamic>>{
      for (final row in progress as List)
        (row as Map<String, dynamic>)['learning_item_id'] as String: row,
    };

    return (catalog as List).map((row) {
      final json = Map<String, dynamic>.from(row as Map<String, dynamic>);
      final p = progressMap[json['id']];
      if (p != null) {
        json['status'] = p['status'];
        json['progress_pct'] = p['progress_pct'];
      }
      return LearningItem.fromJson(json);
    }).toList();
  }

  /// FR-7.3/7.5: persist reader scroll progress; marks 'done' at 100%
  /// (FR-7.4) via an upsert so it works whether or not a progress row
  /// exists yet.
  Future<void> updateProgress({
    required String learningItemId,
    required double progressPct,
  }) {
    final status = progressPct >= 100
        ? 'done'
        : (progressPct > 0 ? 'in_progress' : 'recommended');
    return _client.from('user_learning_progress').upsert({
      'user_id': _client.auth.currentUser!.id,
      'learning_item_id': learningItemId,
      'status': status,
      'progress_pct': progressPct.clamp(0, 100),
      'last_read_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,learning_item_id');
  }
}
