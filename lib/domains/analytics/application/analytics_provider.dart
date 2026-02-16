import 'dart:math';

import 'package:dominium/domains/analytics/data/possibility_result.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
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
