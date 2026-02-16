import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/orders/data/order_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ordens')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrderForm(context, ref),
        label: const Text('Emitir Ordem'),
        icon: const Icon(Icons.add_task),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: orders.isEmpty
            ? const Center(
                child: Text(
                  'Nenhuma ordem emitida. Comece com poucas ordens de alto impacto.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                itemBuilder: (_, i) {
                  final order = orders[i];
                  return GlassCard(
                    child: ListTile(
                      title: Text(order.title),
                      subtitle: Text(
                        '${order.category.name.toUpperCase()} • vence em ${DateFormat('dd/MM').format(order.dueDate)}',
                      ),
                      trailing: Checkbox(
                        value: order.executed,
                        onChanged: (v) {
                          final failedAt = v == true ? null : DateTime.now();
                          ref.read(ordersProvider.notifier).save(
                                order.copyWith(executed: v ?? false, lastFailedAt: failedAt),
                              );
                        },
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: orders.length,
              ),
      ),
    );
  }

  Future<void> _showOrderForm(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final description = TextEditingController();
    DateTime dueDate = DateTime.now();
    OrderCategory category = OrderCategory.mental;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova Ordem Imperial'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Título')),
              const SizedBox(height: 8),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 8),
              DropdownButton<OrderCategory>(
                isExpanded: true,
                value: category,
                onChanged: (v) => setState(() => category = v ?? OrderCategory.mental),
                items: OrderCategory.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),
              ListTile(
                title: Text('Vencimento: ${DateFormat('dd/MM/yyyy').format(dueDate)}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: dueDate,
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                await ref.read(ordersProvider.notifier).save(
                      OrderItem(
                        id: const Uuid().v4(),
                        title: title.text.trim(),
                        description: description.text.trim(),
                        category: category,
                        dueDate: dueDate,
                        executed: false,
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Emitir'),
            ),
          ],
        ),
      ),
    );
  }
}
