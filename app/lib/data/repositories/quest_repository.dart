import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/challenge.dart';
import '../../models/metric_total.dart';
import '../../models/quest_today.dart';

const _uuid = Uuid();

/// Wraps the Today-screen data path: `ensure_today_entries()` +
/// `v_today_quests` + `log_quest_action()` (supabase/migrations/0005,
/// 0006). This is also exactly what the MCP `get_today`/`complete_quest`/
/// `skip_quest` tools (FR-9.1–9.2) will call, so app and MCP writes land
/// through the identical path (AR-9).
class QuestRepository {
  QuestRepository(this._client);
  final SupabaseClient _client;

  Future<Challenge?> getActiveChallenge() async {
    final row = await _client
        .from('challenges')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Challenge.fromJson(row);
  }

  Future<List<QuestToday>> getTodayQuests() async {
    await _client.rpc('ensure_today_entries');
    final rows = await _client.from('v_today_quests').select();
    return (rows as List)
        .map((r) => QuestToday.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MetricTotal>> getMetricTotals(String challengeId) async {
    final rows = await _client
        .from('v_metric_totals')
        .select()
        .eq('challenge_id', challengeId);
    return (rows as List)
        .map((r) => MetricTotal.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// action: 'done' | 'skipped' | 'undo'. Generates a fresh idempotency key
  /// per logical action so offline retries (AR-5) can't double-apply, while
  /// still letting the caller retry the exact same call safely.
  Future<void> logQuestAction(
    String questId,
    String action, {
    String? clientWriteId,
  }) {
    return _client.rpc(
      'log_quest_action',
      params: {
        'p_quest_id': questId,
        'p_action': action,
        'p_client_write_id': clientWriteId ?? _uuid.v4(),
      },
    );
  }

  Future<void> createQuest({
    required String title,
    String? description,
    required Map<String, dynamic> repeatRule,
    required int difficulty,
    required String statCategory,
    String? linkedMetricId,
    double? metricIncrement,
  }) {
    return _client.from('quests').insert({
      'user_id': _client.auth.currentUser!.id,
      'title': title,
      'description': description,
      'repeat_rule': repeatRule,
      'difficulty': difficulty,
      'stat_category': statCategory,
      'linked_metric_id': linkedMetricId,
      'metric_increment': metricIncrement,
    });
  }

  Future<void> archiveQuest(String questId) {
    return _client
        .from('quests')
        .update({
          'is_active': false,
          'archived_at': DateTime.now().toIso8601String(),
        })
        .eq('id', questId);
  }
}
