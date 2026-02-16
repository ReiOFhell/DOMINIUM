class MonthlyReport {
  MonthlyReport({
    required this.id,
    required this.monthKey,
    required this.generatedAt,
    required this.victories,
    required this.failures,
    required this.currentRisk,
    required this.tacticalPlan,
    required this.projectedNet,
  });

  final String id;
  final String monthKey;
  final DateTime generatedAt;
  final List<String> victories;
  final List<String> failures;
  final String currentRisk;
  final List<String> tacticalPlan;
  final double projectedNet;

  Map<String, dynamic> toMap() => {
        'id': id,
        'monthKey': monthKey,
        'generatedAt': generatedAt.toIso8601String(),
        'victories': victories,
        'failures': failures,
        'currentRisk': currentRisk,
        'tacticalPlan': tacticalPlan,
        'projectedNet': projectedNet,
      };

  factory MonthlyReport.fromMap(Map map) => MonthlyReport(
        id: map['id'] as String,
        monthKey: map['monthKey'] as String,
        generatedAt: DateTime.parse(map['generatedAt'] as String),
        victories: (map['victories'] as List?)?.cast<String>() ?? const [],
        failures: (map['failures'] as List?)?.cast<String>() ?? const [],
        currentRisk: map['currentRisk'] as String? ?? 'Estável',
        tacticalPlan: (map['tacticalPlan'] as List?)?.cast<String>() ?? const [],
        projectedNet: (map['projectedNet'] as num?)?.toDouble() ?? 0,
      );
}
