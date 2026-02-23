import 'package:dominium/domains/progression/data/progression_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projectLevelFromScenario aplica bônus e penalidade por risco', () {
    expect(
      projectLevelFromScenario(currentLevel: 5, disciplineDelta: 16, riskScore: 30),
      8,
    );

    expect(
      projectLevelFromScenario(currentLevel: 5, disciplineDelta: 0, riskScore: 90),
      4,
    );
  });

  test('projectedTitleByRiskAndLevel prioriza título crítico por risco', () {
    expect(
      projectedTitleByRiskAndLevel(riskScore: 92, projectedLevel: 9),
      'Devedor em Guerra',
    );
    expect(
      projectedTitleByRiskAndLevel(riskScore: 20, projectedLevel: 8),
      'Arquiduque do Cofre',
    );
  });
}
