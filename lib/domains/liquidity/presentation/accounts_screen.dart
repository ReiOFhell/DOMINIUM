import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/liquidity/application/war_coffers_provider.dart';
import 'package:dominium/domains/liquidity/data/account.dart';
import 'package:dominium/domains/liquidity/data/war_coffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsProvider);
    final warBudget = ref.watch(warBudgetSummaryProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Contas e Saldo Real')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newAccount(context, ref),
        label: const Text('Nova Conta'),
        icon: const Icon(Icons.add_card),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Visão de Realidade Atual', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Saldo total consolidado: ${currency.format(state.totalBalance)}'),
                Text('Compromissos críticos: ${currency.format(warBudget.criticalCommitments)}'),
                const SizedBox(height: 6),
                Text(
                  'Saldo livre de guerra: ${currency.format(warBudget.warFreeBalance)}',
                  style: TextStyle(
                    color: warBudget.warFreeBalance >= 0 ? DominiumTheme.gold : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            mood: warBudget.warFreeBalance < 0 ? ImperialMood.alerta : ImperialMood.calmo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Cofres Táticos', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => _configureCoffers(context, ref),
                      child: const Text('Ajustar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...warBudget.coffers.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.$1.label)),
                        Text('${(entry.$1.weight * 100).toStringAsFixed(0)}% • ${currency.format(entry.$2)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                Text('Dívidas abertas atuais: ${currency.format(warBudget.openDebts)}'),
                Text('Cofre Essencial protegido em: ${currency.format(warBudget.essentialAllocated)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (state.accounts.isEmpty)
            const GlassCard(child: Text('Nenhuma conta registrada.'))
          else
            ...state.accounts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: Color(a.colorHex)),
                    title: Text(a.name),
                    subtitle: Text(a.kind),
                    trailing: Text(currency.format(a.balance)),
                    onTap: () => _moveDialog(context, ref, a),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _newAccount(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final kind = TextEditingController(text: 'Conta bancária');
    final balance = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar Conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: kind, decoration: const InputDecoration(labelText: 'Tipo')),
            TextField(controller: balance, decoration: const InputDecoration(labelText: 'Saldo inicial'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(accountsProvider.notifier).createAccount(
                    name: name.text.trim(),
                    kind: kind.text.trim(),
                    initialBalance: double.tryParse(balance.text.replaceAll(',', '.')) ?? 0,
                    colorHex: 0xFFB2873F,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveDialog(BuildContext context, WidgetRef ref, FinancialAccount account) async {
    final description = TextEditingController();
    final amount = TextEditingController();
    MovementType type = MovementType.saida;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Movimentar ${account.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
              TextField(controller: amount, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
              DropdownButton<MovementType>(
                value: type,
                isExpanded: true,
                onChanged: (v) => setState(() => type = v ?? MovementType.saida),
                items: const [
                  DropdownMenuItem(value: MovementType.entrada, child: Text('Entrada')),
                  DropdownMenuItem(value: MovementType.saida, child: Text('Saída')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final budget = ref.read(warBudgetSummaryProvider);
                final result = await ref.read(accountsProvider.notifier).move(
                      account: account,
                      description: description.text.trim(),
                      amount: double.tryParse(amount.text.replaceAll(',', '.')) ?? 0,
                      type: type,
                      essentialGuardBalance: budget.essentialAllocated,
                      warningGuardBalance: budget.essentialAllocated * 1.15,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: switch (result.status) {
                        MovementExecutionStatus.executed => null,
                        MovementExecutionStatus.warning => Colors.orange.shade700,
                        MovementExecutionStatus.blocked => Colors.red.shade700,
                      },
                    ),
                  );
                }

                if (result.applied && context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Executar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _configureCoffers(BuildContext context, WidgetRef ref) async {
    final current = ref.read(warCoffersProvider);
    final controllers = {
      for (final coffer in current)
        coffer.type: TextEditingController(text: (coffer.weight * 100).toStringAsFixed(0)),
    };

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajustar Cofres (%)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in WarCofferType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[type],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: type.name.toUpperCase()),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final values = {
                for (final type in WarCofferType.values)
                  type: double.tryParse(controllers[type]!.text.replaceAll(',', '.')) ?? 0,
              };
              await ref.read(warCoffersProvider.notifier).rebalancePercentages(values);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
