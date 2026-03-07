import 'package:dominium/domains/analytics/data/anomaly_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildAnomalyInsights gera score e ordena por severidade', () {
    final insights = buildAnomalyInsights(
      const AnomalySourceMetrics(
        recentPurchases: 1500,
        previousPurchases: 1000,
        averageCommitment: 0.82,
        impulseBursts: 2,
        recentIncome: 1000,
        openDebt: 1500,
      ),
    );

    expect(insights, isNotEmpty);
    expect(insights.first.score >= insights.last.score, isTrue);
    expect(insights.any((i) => i.type == AnomalyType.padrao), isTrue);
    expect(insights.any((i) => i.type == AnomalyType.riscoGradual), isTrue);
    expect(insights.any((i) => i.type == AnomalyType.autodestrutivo), isTrue);
  });

  test('buildAnomalyInsights não gera alerta quando métricas estão estáveis', () {
    final insights = buildAnomalyInsights(
      const AnomalySourceMetrics(
        recentPurchases: 500,
        previousPurchases: 500,
        averageCommitment: 0.4,
        impulseBursts: 0,
        recentIncome: 2000,
        openDebt: 500,
      ),
    );

    expect(insights, isEmpty);
  });
}
