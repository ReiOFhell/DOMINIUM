import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/monthly_closure/data/monthly_report.dart';
import 'package:dominium/domains/monthly_closure/data/monthly_report_repository.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class MonthlyClosureChecklist {
  const MonthlyClosureChecklist({
    required this.reconcileAccounts,
    required this.reviewDebts,
    required this.evaluateProjectedCash,
    required this.defineCampaign,
  });

  final bool reconcileAccounts;
  final bool reviewDebts;
  final bool evaluateProjectedCash;
  final bool defineCampaign;

  bool get isComplete =>
      reconcileAccounts && reviewDebts && evaluateProjectedCash && defineCampaign;

  MonthlyClosureChecklist copyWith({
    bool? reconcileAccounts,
    bool? reviewDebts,
    bool? evaluateProjectedCash,
    bool? defineCampaign,
  }) {
    return MonthlyClosureChecklist(
      reconcileAccounts: reconcileAccounts ?? this.reconcileAccounts,
      reviewDebts: reviewDebts ?? this.reviewDebts,
      evaluateProjectedCash: evaluateProjectedCash ?? this.evaluateProjectedCash,
      defineCampaign: defineCampaign ?? this.defineCampaign,
    );
  }

  static const empty = MonthlyClosureChecklist(
    reconcileAccounts: false,
    reviewDebts: false,
    evaluateProjectedCash: false,
    defineCampaign: false,
  );
}

final monthlyReportRepositoryProvider =
    Provider<MonthlyReportRepository>((_) => MonthlyReportRepository.fromHive());

final monthlyReportsProvider = StateNotifierProvider<MonthlyClosureController, List<MonthlyReport>>(
  (ref) => MonthlyClosureController(ref.read(monthlyReportRepositoryProvider)),
);

final monthlyChecklistProvider =
    StateProvider<MonthlyClosureChecklist>((_) => MonthlyClosureChecklist.empty);

final monthlyClosureRiskProvider = Provider<String>((ref) {
  final debts = ref.watch(debtsProvider);
  final direct = ref.watch(totalDirectDebtsProvider);
  final real = ref.watch(accountsProvider).totalBalance;

  final cardOpen = debts.fold<double>(0, (s, c) => s + c.openDebt);
  final total = cardOpen + direct;

  if (total > real * 1.2) return 'Crítico';
  if (total > real * 0.8) return 'Alerta';
  return 'Estável';
});

final monthlyProjectedNetProvider = Provider<double>((ref) {
  final cardOpen = ref.watch(debtsProvider).fold<double>(0, (s, c) => s + c.openDebt);
  final direct = ref.watch(totalDirectDebtsProvider);
  final real = ref.watch(accountsProvider).totalBalance;
  return real - (cardOpen + direct);
});

final monthlySuggestedPlanProvider = Provider<List<String>>((ref) {
  final risk = ref.watch(monthlyClosureRiskProvider);
  final campaigns = ref.watch(campaignsProvider);
  final plan = <String>[];

  if (risk == 'Crítico') {
    plan.add('Executar campanha de contenção de dívida com prioridade máxima.');
    plan.add('Suspender compras parceladas fora do essencial por 30 dias.');
  } else if (risk == 'Alerta') {
    plan.add('Aumentar pagamento mensal de dívidas em 15% no próximo ciclo.');
  } else {
    plan.add('Expandir reserva líquida mantendo caixa projetado positivo.');
  }

  if (campaigns.isEmpty) {
    plan.add('Definir campanha mensal com chefe financeiro mensurável.');
  }
  plan.add('Realizar novo fechamento em 30 dias com comparação de progresso.');
  return plan;
});

class MonthlyClosureController extends StateNotifier<List<MonthlyReport>> {
  MonthlyClosureController(this._repository) : super(_repository.all());

  final MonthlyReportRepository _repository;

  Future<void> generateReport({
    required String risk,
    required double projectedNet,
    required List<String> victories,
    required List<String> failures,
    required List<String> tacticalPlan,
  }) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final report = MonthlyReport(
      id: const Uuid().v4(),
      monthKey: monthKey,
      generatedAt: now,
      victories: victories,
      failures: failures,
      currentRisk: risk,
      tacticalPlan: tacticalPlan,
      projectedNet: projectedNet,
    );

    await _repository.save(report);
    state = _repository.all();
  }
}

final monthlyVictoryFailureProvider = Provider<(List<String>, List<String>)>((ref) {
  final treasury = ref.watch(treasuryEntriesProvider);
  final projected = ref.watch(monthlyProjectedNetProvider);
  final progression = ref.watch(progressionProvider);
  final risk = ref.watch(monthlyClosureRiskProvider);

  final victories = <String>[];
  final failures = <String>[];

  final received = treasury.where((t) => t.received).fold<double>(0, (s, t) => s + t.amount);
  final pending = treasury.where((t) => !t.received).fold<double>(0, (s, t) => s + t.amount);

  if (received >= pending) {
    victories.add('Receitas recebidas superaram pendências neste ciclo.');
  } else {
    failures.add('Pendências superaram receitas recebidas no ciclo.');
  }

  if (projected >= 0) {
    victories.add('Caixa líquido projetado permaneceu positivo.');
  } else {
    failures.add('Caixa líquido projetado ficou negativo.');
  }

  if (progression.level >= 2) {
    victories.add('Progressão imperial avançou para nível ${progression.level}.');
  }

  if (risk == 'Crítico') {
    failures.add('Risco atual em estado crítico: requer plano de contenção imediato.');
  }

  if (victories.isEmpty) victories.add('Ciclo concluído com estabilidade mínima.');
  if (failures.isEmpty) failures.add('Sem falhas críticas no fechamento atual.');

  return (victories, failures);
});
