int projectLevelFromScenario({
  required int currentLevel,
  required int disciplineDelta,
  required int riskScore,
}) {
  final levelShift = (disciplineDelta ~/ 8) + (riskScore <= 45 ? 1 : 0) - (riskScore >= 85 ? 1 : 0);
  return (currentLevel + levelShift).clamp(1, 99).toInt();
}

String projectedTitleByRiskAndLevel({required int riskScore, required int projectedLevel}) {
  if (riskScore >= 85) return 'Devedor em Guerra';
  if (projectedLevel >= 8) return 'Arquiduque do Cofre';
  if (projectedLevel >= 6) return 'Executor do Orçamento';
  if (projectedLevel >= 4) return 'Conselheiro do Caixa';
  return 'Regente em Formação';
}
