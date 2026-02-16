import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/analytics/application/analytics_provider.dart';
import 'package:dominium/domains/analytics/data/possibility_result.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final fixedIncome = TextEditingController(text: '0');
  final variableIncome = TextEditingController(text: '0');
  final fixedCosts = TextEditingController(text: '0');
  final margin = TextEditingController(text: '20');
  final debtTarget = TextEditingController(text: '0');
  final installments = TextEditingController(text: '6');
  final interest = TextEditingController(text: '3');

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(monthlyFlowProvider);
    final scenarios = ref.watch(possibilityScenariosProvider);
    final debts = ref.watch(debtsProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Oráculo Financeiro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fluxo mensal (Ganhos • Gastos • Saldo)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButton<int>(
                  value: ref.watch(flowFilterProvider),
                  onChanged: (v) => ref.read(flowFilterProvider.notifier).state = v ?? 6,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 meses')),
                    DropdownMenuItem(value: 6, child: Text('6 meses')),
                    DropdownMenuItem(value: 12, child: Text('12 meses')),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (var i = 0; i < flow.length; i++) FlSpot(i.toDouble(), flow[i].income)],
                          color: DominiumTheme.gold,
                        ),
                        LineChartBarData(
                          spots: [for (var i = 0; i < flow.length; i++) FlSpot(i.toDouble(), flow[i].expense)],
                          color: Colors.redAccent,
                        ),
                        LineChartBarData(
                          spots: [for (var i = 0; i < flow.length; i++) FlSpot(i.toDouble(), flow[i].balance.abs())],
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...flow.map((f) => Text(
                    '${DateFormat('MM/yy').format(f.month)} • Ganhos ${currency.format(f.income)} • Gastos ${currency.format(f.expense)} • Saldo ${currency.format(f.balance)}',
                    style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Composição de gastos por cartão', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (debts.isEmpty)
                  const Text('Sem cartões para compor análise.')
                else
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          for (var i = 0; i < debts.length; i++)
                            PieChartSectionData(
                              value: debts[i].openDebt,
                              title: debts[i].name,
                              color: Color.lerp(DominiumTheme.red, DominiumTheme.gold, i / debts.length),
                              radius: 70,
                              titleStyle: const TextStyle(fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modo Auditor', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._anomalies(flow).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $e'),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _calculatorCard(),

          const SizedBox(height: 12),

          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ritual de Fechamento do Mês', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...const [
                  'Conferir todas as faturas em julgamento',
                  'Registrar despesas fixas e variáveis do ciclo',
                  'Emitir decreto de pagamento do próximo vencimento',
                  'Atualizar cofres: emergência, projetos e investimento',
                ].map((e) => Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [Icon(Icons.check_circle_outline, size: 16), SizedBox(width: 8), Expanded(child: Text(e))],
                      ),
                    )),
              ],
            ),
          ),

          ...scenarios.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_scenarioName(s.profile), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Veredito: ${_verdictText(s.verdict)}'),
                    Text('Parcela estimada: ${currency.format(s.installmentValue)}'),
                    Text('Renda comprometida: ${s.incomeCommittedPercent.toStringAsFixed(1)}%'),
                    Text('Folga pós-fixas: ${currency.format(s.postFixedSlack)}'),
                    Text('Risco de rotativo: ${s.rotativeRisk.toStringAsFixed(1)}%'),
                    const SizedBox(height: 4),
                    Text('Recomendação: ${s.recommendation}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calculatorCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Calculadora de Possibilidades', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: fixedIncome, decoration: const InputDecoration(labelText: 'Ganhos fixos')),
          TextField(controller: variableIncome, decoration: const InputDecoration(labelText: 'Ganhos variáveis')),
          TextField(controller: fixedCosts, decoration: const InputDecoration(labelText: 'Gastos fixos')),
          TextField(controller: margin, decoration: const InputDecoration(labelText: 'Margem segura %')),
          TextField(controller: debtTarget, decoration: const InputDecoration(labelText: 'Dívida pretendida')),
          TextField(controller: installments, decoration: const InputDecoration(labelText: 'Parcelas')),
          TextField(controller: interest, decoration: const InputDecoration(labelText: 'Juros %')), 
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                ref.read(possibilityInputProvider.notifier).state = PossibilityInput(
                      fixedIncome: _parse(fixedIncome.text),
                      variableIncome: _parse(variableIncome.text),
                      fixedCosts: _parse(fixedCosts.text),
                      safeMarginPercent: _parse(margin.text),
                      debtTarget: _parse(debtTarget.text),
                      installments: _parse(installments.text).toInt(),
                      interest: _parse(interest.text),
                    );
              },
              child: const Text('Julgar aquisição'),
            ),
          ),
        ],
      ),
    );
  }

  double _parse(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0;

  List<String> _anomalies(List<FlowPoint> flow) {
    if (flow.length < 2) return const ['Dados insuficientes para auditoria de anomalias.'];
    final anomalies = <String>[];
    for (var i = 1; i < flow.length; i++) {
      if (flow[i].expense > flow[i - 1].expense * 1.35) {
        anomalies.add('Pico de gasto em ${DateFormat('MM/yy').format(flow[i].month)} acima de 35% do ciclo anterior.');
      }
    }
    if (anomalies.isEmpty) anomalies.add('Sem anomalias graves detectadas no período filtrado.');
    return anomalies;
  }

  String _scenarioName(ScenarioProfile p) => switch (p) {
        ScenarioProfile.conservador => 'Cenário Conservador',
        ScenarioProfile.realista => 'Cenário Realista',
        ScenarioProfile.agressivo => 'Cenário Agressivo',
      };

  String _verdictText(AcquisitionVerdict v) => switch (v) {
        AcquisitionVerdict.pode => 'Pode',
        AcquisitionVerdict.podeComRisco => 'Pode com risco',
        AcquisitionVerdict.naoPode => 'Não pode',
      };
}
