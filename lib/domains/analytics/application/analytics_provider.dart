export 'package:dominium/domains/analytics/data/anomaly_engine.dart';
import 'dart:math';

import 'package:dominium/domains/analytics/data/possibility_result.dart';
import 'package:dominium/core/services/calculation_telemetry.dart';
import 'package:dominium/domains/analytics/data/anomaly_engine.dart';
import 'package:dominium/domains/analytics/data/unified_decision.dart';
import 'package:dominium/domains/analytics/data/unified_decision_engine.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class FlowPoint {
  FlowPoint(this.month, this.income, this.expense, this.balance);

  final DateTime month;
  final double income;
  final double expense;
  final double balance;
}

final flowFilterProvider = StateProvider<int>((_) => 6);

final monthlyFlowProvider = Provider<List<FlowPoint>>((ref) {
  final months = ref.watch(flowFilterProvider);
  final treasury = ref.watch(treasuryEntriesProvider);
  final debts = ref.watch(debtsProvider);
  final now = DateTime.now();
  final points = <FlowPoint>[];

  for (var i = months - 1; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final income = treasury
        .where((e) => e.received && e.date.year == month.year && e.date.month == month.month)
        .fold<double>(0, (s, e) => s + e.amount);
    final debtExpense = debts.fold<double>(0, (sum, card) {
      return sum + card.invoices
          .where((inv) => inv.dueDate.year == month.year && inv.dueDate.month == month.month)
          .fold<double>(0, (s, inv) => s + inv.paid);
    });
    final expense = debtExpense;
    points.add(FlowPoint(month, income, expense, income - expense));
  }

  return points;
});

final possibilityInputProvider = StateProvider<PossibilityInput>(
  (_) => PossibilityInput(
    fixedIncome: 0,
    variableIncome: 0,
    fixedCosts: 0,
    safeMarginPercent: 20,
    debtTarget: 0,
    installments: 1,
    interest: 0,
  ),
);

final possibilityScenariosProvider = Provider<List<PossibilityResult>>((ref) {
  final input = ref.watch(possibilityInputProvider);

  PossibilityResult build(ScenarioProfile profile, double riskTolerance) {
    final installments = max(1, input.installments);
    final monthlyRate = input.interest / 100;
    final installment = monthlyRate == 0
        ? input.debtTarget / installments
        : (input.debtTarget * monthlyRate) /
            (1 - 1 / pow(1 + monthlyRate, installments));

    final totalIncome = input.totalIncome;
    final minSafe = max(totalIncome * (input.safeMarginPercent / 100), input.fixedCosts * 0.05);
    final postFixed = totalIncome - input.fixedCosts - installment;
    final committed = totalIncome == 0 ? 1.0 : installment / totalIncome;
    final risk = committed > riskTolerance ? committed : committed * 0.8;

    final verdict = postFixed < minSafe
        ? AcquisitionVerdict.naoPode
        : (risk > 0.32 ? AcquisitionVerdict.podeComRisco : AcquisitionVerdict.pode);

    final reco = switch (verdict) {
      AcquisitionVerdict.pode => 'Pode executar. Prefira compra logo após fechamento para alongar fôlego.',
      AcquisitionVerdict.podeComRisco =>
        'Pode com risco. Reduza parcelas ou acrescente amortização mensal para evitar rotativo.',
      AcquisitionVerdict.naoPode =>
        'Não execute agora. Reforce caixa e reavalie em 1 ciclo de fatura.',
    };

    return PossibilityResult(
      profile: profile,
      verdict: verdict,
      installmentValue: installment,
      incomeCommittedPercent: committed * 100,
      postFixedSlack: postFixed,
      rotativeRisk: risk * 100,
      recommendation: reco,
    );
  }

  return [
    build(ScenarioProfile.conservador, 0.18),
    build(ScenarioProfile.realista, 0.25),
    build(ScenarioProfile.agressivo, 0.33),
  ];
});



