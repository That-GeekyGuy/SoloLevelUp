/// Mirrors `public.learning_items` left-joined with the current user's
/// `public.user_learning_progress` (FR-7.1–7.5, SRS §5.7.1).
class LearningItem {
  final String id;
  final String title;
  final String author;
  final String? coverRef;
  final List<String> category;
  final double? rating;
  final int ratingCount;
  final String summaryText;
  final int? estReadMinutes;
  final String status; // recommended | in_progress | done
  final double progressPct;

  const LearningItem({
    required this.id,
    required this.title,
    required this.author,
    this.coverRef,
    required this.category,
    this.rating,
    required this.ratingCount,
    required this.summaryText,
    this.estReadMinutes,
    required this.status,
    required this.progressPct,
  });

  factory LearningItem.fromJson(Map<String, dynamic> json) => LearningItem(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    coverRef: json['cover_ref'] as String?,
    category: List<String>.from(json['category'] as List? ?? const []),
    rating: (json['rating'] as num?)?.toDouble(),
    ratingCount: json['rating_count'] as int? ?? 0,
    summaryText: json['summary_text'] as String,
    estReadMinutes: json['est_read_minutes'] as int?,
    status: (json['status'] as String?) ?? 'recommended',
    progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0,
  );
}
