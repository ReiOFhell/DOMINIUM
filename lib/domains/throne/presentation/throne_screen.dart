import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/codex/application/codex_provider.dart';
import 'package:dominium/domains/codex/data/codex_entry.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/rituals/application/ritual_provider.dart';
import 'package:dominium/domains/throne/application/empire_settings_provider.dart';
import 'package:dominium/domains/throne/application/imperial_advisor_provider.dart';
import 'package:dominium/domains/throne/application/throne_provider.dart';
import 'package:dominium/domains/throne/data/empire_settings.dart';
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
  bool _revelationChecked = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revelationChecked) return;
    _revelationChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = ref.read(pendingRevelationsProvider);
      if (pending.isEmpty || !mounted) return;
      final system = pending.first;
      await _showRevelation(system);
      await ref.read(codexProvider.notifier).reveal(system);
    });
  }

  @override
  void dispose() {
    reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = ref.watch(throneTitleProvider);
    final phrase = ref.watch(imperialPhraseProvider);
    final advice = ref.watch(imperialAdvisorProvider);
    final interventions = ref.watch(mentorInterventionsProvider);
    final progressMentor = ref.watch(progressionMentorProvider);
    final treasury = ref.watch(treasuryEntriesProvider);
    final campaigns = ref.watch(campaignsProvider);
    final orders = ref.watch(ordersProvider);

    final received = treasury.where((e) => e.received).fold<double>(0, (a, e) => a + e.amount);
    final pending = treasury.where((e) => !e.received).fold<double>(0, (a, e) => a + e.amount);
    final doneOrders = orders.where((o) => o.executed).length;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trono'),
        actions: [
          IconButton(
            onPressed: () => _openImperialConfig(context),
            icon: const Icon(Icons.tune),
            tooltip: 'Arquitetura do Império',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lord Inkosi, título atual: $title',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(phrase, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          if (interventions.isNotEmpty)
            GlassCard(
              mood: ImperialMood.alerta,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mentor Invisível', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...interventions.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(m.message),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => ref.read(codexProvider.notifier).registerUsage(m.system),
                              child: Text(m.action),
                            ),
                          ],
                        ),
                      )),
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
                    BarChartGroupData(
                        x: 0,
                        barRods: [BarChartRodData(toY: received / 100, color: DominiumTheme.gold)]),
                    BarChartGroupData(
                        x: 1,
                        barRods: [BarChartRodData(toY: doneOrders.toDouble(), color: Colors.white70)]),
                    BarChartGroupData(
                        x: 2,
                        barRods: [BarChartRodData(toY: campaigns.length.toDouble(), color: DominiumTheme.red)]),
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
                const Text('Mentor de Progressão', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...progressMentor.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $m'),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conselheira Imperial', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...advice.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $insight'),
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

  Future<void> _openImperialConfig(BuildContext context) async {
    final settings = ref.read(empireSettingsProvider);
    final throne = TextEditingController(text: settings.throneLabel);
    final treasury = TextEditingController(text: settings.treasuryLabel);
    final orders = TextEditingController(text: settings.ordersLabel);
    final campaigns = TextEditingController(text: settings.campaignsLabel);
    ImperialPalette palette = settings.palette;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Arquitetura Imperial'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: throne, decoration: const InputDecoration(labelText: 'Nome do Trono')),
                const SizedBox(height: 8),
                TextField(controller: treasury, decoration: const InputDecoration(labelText: 'Nome do Tesouro')),
                const SizedBox(height: 8),
                TextField(controller: orders, decoration: const InputDecoration(labelText: 'Nome das Ordens')),
                const SizedBox(height: 8),
                TextField(
                    controller: campaigns,
                    decoration: const InputDecoration(labelText: 'Nome das Campanhas')),
                const SizedBox(height: 12),
                DropdownButton<ImperialPalette>(
                  value: palette,
                  isExpanded: true,
                  onChanged: (v) => setState(() => palette = v ?? ImperialPalette.crimson),
                  items: const [
                    DropdownMenuItem(
                      value: ImperialPalette.crimson,
                      child: Text('Vermelho Imperial'),
                    ),
                    DropdownMenuItem(
                      value: ImperialPalette.royal,
                      child: Text('Azul Real'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                await ref.read(empireSettingsProvider.notifier).update(
                      settings.copyWith(
                        throneLabel: throne.text.trim().isEmpty ? settings.throneLabel : throne.text.trim(),
                        treasuryLabel:
                            treasury.text.trim().isEmpty ? settings.treasuryLabel : treasury.text.trim(),
                        ordersLabel: orders.text.trim().isEmpty ? settings.ordersLabel : orders.text.trim(),
                        campaignsLabel: campaigns.text.trim().isEmpty
                            ? settings.campaignsLabel
                            : campaigns.text.trim(),
                        palette: palette,
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Aplicar Decreto'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showRevelation(ImperialSystem system) async {
    final data = switch (system) {
      ImperialSystem.ordens => (
          title: 'Nova estrutura desbloqueada: Ordens Imperiais',
          why: 'Existe para transformar intenção em execução consistente.',
          when: 'Use quando houver metas sem cadência diária.',
          how: 'Crie 1 ordem de alto impacto e acompanhe execução por 7 dias.',
          risk: 'Ignorar mantém avanço sem ritmo e reduz crescimento.'
        ),
      ImperialSystem.campanhas => (
          title: 'Nova estrutura desbloqueada: Campanhas',
          why: 'Existe para enfrentar ameaças complexas em ciclos longos.',
          when: 'Use ao lidar com dívida crescente ou metas estruturais.',
          how: 'Defina objetivo, marcos e ordens vinculadas.',
          risk: 'Ignorar amplia improviso e reduz capacidade de reação.'
        ),
      ImperialSystem.dividas => (
          title: 'Nova estrutura desbloqueada: Trono das Dívidas',
          why: 'Existe para conter juros e recuperar soberania financeira.',
          when: 'Use sempre que houver faturas ou parcelas vivas.',
          how: 'Registre compras, simule ciclos e emita decretos de pagamento.',
          risk: 'Ignorar favorece rotativo e acelera perda de caixa.'
        ),
      _ => (
          title: 'Nova estrutura imperial detectada',
          why: 'Uma nova camada de comando foi aberta.',
          when: 'Use quando o mentor sinalizar relevância.',
          how: 'Inicie o modo guiado no Codex Imperial.',
          risk: 'Ignorar reduz clareza estratégica.'
        ),
    };

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(data.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por que existe: ${data.why}'),
            const SizedBox(height: 6),
            Text('Quando usar: ${data.when}'),
            const SizedBox(height: 6),
            Text('Como usar: ${data.how}'),
            const SizedBox(height: 6),
            Text('Se ignorar: ${data.risk}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compreendi e avançar'),
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