final anomalyInsightsProvider = Provider<List<AnomalyInsight>>((ref) {
  final treasury = ref.watch(treasuryEntriesProvider);
  final debts = ref.watch(debtsProvider);
  final now = DateTime.now();

  final recentPurchases = debts
      .expand((c) => c.purchases)
      .where((p) => now.difference(p.date).inDays <= 12)
      .fold<double>(0, (s, p) => s + p.amount);
  final previousPurchases = debts
      .expand((c) => c.purchases)
      .where((p) {
        final d = now.difference(p.date).inDays;
        return d > 12 && d <= 24;
      })
      .fold<double>(0, (s, p) => s + p.amount);

  final avgCommit = debts.isEmpty
      ? 0.0
      : debts.fold<double>(0, (s, c) => s + c.committedLimitNow) / debts.length;

  final impulseBursts = debts
      .expand((c) => c.purchases)
      .where((p) => now.difference(p.date).inDays <= 7)
      .fold<Map<String, int>>({}, (map, p) {
        final key = '${p.date.year}-${p.date.month}-${p.date.day}';
        map[key] = (map[key] ?? 0) + 1;
        return map;
      })
      .values
      .where((count) => count >= 4)
      .length;

  final recentIncome = treasury
      .where((t) => t.received && now.difference(t.date).inDays <= 30)
      .fold<double>(0, (s, t) => s + t.amount);
  final recentOpenDebt = debts.fold<double>(0, (s, c) => s + c.openDebt);

  return buildAnomalyInsights(
    AnomalySourceMetrics(
      recentPurchases: recentPurchases,
      previousPurchases: previousPurchases,
      averageCommitment: avgCommit,
      impulseBursts: impulseBursts,
      recentIncome: recentIncome,
      openDebt: recentOpenDebt,
    ),
  );
});

final anomalyGroupedProvider = Provider<Map<AnomalyType, List<AnomalyInsight>>>((ref) {
  final grouped = <AnomalyType, List<AnomalyInsight>>{};
  for (final anomaly in ref.watch(anomalyInsightsProvider)) {
    grouped.putIfAbsent(anomaly.type, () => []).add(anomaly);
  }
  return grouped;
});

final anomalyAlertsProvider = Provider<List<String>>((ref) {
  final anomalies = ref.watch(anomalyInsightsProvider);
  if (anomalies.isEmpty) {
    return ['Sem anomalias críticas no momento. O padrão financeiro está sob controle.'];
  }

  return anomalies
      .map((a) => '[${a.typeLabel} • ${a.score}/100] ${a.description}')
      .toList();
});



final unifiedDecisionProjectionProvider =
    Provider.family<UnifiedDecisionProjection, UnifiedDecisionScenario>((ref, scenario) {
  final cards = ref.watch(debtsProvider);
  final directDebts = ref.watch(directDebtsProvider);
  final realCash = ref.watch(accountsProvider).totalBalance;
  final progression = ref.watch(progressionProvider);
  final flow = ref.watch(monthlyFlowProvider);

  final base = UnifiedDecisionBase(
    realCash: realCash,
    cardDebt: cards.fold<double>(0, (sum, card) => sum + card.openDebt),
    directDebt: directDebts.fold<double>(0, (sum, debt) => sum + debt.remainingValue),
    averageMonthlyNet:
        flow.isEmpty ? 0.0 : flow.fold<double>(0, (sum, point) => sum + point.balance) / flow.length,
    currentLevel: progression.level,
  );

  final projection = simulateUnifiedDecision(scenario: scenario, base: base);

  final hasInvalidNumber = projection.snapshots.any(
    (s) => s.projectedRealCash.isNaN || s.projectedObligations.isNaN,
  );

  if (hasInvalidNumber) {
    CalculationTelemetry.record(
      area: 'unified_decision',
      message: 'Projected numbers became NaN',
      context: {
        'scenario': scenario.name,
      },
    );
  }

  final inconsistent = projection.snapshots.any(
    (s) => s.riskScore < 40 && s.projectedObligations > (s.projectedRealCash * 2),
  );

  if (inconsistent) {
    CalculationTelemetry.record(
      area: 'unified_decision',
      message: 'Risk and obligations are inconsistent',
      context: {'scenario': scenario.name},
    );
  }

  return projection;
});
