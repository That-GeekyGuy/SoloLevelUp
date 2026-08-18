/// Mirrors `public.challenges` (FR-2.1–2.5).
class Challenge {
  final String id;
  final DateTime startDate;
  final int lengthDays;
  final String status; // active | completed | reset

  const Challenge({
    required this.id,
    required this.startDate,
    required this.lengthDays,
    required this.status,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: json['id'] as String,
    startDate: DateTime.parse(json['start_date'] as String),
    lengthDays: json['length_days'] as int,
    status: json['status'] as String,
  );

  int get currentDay {
    final today = DateTime.now();
    final elapsed = DateTime(today.year, today.month, today.day)
        .difference(DateTime(startDate.year, startDate.month, startDate.day))
        .inDays;
    return (elapsed + 1).clamp(1, lengthDays);
  }

  int get currentWeek => ((currentDay - 1) ~/ 7) + 1;

  bool get isFirstDayOfWeek => ((currentDay - 1) % 7) == 0;
}
