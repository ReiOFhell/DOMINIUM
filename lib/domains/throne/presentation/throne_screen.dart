import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/rituals/application/ritual_provider.dart';
import 'package:dominium/domains/throne/application/throne_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ThroneScreen extends ConsumerStatefulWidget {
  const ThroneScreen({super.key});

  @override
  ConsumerState<ThroneScreen> createState() => _ThroneScreenState();
}

class _ThroneScreenState extends ConsumerState<ThroneScreen> {
  final reflection = TextEditingController();

  @override
  void dispose() {
    reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = ref.watch(throneTitleProvider);
    final phrase = ref.watch(imperialPhraseProvider);
    final treasury = ref.watch(treasuryEntriesProvider);
    final campaigns = ref.watch(campaignsProvider);
    final orders = ref.watch(ordersProvider);

    final received = treasury.where((e) => e.received).fold<double>(0, (a, e) => a + e.amount);
    final pending = treasury.where((e) => !e.received).fold<double>(0, (a, e) => a + e.amount);
    final doneOrders = orders.where((o) => o.executed).length;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Trono')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lord $title', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(phrase, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric('Ouro total', formatter.format(received), DominiumTheme.gold),
                _metric('Dívidas', formatter.format(pending), Colors.white),
                _metric('Campanhas', campaigns.length.toString(), Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: received / 100, color: DominiumTheme.gold)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: doneOrders.toDouble(), color: Colors.white70)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: campaigns.length.toDouble(), color: DominiumTheme.red)]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ritual Diário (50 palavras)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: reflection,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Registre sua reflexão sem culpa, apenas clareza.',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => ref.read(ritualsProvider.notifier).saveToday(reflection.text.trim()),
                    child: const Text('Registrar Ritual'),
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
                const Text('Títulos Honoríficos', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (received >= 10000) const Text('• Guardião das Finanças'),
                if (doneOrders >= 50) const Text('• Executor de Decretos'),
                if (campaigns.length >= 3) const Text('• Estrategista de Campanhas'),
                if (received < 10000 && doneOrders < 50 && campaigns.length < 3)
                  const Text('Registre avanço consistente para desbloquear honrarias.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
