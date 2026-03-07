import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/debts_direct/data/direct_debt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DirectDebtsScreen extends ConsumerWidget {
  const DirectDebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(directDebtsProvider);
    final total = ref.watch(totalDirectDebtsProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Dívidas Diretas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newDebt(context, ref),
        label: const Text('Nova Dívida Direta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Visão de Obrigações (fora do cartão)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Total restante: ${currency.format(total)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (debts.isEmpty)
            const GlassCard(child: Text('Sem dívidas diretas registradas.'))
          else
            ...debts.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(d.name),
                    subtitle: Text('${d.creditor} • ${d.state.name}'),
                    trailing: Text(currency.format(d.remainingValue)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Descrição: ${d.description}\nTotal: ${currency.format(d.totalValue)}\nOrigem: ${DateFormat('dd/MM/yyyy').format(d.originDate)}'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => _payment(context, ref, d),
                        child: const Text('Registrar pagamento parcial'),
                      ),
                      if (d.payments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...d.payments.map((p) => Text('• ${DateFormat('dd/MM').format(p.date)}: ${currency.format(p.value)} (${p.note})')),
                      ]
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _newDebt(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final creditor = TextEditingController();
    final value = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar Dívida Direta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(controller: creditor, decoration: const InputDecoration(labelText: 'Credor')),
            TextField(controller: value, decoration: const InputDecoration(labelText: 'Valor total'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(directDebtsProvider.notifier).createDebt(
                    name: name.text.trim(),
                    description: description.text.trim(),
                    creditor: creditor.text.trim(),
                    totalValue: double.tryParse(value.text.replaceAll(',', '.')) ?? 0,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _payment(BuildContext context, WidgetRef ref, DirectDebt debt) async {
    final value = TextEditingController();
    final note = TextEditingController(text: 'Pagamento parcial');

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pagamento da dívida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: value, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Observação')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(directDebtsProvider.notifier).addPayment(
                    debt: debt,
                    value: double.tryParse(value.text.replaceAll(',', '.')) ?? 0,
                    note: note.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
