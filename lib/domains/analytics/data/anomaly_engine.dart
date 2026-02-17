class AnomalySourceMetrics {
  const AnomalySourceMetrics({
    required this.recentPurchases,
    required this.previousPurchases,
    required this.averageCommitment,
    required this.impulseBursts,
    required this.recentIncome,
    required this.openDebt,
  });

  final double recentPurchases;
  final double previousPurchases;
  final double averageCommitment;
  final int impulseBursts;
  final double recentIncome;
  final double openDebt;
}

enum AnomalyType { padrao, riscoGradual, autodestrutivo }

enum AnomalyAction { abrirDividasCartao, iniciarContencao, abrirOraculo }

class AnomalyInsight {
  const AnomalyInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.score,
    required this.action,
    required this.actionLabel,
  });

  final AnomalyType type;
  final String title;
  final String description;
  final int score;
  final AnomalyAction action;
  final String actionLabel;

  String get typeLabel => switch (type) {
        AnomalyType.padrao => 'Padrão',
        AnomalyType.riscoGradual => 'Risco gradual',
        AnomalyType.autodestrutivo => 'Autodestrutivo',
      };
}

List<AnomalyInsight> buildAnomalyInsights(AnomalySourceMetrics metrics) {
  final anomalies = <AnomalyInsight>[];

  if (metrics.previousPurchases > 0) {
    final change = ((metrics.recentPurchases - metrics.previousPurchases) / metrics.previousPurchases) * 100;
    if (change >= 20) {
      anomalies.add(
        AnomalyInsight(
          type: AnomalyType.padrao,
          title: 'Mudança abrupta de padrão de compra',
          description: 'Gastos cresceram ${change.toStringAsFixed(0)}% nos últimos 12 dias.',
          score: change.clamp(20, 100).round(),
          action: AnomalyAction.abrirOraculo,
          actionLabel: 'Abrir Oráculo',
        ),
      );
    }
  }

  if (metrics.averageCommitment >= 0.78) {
    anomalies.add(
      AnomalyInsight(
        type: AnomalyType.riscoGradual,
        title: 'Comprometimento médio elevado',
        description: 'Limite médio comprometido em ${(metrics.averageCommitment * 100).toStringAsFixed(0)}%.',
        score: (metrics.averageCommitment * 100).clamp(0, 100).round(),
        action: AnomalyAction.abrirDividasCartao,
        actionLabel: 'Abrir Dívidas',
      ),
    );
  }

  if (metrics.impulseBursts > 0) {
    anomalies.add(
      AnomalyInsight(
        type: AnomalyType.autodestrutivo,
        title: 'Explosão de compras impulsivas',
        description: 'Detectadas ${metrics.impulseBursts} janela(s) com 4+ compras no mesmo dia.',
        score: (70 + metrics.impulseBursts * 10).clamp(0, 100).round(),
        action: AnomalyAction.iniciarContencao,
        actionLabel: 'Iniciar contenção',
      ),
    );
  }

  if (metrics.recentIncome > 0 && metrics.openDebt > metrics.recentIncome * 1.2) {
    final overload = (metrics.openDebt / metrics.recentIncome) * 100;
    anomalies.add(
      AnomalyInsight(
        type: AnomalyType.riscoGradual,
        title: 'Dívida aberta acima da renda recente',
        description: 'Dívida em ${overload.toStringAsFixed(0)}% da renda dos últimos 30 dias.',
        score: overload.clamp(0, 100).round(),
        action: AnomalyAction.abrirDividasCartao,
        actionLabel: 'Ver dívida',
      ),
    );
  }

  anomalies.sort((a, b) => b.score.compareTo(a.score));
  return anomalies;
}
