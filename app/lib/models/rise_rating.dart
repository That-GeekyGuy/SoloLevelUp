/// One lens (Day 1 / Current / Potential) of the Rise Rating (FR-5.1–5.2).
class RiseRatingLens {
  final double overall;
  final double wisdom;
  final double strength;
  final double focus;
  final double confidence;
  final double discipline;

  const RiseRatingLens({
    required this.overall,
    required this.wisdom,
    required this.strength,
    required this.focus,
    required this.confidence,
    required this.discipline,
  });

  Map<String, double> get asStatMap => {
    'wisdom': wisdom,
    'strength': strength,
    'focus': focus,
    'confidence': confidence,
    'discipline': discipline,
  };
}

/// Mirrors one row of `public.v_rise_rating` (all three lenses at once).
class RiseRating {
  final RiseRatingLens day1;
  final RiseRatingLens current;
  final RiseRatingLens potential;

  const RiseRating({
    required this.day1,
    required this.current,
    required this.potential,
  });

  factory RiseRating.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num).toDouble();
    return RiseRating(
      day1: RiseRatingLens(
        overall: d('day1_overall'),
        wisdom: d('day1_wisdom'),
        strength: d('day1_strength'),
        focus: d('day1_focus'),
        confidence: d('day1_confidence'),
        discipline: d('day1_discipline'),
      ),
      current: RiseRatingLens(
        overall: d('current_overall'),
        wisdom: d('current_wisdom'),
        strength: d('current_strength'),
        focus: d('current_focus'),
        confidence: d('current_confidence'),
        discipline: d('current_discipline'),
      ),
      potential: RiseRatingLens(
        overall: d('potential_overall'),
        wisdom: d('potential_wisdom'),
        strength: d('potential_strength'),
        focus: d('potential_focus'),
        confidence: d('potential_confidence'),
        discipline: d('potential_discipline'),
      ),
    );
  }

  double deltaFor(String statKey, RiseRatingLens lens) {
    final base = statKey == 'overall' ? day1.overall : day1.asStatMap[statKey]!;
    final value = statKey == 'overall'
        ? lens.overall
        : lens.asStatMap[statKey]!;
    return value - base;
  }
}
