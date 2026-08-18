/// Mirrors `public.achievements` left-joined with the current user's
/// `public.user_achievements` (FR-6.1–6.3).
class Achievement {
  final String id;
  final String key;
  final String name;
  final String description;
  final String? iconRef;
  final int sortOrder;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    this.iconRef,
    required this.sortOrder,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    key: json['key'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    iconRef: json['icon_ref'] as String?,
    sortOrder: json['sort_order'] as int,
    unlockedAt: json['unlocked_at'] == null
        ? null
        : DateTime.parse(json['unlocked_at'] as String),
  );
}
