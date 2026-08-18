/// Mirrors `public.v_today_quests` (supabase/migrations/0005_views.sql).
class QuestToday {
  final String questId;
  final String title;
  final String? description;
  final String? iconRef;
  final Map<String, dynamic> repeatRule;
  final int difficulty;
  final String statCategory;
  final String todayStatus; // done | skipped | pending
  final String? todayEntryId;
  final int streakLen;

  const QuestToday({
    required this.questId,
    required this.title,
    this.description,
    this.iconRef,
    required this.repeatRule,
    required this.difficulty,
    required this.statCategory,
    required this.todayStatus,
    this.todayEntryId,
    required this.streakLen,
  });

  factory QuestToday.fromJson(Map<String, dynamic> json) => QuestToday(
    questId: json['quest_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    iconRef: json['icon_ref'] as String?,
    repeatRule: Map<String, dynamic>.from(json['repeat_rule'] as Map),
    difficulty: json['difficulty'] as int,
    statCategory: json['stat_category'] as String,
    todayStatus: json['today_status'] as String,
    todayEntryId: json['today_entry_id'] as String?,
    streakLen: json['streak_len'] as int,
  );

  String get repeatLabel {
    switch (repeatRule['type']) {
      case 'everyday':
        return 'Everyday';
      case 'n_times_per_week':
        return '${repeatRule['n']} times a week';
      case 'specific_weekdays':
        return 'Specific days';
      default:
        return '';
    }
  }
}
