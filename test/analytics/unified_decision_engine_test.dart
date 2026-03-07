import 'package:dominium/domains/analytics/data/unified_decision.dart';
import 'package:dominium/domains/analytics/data/unified_decision_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulateUnifiedDecision projeta horizontes 3/6/12', () {
    final scenario = UnifiedDecisionScenario(
      name: 'Teste',
      monthlyCardSpendDelta: 200,
      monthlyIncomeDelta: 100,
      monthlyFixedCostDelta: 0,
      monthlyCardPaymentExtra: 150,
      monthlyDirectDebtPaymentExtra: 50,
      disciplineDelta: 8,
    );

    final projection = simulateUnifiedDecision(
      scenario: scenario,
      base: const UnifiedDecisionBase(
        realCash: 5000,
        cardDebt: 2000,
        directDebt: 1000,
        averageMonthlyNet: 300,
        currentLevel: 4,
      ),
    );

    expect(projection.snapshots.map((s) => s.horizonMonths), [3, 6, 12]);
    expect(projection.snapshots.every((s) => s.riskScore >= 0 && s.riskScore <= 100), isTrue);
  });

  test('regressão: cenário de contenção reduz obrigações no longo prazo', () {
    final scenario = UnifiedDecisionScenario(
      name: 'Contenção',
      monthlyCardSpendDelta: 0,
      monthlyIncomeDelta: 0,
      monthlyFixedCostDelta: 0,
      monthlyCardPaymentExtra: 300,
      monthlyDirectDebtPaymentExtra: 200,
      disciplineDelta: 12,
    );

    final projection = simulateUnifiedDecision(
      scenario: scenario,
      base: const UnifiedDecisionBase(
        realCash: 3000,
        cardDebt: 4000,
        directDebt: 2000,
        averageMonthlyNet: 400,
        currentLevel: 3,
      ),
    );

    final six = projection.snapshots.firstWhere((s) => s.horizonMonths == 6);
    final twelve = projection.snapshots.firstWhere((s) => s.horizonMonths == 12);
    expect(twelve.projectedObligations < six.projectedObligations, isTrue);
  });
}
