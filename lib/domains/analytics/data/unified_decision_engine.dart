import 'package:dominium/domains/analytics/data/unified_decision.dart';
import 'package:dominium/domains/progression/data/progression_engine.dart';

class UnifiedDecisionBase {
  const UnifiedDecisionBase({
    required this.realCash,
    required this.cardDebt,
    required this.directDebt,
    required this.averageMonthlyNet,
    required this.currentLevel,
  });

  final double realCash;
  final double cardDebt;
  final double directDebt;
  final double averageMonthlyNet;
  final int currentLevel;
}

UnifiedDecisionProjection simulateUnifiedDecision({
  required UnifiedDecisionScenario scenario,
  required UnifiedDecisionBase base,
  List<int> horizons = const [3, 6, 12],
}) {
  UnifiedDecisionSnapshot compute(int months) {
    var cardDebt = base.cardDebt;
    var directDebt = base.directDebt;
    var cash = base.realCash;

    for (var i = 0; i < months; i++) {
      cardDebt = (cardDebt + scenario.monthlyCardSpendDelta - scenario.monthlyCardPaymentExtra)
          .clamp(0.0, double.infinity)
          .toDouble();
      directDebt = (directDebt - scenario.monthlyDirectDebtPaymentExtra)
          .clamp(0.0, double.infinity)
          .toDouble();

      cash += base.averageMonthlyNet + scenario.monthlyIncomeDelta - scenario.monthlyFixedCostDelta;
      cash -= scenario.monthlyCardPaymentExtra + scenario.monthlyDirectDebtPaymentExtra;
    }

    final obligations = cardDebt + directDebt;
    final denominator = cash <= 0 ? 1.0 : cash;
    final riskScore = ((obligations / denominator) * 100).clamp(0, 100).round();
    final riskLabel = riskScore >= 85
        ? 'Crítico'
        : riskScore >= 65
            ? 'Alto'
            : riskScore >= 40
                ? 'Moderado'
                : 'Controlado';

    final projectedLevel = projectLevelFromScenario(
      currentLevel: base.currentLevel,
      disciplineDelta: scenario.disciplineDelta,
      riskScore: riskScore,
    );

    return UnifiedDecisionSnapshot(
      horizonMonths: months,
      projectedRealCash: cash,
      projectedObligations: obligations,
      riskScore: riskScore,
      riskLabel: riskLabel,
      projectedLevel: projectedLevel,
      projectedTitle: projectedTitleByRiskAndLevel(riskScore: riskScore, projectedLevel: projectedLevel),
    );
  }

  return UnifiedDecisionProjection(
    scenario: scenario,
    snapshots: [for (final months in horizons) compute(months)],
  );
}
