import 'dart:math';

import 'package:dominium/domains/analytics/data/possibility_result.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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

  final anomalies = <AnomalyInsight>[];

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

  if (previousPurchases > 0) {
    final change = ((recentPurchases - previousPurchases) / previousPurchases) * 100;
    if (change >= 20) {
      final score = change.clamp(20, 100).round();
      anomalies.add(
        AnomalyInsight(
          type: AnomalyType.padrao,
          title: 'Mudança abrupta de padrão de compra',
          description: 'Gastos cresceram ${change.toStringAsFixed(0)}% nos últimos 12 dias.',
          score: score,
          action: AnomalyAction.abrirOraculo,
          actionLabel: 'Abrir Oráculo',
        ),
      );
    }
  }

  final avgCommit = debts.isEmpty
      ? 0.0
      : debts.fold<double>(0, (s, c) => s + c.committedLimitNow) / debts.length;
  if (avgCommit >= 0.78) {
    final score = (avgCommit * 100).clamp(0, 100).round();
    anomalies.add(
      AnomalyInsight(
        type: AnomalyType.riscoGradual,
        title: 'Comprometimento médio elevado',
        description: 'Limite médio comprometido em ${(avgCommit * 100).toStringAsFixed(0)}%.',
        score: score,
        action: AnomalyAction.abrirDividasCartao,
        actionLabel: 'Abrir Dívidas',
      ),
    );
  }

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

  if (impulseBursts > 0) {
    final score = (70 + impulseBursts * 10).clamp(0, 100).round();
    anomalies.add(
      AnomalyInsight(
        type: AnomalyType.autodestrutivo,
        title: 'Explosão de compras impulsivas',
        description: 'Detectadas $impulseBursts janela(s) com 4+ compras no mesmo dia.',
        score: score,
        action: AnomalyAction.iniciarContencao,
        actionLabel: 'Iniciar contenção',
      ),
    );
  }

  final recentIncome = treasury
      .where((t) => t.received && now.difference(t.date).inDays <= 30)
      .fold<double>(0, (s, t) => s + t.amount);
  final recentOpenDebt = debts.fold<double>(0, (s, c) => s + c.openDebt);
  if (recentIncome > 0 && recentOpenDebt > recentIncome * 1.2) {
    final overload = (recentOpenDebt / recentIncome) * 100;
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
