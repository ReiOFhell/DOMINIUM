class UnifiedDecisionScenario {
  const UnifiedDecisionScenario({
    required this.name,
    required this.monthlyCardSpendDelta,
    required this.monthlyIncomeDelta,
    required this.monthlyFixedCostDelta,
    required this.monthlyCardPaymentExtra,
    required this.monthlyDirectDebtPaymentExtra,
    required this.disciplineDelta,
  });

  final String name;
  final double monthlyCardSpendDelta;
  final double monthlyIncomeDelta;
  final double monthlyFixedCostDelta;
  final double monthlyCardPaymentExtra;
  final double monthlyDirectDebtPaymentExtra;
  final int disciplineDelta;

  @override
  bool operator ==(Object other) {
    return other is UnifiedDecisionScenario &&
        other.name == name &&
        other.monthlyCardSpendDelta == monthlyCardSpendDelta &&
        other.monthlyIncomeDelta == monthlyIncomeDelta &&
        other.monthlyFixedCostDelta == monthlyFixedCostDelta &&
        other.monthlyCardPaymentExtra == monthlyCardPaymentExtra &&
        other.monthlyDirectDebtPaymentExtra == monthlyDirectDebtPaymentExtra &&
        other.disciplineDelta == disciplineDelta;
  }

  @override
  int get hashCode => Object.hash(
        name,
        monthlyCardSpendDelta,
        monthlyIncomeDelta,
        monthlyFixedCostDelta,
        monthlyCardPaymentExtra,
        monthlyDirectDebtPaymentExtra,
        disciplineDelta,
      );
}

class UnifiedDecisionSnapshot {
  const UnifiedDecisionSnapshot({
    required this.horizonMonths,
    required this.projectedRealCash,
    required this.projectedObligations,
    required this.riskScore,
    required this.riskLabel,
    required this.projectedLevel,
    required this.projectedTitle,
  });

  final int horizonMonths;
  final double projectedRealCash;
  final double projectedObligations;
  final int riskScore;
  final String riskLabel;
  final int projectedLevel;
  final String projectedTitle;
}

class UnifiedDecisionProjection {
  const UnifiedDecisionProjection({
    required this.scenario,
    required this.snapshots,
  });

  final UnifiedDecisionScenario scenario;
  final List<UnifiedDecisionSnapshot> snapshots;
}
