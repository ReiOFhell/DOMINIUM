import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:dominium/domains/treasury/data/treasury_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(treasuryFilteredProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final received = entries.where((e) => e.received).fold<double>(0, (sum, e) => sum + e.amount);
    final pending = entries.where((e) => !e.received).fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Tesouro Imperial')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        label: const Text('Nova Receita'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _money('Recebido', currency.format(received)),
                  _money('A receber', currency.format(pending)),
                  _money('Saldo', currency.format(received), emphasize: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar registros'),
              onChanged: (v) => ref.read(treasurySearchProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<TreasurySort>(
                value: ref.watch(treasurySortProvider),
                onChanged: (v) => ref.read(treasurySortProvider.notifier).state = v ?? TreasurySort.date,
                items: const [
                  DropdownMenuItem(value: TreasurySort.date, child: Text('Ordenar por data')),
                  DropdownMenuItem(value: TreasurySort.amount, child: Text('Ordenar por valor')),
                  DropdownMenuItem(value: TreasurySort.status, child: Text('Ordenar por status')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Nenhuma receita registrada. O Tesouro aguarda sua ordem.'))
                  : ListView.separated(
                      itemBuilder: (_, i) => _entryTile(context, ref, entries[i], currency),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: entries.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _money(String label, String value, {bool emphasize = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? DominiumTheme.gold : Colors.white,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _entryTile(BuildContext context, WidgetRef ref, TreasuryEntry entry, NumberFormat currency) {
    return GlassCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(entry.title),
        subtitle: Text('${currency.format(entry.amount)} • ${entry.received ? 'Recebido' : 'Pendente'}'),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Local: ${entry.location}\nDescrição: ${entry.description}\nData: ${DateFormat('dd/MM/yyyy').format(entry.date)}'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => _showForm(context, ref, existing: entry),
                child: const Text('Editar'),
              ),
              TextButton(
                onPressed: () => ref.read(treasuryEntriesProvider.notifier).save(entry.copyWith(received: !entry.received)),
                child: Text(entry.received ? 'Marcar pendente' : 'Marcar recebido'),
              ),
              TextButton(
                onPressed: () => ref.read(treasuryEntriesProvider.notifier).remove(entry.id),
                child: const Text('Deletar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, {TreasuryEntry? existing}) async {
    final title = TextEditingController(text: existing?.title);
    final description = TextEditingController(text: existing?.description);
    final location = TextEditingController(text: existing?.location);
    final amount = TextEditingController(text: existing?.amount.toString());
    DateTime selectedDate = existing?.date ?? DateTime.now();
    bool received = existing?.received ?? false;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Nova Receita' : 'Editar Receita'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 8),
                TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
                const SizedBox(height: 8),
                TextField(controller: location, decoration: const InputDecoration(labelText: 'Local')),
                const SizedBox(height: 8),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text('Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.date_range),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: selectedDate,
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
                SwitchListTile(
                  value: received,
                  onChanged: (v) => setState(() => received = v),
                  title: const Text('Recebido'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final parsedAmount = double.tryParse(amount.text.replaceAll(',', '.'));
                if (title.text.trim().isEmpty || parsedAmount == null) return;

                final entry = TreasuryEntry(
                  id: existing?.id ?? const Uuid().v4(),
                  title: title.text.trim(),
                  description: description.text.trim(),
                  location: location.text.trim(),
                  amount: parsedAmount,
                  date: selectedDate,
                  received: received,
                );
                await ref.read(treasuryEntriesProvider.notifier).save(entry);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
