import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/analytics/presentation/analytics_screen.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/campaigns/presentation/campaigns_screen.dart';
import 'package:dominium/domains/codex/presentation/codex_screen.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts/presentation/debts_screen.dart';
import 'package:dominium/domains/navigation/presentation/domain_hub_screen.dart';
import 'package:dominium/domains/orders/presentation/orders_screen.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/progression/presentation/progression_screen.dart';
import 'package:dominium/domains/throne/application/empire_settings_provider.dart';
import 'package:dominium/domains/throne/presentation/throne_screen.dart';
import 'package:dominium/domains/treasury/presentation/treasury_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ImperiumShell extends ConsumerStatefulWidget {
  const ImperiumShell({super.key});

  @override
  ConsumerState<ImperiumShell> createState() => _ImperiumShellState();
}

class _ImperiumShellState extends ConsumerState<ImperiumShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(empireSettingsProvider);
    final pages = [
      _centerPage(context),
      _financePage(context),
      _executionPage(context),
      _systemPage(context),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleByIndex(index, settings.throneLabel)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_customize), label: 'Centro'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Finanças'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Execução'),
          NavigationDestination(icon: Icon(Icons.shield_moon), label: 'Sistema'),
        ],
      ),
    );
  }

  Widget _centerPage(BuildContext context) {
    final debts = ref.watch(debtsProvider);
    final campaigns = ref.watch(campaignsProvider);
    final title = ref.watch(currentImperialTitleProvider);

    final openDebt = debts.fold<double>(0, (s, c) => s + c.openDebt);
    final risk = debts.isEmpty
        ? 'Estável'
        : debts.any((c) => c.committedLimitNow > 0.85)
            ? 'Crítico'
            : debts.any((c) => c.committedLimitNow > 0.7)
                ? 'Atenção'
                : 'Controlado';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          mood: risk == 'Crítico'
              ? ImperialMood.critico
              : risk == 'Atenção'
                  ? ImperialMood.alerta
                  : ImperialMood.calmo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Estado Atual do Império: $risk'),
              const SizedBox(height: 8),
              Text('Dívida aberta: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(openDebt)}'),
              Text('Campanhas ativas: ${campaigns.length}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DomainHubScreen(
          title: 'Centro de Comando',
          description:
              'Visão unificada dos pontos críticos. Hierarquia absoluta para decisões imediatas.',
          actions: [
            DomainHubAction(
              title: 'Trono Estratégico',
              subtitle: 'Painel completo de estado, mentor e rituais.',
              icon: Icons.account_balance,
              onTap: () => _open(context, const ThroneScreen()),
            ),
            DomainHubAction(
              title: 'Trono das Dívidas',
              subtitle: 'Domine risco, fatura e rotativo com prioridade máxima.',
              icon: Icons.shield,
              badge: risk,
              mood: risk == 'Crítico' ? ImperialMood.critico : ImperialMood.alerta,
              onTap: () => _open(context, const DebtsScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _financePage(BuildContext context) {
    return DomainHubScreen(
      title: 'Domínio Financeiro',
      description:
          'Arquitetura de caixa, dívida e projeção. Superfície simples, profundidade profissional.',
      actions: [
        DomainHubAction(
          title: 'Tesouro Imperial',
          subtitle: 'Receitas, saldo e histórico com precisão de caixa.',
          icon: Icons.account_balance_wallet,
          onTap: () => _open(context, const TreasuryScreen()),
        ),
        DomainHubAction(
          title: 'Trono das Dívidas',
          subtitle: 'Compras, faturas, estratégia e guerra de quitação.',
          icon: Icons.shield,
          onTap: () => _open(context, const DebtsScreen()),
        ),
        DomainHubAction(
          title: 'Oráculo Financeiro',
          subtitle: 'Fluxo, auditoria, cenários e decisões de aquisição.',
          icon: Icons.auto_graph,
          onTap: () => _open(context, const AnalyticsScreen()),
        ),
      ],
    );
  }

  Widget _executionPage(BuildContext context) {
    final campaigns = ref.watch(campaignsProvider);

    return DomainHubScreen(
      title: 'Domínio de Execução',
      description: 'Ordens e campanhas com sequência tática: começo, meio e conclusão.',
      actions: [
        DomainHubAction(
          title: 'Ordens',
          subtitle: 'Ritmo diário e disciplina verificável.',
          icon: Icons.gavel,
          onTap: () => _open(context, const OrdersScreen()),
        ),
        DomainHubAction(
          title: 'Campanhas',
          subtitle: 'Arcos estratégicos mensais com missão e chefe.',
          icon: Icons.flag,
          badge: '${campaigns.length} ativa(s)',
          mood: campaigns.isEmpty ? ImperialMood.alerta : ImperialMood.calmo,
          onTap: () => _open(context, const CampaignsScreen()),
        ),
      ],
    );
  }

  Widget _systemPage(BuildContext context) {
    final progression = ref.watch(progressionProvider);

    return DomainHubScreen(
      title: 'Domínio do Sistema',
      description: 'Progressão, conhecimento e governança do próprio instrumento.',
      actions: [
        DomainHubAction(
          title: 'Sistema de Progressão Imperial',
          subtitle: 'Títulos, ordem, moedas internas, loja e gravidade.',
          icon: Icons.military_tech,
          badge: 'Nível ${progression.level}',
          onTap: () => _open(context, const ProgressionScreen()),
        ),
        DomainHubAction(
          title: 'Codex Imperial',
          subtitle: 'Biblioteca viva: descoberta, uso e domínio dos módulos.',
          icon: Icons.menu_book,
          onTap: () => _open(context, const CodexScreen()),
        ),
      ],
    );
  }

  String _titleByIndex(int idx, String throneName) => switch (idx) {
        0 => throneName,
        1 => 'Finanças',
        2 => 'Execução',
        3 => 'Sistema',
        _ => 'Imperium',
      };

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
