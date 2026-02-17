import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/monthly_closure/application/monthly_closure_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MonthlyClosureScreen extends ConsumerStatefulWidget {
  const MonthlyClosureScreen({super.key});

  @override
  ConsumerState<MonthlyClosureScreen> createState() => _MonthlyClosureScreenState();
}

class _MonthlyClosureScreenState extends ConsumerState<MonthlyClosureScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final checklist = ref.watch(monthlyChecklistProvider);
    final risk = ref.watch(monthlyClosureRiskProvider);
    final projected = ref.watch(monthlyProjectedNetProvider);
    final plan = ref.watch(monthlySuggestedPlanProvider);
    final tuple = ref.watch(monthlyVictoryFailureProvider);
    final reports = ref.watch(monthlyReportsProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Ritual de Fechamento Mensal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Stepper(
              currentStep: step,
              onStepContinue: () {
                if (step < 3) {
                  setState(() => step += 1);
                }
              },
              onStepCancel: () {
                if (step > 0) setState(() => step -= 1);
              },
              controlsBuilder: (context, details) => Row(
                children: [
                  FilledButton.tonal(onPressed: details.onStepContinue, child: const Text('Avançar')),
                  const SizedBox(width: 8),
                  TextButton(onPressed: details.onStepCancel, child: const Text('Voltar')),
                ],
              ),
              steps: [
                Step(
                  title: const Text('Conciliar saldos das contas'),
                  isActive: step >= 0,
                  content: CheckboxListTile(
                    value: checklist.reconcileAccounts,
                    onChanged: (v) => ref.read(monthlyChecklistProvider.notifier).state =
                        checklist.copyWith(reconcileAccounts: v ?? false),
                    title: const Text('Saldos conciliados com bancos e dinheiro físico.'),
                  ),
                ),
                Step(
                  title: const Text('Revisar dívidas cartão e diretas'),
                  isActive: step >= 1,
                  content: CheckboxListTile(
                    value: checklist.reviewDebts,
                    onChanged: (v) => ref.read(monthlyChecklistProvider.notifier).state =
                        checklist.copyWith(reviewDebts: v ?? false),
                    title: const Text('Faturas e dívidas diretas revisadas com status atualizado.'),
                  ),
                ),
                Step(
                  title: const Text('Avaliar caixa projetado'),
                  isActive: step >= 2,
                  content: CheckboxListTile(
                    value: checklist.evaluateProjectedCash,
                    onChanged: (v) => ref.read(monthlyChecklistProvider.notifier).state =
                        checklist.copyWith(evaluateProjectedCash: v ?? false),
                    title: Text('Caixa projetado avaliado: ${currency.format(projected)}'),
                  ),
                ),
                Step(
                  title: const Text('Definir campanha do próximo ciclo'),
                  isActive: step >= 3,
                  content: CheckboxListTile(
                    value: checklist.defineCampaign,
                    onChanged: (v) => ref.read(monthlyChecklistProvider.notifier).state =
                        checklist.copyWith(defineCampaign: v ?? false),
                    title: const Text('Plano tático do próximo ciclo confirmado.'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            mood: risk == 'Crítico'
                ? ImperialMood.critico
                : risk == 'Alerta'
                    ? ImperialMood.alerta
                    : ImperialMood.calmo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prévia do Relatório Imperial Mensal', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Risco atual: $risk'),
                Text('Caixa líquido projetado: ${currency.format(projected)}'),
                const SizedBox(height: 8),
                const Text('Vitórias:'),
                ...tuple.$1.map((v) => Text('• $v')),
                const SizedBox(height: 8),
                const Text('Falhas:'),
                ...tuple.$2.map((f) => Text('• $f')),
                const SizedBox(height: 8),
                const Text('Plano tático seguinte:'),
                ...plan.map((p) => Text('• $p')),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: checklist.isComplete
                      ? () async {
                          await ref.read(monthlyReportsProvider.notifier).generateReport(
                                risk: risk,
                                projectedNet: projected,
                                victories: tuple.$1,
                                failures: tuple.$2,
                                tacticalPlan: plan,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Relatório Imperial Mensal gerado com sucesso.')),
                            );
                          }
                        }
                      : null,
                  child: const Text('Gerar Relatório Imperial Mensal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico de Fechamentos', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (reports.isEmpty)
                  const Text('Nenhum fechamento gerado ainda.')
                else
                  ...reports.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${r.monthKey} • ${DateFormat('dd/MM/yyyy HH:mm').format(r.generatedAt)} • Risco ${r.currentRisk} • Projetado ${currency.format(r.projectedNet)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
