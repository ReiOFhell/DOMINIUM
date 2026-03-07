import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/analytics/application/analytics_provider.dart';
import 'package:dominium/domains/analytics/presentation/analytics_screen.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/campaigns/data/campaign.dart';
import 'package:dominium/domains/campaigns/presentation/campaigns_screen.dart';
import 'package:dominium/domains/codex/presentation/codex_screen.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts/presentation/debts_screen.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/debts_direct/presentation/direct_debts_screen.dart';
import 'package:dominium/domains/navigation/presentation/domain_hub_screen.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/liquidity/application/war_coffers_provider.dart';
import 'package:dominium/domains/liquidity/presentation/accounts_screen.dart';
import 'package:dominium/domains/orders/presentation/orders_screen.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/progression/presentation/progression_screen.dart';
import 'package:dominium/domains/profile/presentation/profile_screen.dart';
import 'package:dominium/domains/throne/application/empire_settings_provider.dart';
import 'package:dominium/domains/throne/presentation/throne_screen.dart';
import 'package:dominium/domains/timeline/presentation/timeline_screen.dart';
import 'package:dominium/domains/treasury/presentation/treasury_screen.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
    final anomalyGroups = ref.watch(anomalyGroupedProvider);
    final anomalies = ref.watch(anomalyInsightsProvider);
    final directDebt = ref.watch(totalDirectDebtsProvider);
    final accountBalance = ref.watch(accountsProvider).totalBalance;
    final treasuryEntries = ref.watch(treasuryEntriesProvider);
    final treasuryReceived = treasuryEntries
        .where((entry) => entry.received && !entry.isDeleted)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final realBalance = accountBalance + treasuryReceived;
    final warBudget = ref.watch(warBudgetSummaryProvider);

    final openDebt = debts.fold<double>(0, (s, c) => s + c.openDebt);
    final totalObligations = openDebt + directDebt;
    final projectedNet = realBalance - totalObligations;
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
              Text('Centro de Comando', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(title.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Estado Atual do Império: $risk'),
              Text('Saldo real atual: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(realBalance)} (Contas + Tesouro recebido)'),
              Text('Obrigações totais: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalObligations)}'),
              Text('Caixa líquido projetado: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(projectedNet)}'),
              Text('Saldo livre de guerra: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(warBudget.warFreeBalance)}'),
              Text('Campanhas ativas: ${campaigns.length}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          mood: anomalies.isEmpty ? ImperialMood.calmo : ImperialMood.alerta,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sistema de Detecção de Anomalias v2', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (anomalies.isEmpty)
                const Text('Sem anomalias críticas no momento. O padrão financeiro está sob controle.')
              else
                ...AnomalyType.values.where((t) => (anomalyGroups[t] ?? const []).isNotEmpty).map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${_anomalyTypeLabel(type)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ...(anomalyGroups[type] ?? const []).map(
                          (anomaly) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('${anomaly.title} (${anomaly.score}/100)')),
                                    FilledButton.tonal(
                                      onPressed: () => _executeAnomalyAction(context, anomaly),
                                      child: Text(anomaly.actionLabel),
                                    ),
                                  ],
                                ),
                                Text(anomaly.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
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
              const Text('Ações Prioritárias', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance),
                title: const Text('Trono Estratégico'),
                subtitle: const Text('Estado geral, mentor, rituais e decretos.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, const ThroneScreen()),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shield),
                title: const Text('Trono das Dívidas (Cartão)'),
                subtitle: const Text('Risco, faturas e contenção imediata.'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(risk, style: const TextStyle(fontSize: 11)),
                ),
                onTap: () => _open(context, const DebtsScreen()),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.handshake),
                title: const Text('Dívidas Diretas'),
                subtitle: const Text('Obrigações fora de cartão com histórico parcial.'),
                trailing: Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(directDebt), style: const TextStyle(fontSize: 11)),
                onTap: () => _open(context, const DirectDebtsScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _anomalyTypeLabel(AnomalyType type) => switch (type) {
        AnomalyType.padrao => 'Padrão',
        AnomalyType.riscoGradual => 'Risco gradual',
        AnomalyType.autodestrutivo => 'Autodestrutivo',
      };

  Future<void> _executeAnomalyAction(BuildContext context, AnomalyInsight anomaly) async {
    switch (anomaly.action) {
      case AnomalyAction.abrirDividasCartao:
        await _open(context, const DebtsScreen());
        return;
      case AnomalyAction.abrirOraculo:
        await _open(context, const AnalyticsScreen());
        return;
      case AnomalyAction.iniciarContencao:
        await ref.read(campaignsProvider.notifier).save(
              Campaign(
                id: const Uuid().v4(),
                name: 'Contenção Automática de Dívida',
                description: 'Campanha criada a partir de anomalia autodestrutiva.',
                startDate: DateTime.now(),
                progress: 0,
                investedValue: 0,
                status: CampaignStatus.estagnada,
                milestones: const [
                  'Congelar compras não essenciais por 7 dias',
                  'Pagar acima do mínimo nas próximas faturas',
                  'Revisar padrão de gastos em 72h',
                ],
                orderIds: const [],
              ),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campanha de contenção iniciada.')),
          );
          await _open(context, const CampaignsScreen());
        }
        return;
    }
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
          title: 'Trono das Dívidas (Cartão)',
          subtitle: 'Compras, faturas, estratégia e guerra de quitação.',
          icon: Icons.shield,
          onTap: () => _open(context, const DebtsScreen()),
        ),
        DomainHubAction(
          title: 'Dívidas Diretas',
          subtitle: 'Empréstimos, promessas e parcelamentos informais.',
          icon: Icons.handshake,
          onTap: () => _open(context, const DirectDebtsScreen()),
        ),
        DomainHubAction(
          title: 'Contas e Saldo Real',
          subtitle: 'Contas bancárias, dinheiro físico e reservas líquidas.',
          icon: Icons.account_balance,
          onTap: () => _open(context, const AccountsScreen()),
        ),
        DomainHubAction(
          title: 'Oráculo Financeiro',
          subtitle: 'Fluxo, auditoria, cenários e decisões de aquisição.',
          icon: Icons.auto_graph,
          onTap: () => _open(context, const AnalyticsScreen()),
        ),
        DomainHubAction(
          title: 'Timeline Financeira',
          subtitle: 'Linha do tempo única com filtros e notas rápidas por evento.',
          icon: Icons.timeline,
          onTap: () => _open(context, const TimelineScreen()),
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
        DomainHubAction(
          title: 'Perfil',
          subtitle: 'Dados da conta, identificação atual e sessão.',
          icon: Icons.person,
          onTap: () => _open(context, const ProfileScreen()),
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
