/// Mirrors `public.v_metric_totals` (FR-4.1 rollup strip).
class MetricTotal {
  final String metricKey;
  final String displayName;
  final String unit;
  final String? iconRef;
  final double total;

  const MetricTotal({
    required this.metricKey,
    required this.displayName,
    required this.unit,
    this.iconRef,
    required this.total,
  });

  factory MetricTotal.fromJson(Map<String, dynamic> json) => MetricTotal(
    metricKey: json['metric_key'] as String,
    displayName: json['display_name'] as String,
    unit: json['unit'] as String,
    iconRef: json['icon_ref'] as String?,
    total: (json['total'] as num).toDouble(),
  );

  String get formatted {
    final isWhole = total == total.roundToDouble();
    final value = isWhole ? total.toStringAsFixed(0) : total.toStringAsFixed(1);
    return '$value$unit $displayName';
  }
}
