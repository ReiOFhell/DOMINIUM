import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts/data/debt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  DebtStrategy selectedStrategy = DebtStrategy.pagarTotal;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(debtsProvider);
    final alerts = ref.watch(debtAlertsProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final totalOpen = cards.fold<double>(0, (sum, c) => sum + c.openDebt);
    final nextDue = cards
        .expand((c) => c.invoices)
        .where((i) => i.openAmount > 0)
        .fold<DateTime?>(null, (closest, inv) {
      if (closest == null || inv.dueDate.isBefore(closest)) return inv.dueDate;
      return closest;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Trono das Dívidas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newCardDialog(context),
        icon: const Icon(Icons.add_card),
        label: const Text('Novo Cartão'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Wrap(
              runSpacing: 12,
              spacing: 24,
              children: [
                _seal('Total em aberto', currency.format(totalOpen), DominiumTheme.gold),
                _seal(
                  'Próximo vencimento',
                  nextDue == null ? 'Sem fatura aberta' : DateFormat('dd/MM').format(nextDue),
                  Colors.white,
                ),
                _seal('Risco', _riskLevel(cards), _riskColor(cards)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sistema de Alertas', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...alerts.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $a'),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _strategyCard(cards),
          const SizedBox(height: 12),
          if (cards.isEmpty)
            const GlassCard(
              child: Text('Nenhum cartão registrado. Institua seu primeiro decreto de dívida.'),
            )
          else
            ...cards.map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _cardTile(card, currency),
                )),
        ],
      ),
    );
  }

  Widget _seal(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _strategyCard(List<DebtCard> cards) {
    final card = cards.isEmpty ? null : cards.first;
    final projection = card == null
        ? const <MonthlyProjection>[]
        : ref.read(debtsProvider.notifier).projectInvoice(card, months: 6);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modo Guerra: Plano de Quitação', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButton<DebtStrategy>(
            value: selectedStrategy,
            isExpanded: true,
            onChanged: (v) => setState(() => selectedStrategy = v ?? DebtStrategy.pagarTotal),
            items: const [
              DropdownMenuItem(value: DebtStrategy.pagarTotal, child: Text('Pagar total sempre que possível')),
              DropdownMenuItem(value: DebtStrategy.pagarMinimo, child: Text('Pagar mínimo (alto risco)')),
              DropdownMenuItem(value: DebtStrategy.pagarParcial, child: Text('Pagar parcial com simulação')),
              DropdownMenuItem(value: DebtStrategy.parcelarFatura, child: Text('Parcelar fatura com comparativo')),
            ],
          ),
          const SizedBox(height: 8),
          if (projection.isNotEmpty)
            ...projection.map(
              (p) => Text(
                '${DateFormat('MM/yy').format(p.month)} • Previsto ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(p.predictedTotal)} • Parcelas vivas ${p.liveInstallments} • Limite ${(p.futureCommittedLimit * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
            )
          else
            const Text('Registre um cartão para gerar projeções de guerra.'),
        ],
      ),
    );
  }

  Widget _cardTile(DebtCard card, NumberFormat currency) {
    return GlassCard(
      child: ExpansionTile(
        title: Text('${card.name} • ${card.bank}'),
        subtitle: Text(
          'Aberto ${currency.format(card.openDebt)} • Limite ${(card.committedLimitNow * 100).toStringAsFixed(0)}%',
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Estado: ${card.state.name}\nFechamento: dia ${card.closingDay} • Vencimento: dia ${card.dueDay}',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () => _purchaseDialog(card),
                child: const Text('Registrar compra'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _paymentDialog(card),
                child: const Text('Decreto de pagamento'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _newCardDialog(BuildContext context) async {
    final name = TextEditingController();
    final bank = TextEditingController();
    final limit = TextEditingController();
    final close = TextEditingController(text: '10');
    final due = TextEditingController(text: '17');
    final juros = TextEditingController(text: '12');
    final iof = TextEditingController(text: '0.38');

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forjar Cartão Imperial'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome do cartão')),
              TextField(controller: bank, decoration: const InputDecoration(labelText: 'Banco')),
              TextField(controller: limit, decoration: const InputDecoration(labelText: 'Limite'), keyboardType: TextInputType.number),
              TextField(controller: close, decoration: const InputDecoration(labelText: 'Dia de fechamento'), keyboardType: TextInputType.number),
              TextField(controller: due, decoration: const InputDecoration(labelText: 'Dia de vencimento'), keyboardType: TextInputType.number),
              TextField(controller: juros, decoration: const InputDecoration(labelText: 'Juros padrão %'), keyboardType: TextInputType.number),
              TextField(controller: iof, decoration: const InputDecoration(labelText: 'IOF/encargos %'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(debtsProvider.notifier).createCard(
                    name: name.text.trim(),
                    limit: double.tryParse(limit.text.replaceAll(',', '.')) ?? 0,
                    bank: bank.text.trim(),
                    closingDay: int.tryParse(close.text) ?? 10,
                    dueDay: int.tryParse(due.text) ?? 17,
                    interest: double.tryParse(juros.text.replaceAll(',', '.')) ?? 0,
                    iof: double.tryParse(iof.text.replaceAll(',', '.')) ?? 0,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseDialog(DebtCard card) async {
    final description = TextEditingController();
    final category = TextEditingController();
    final amount = TextEditingController();
    final store = TextEditingController();
    final tags = TextEditingController();
    PurchaseType type = PurchaseType.vista;
    int installments = 1;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova compra no cartão'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
                TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoria')),
                TextField(controller: amount, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
                TextField(controller: store, decoration: const InputDecoration(labelText: 'Loja / local')),
                TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (;)')),
                DropdownButton<PurchaseType>(
                  isExpanded: true,
                  value: type,
                  onChanged: (v) => setState(() => type = v ?? PurchaseType.vista),
                  items: const [
                    DropdownMenuItem(value: PurchaseType.vista, child: Text('À vista')),
                    DropdownMenuItem(value: PurchaseType.parcelado, child: Text('Parcelado')),
                  ],
                ),
                if (type == PurchaseType.parcelado)
                  Slider(
                    value: installments.toDouble(),
                    min: 2,
                    max: 24,
                    divisions: 22,
                    label: '$installments parcelas',
                    onChanged: (v) => setState(() => installments = v.toInt()),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                await ref.read(debtsProvider.notifier).registerPurchase(
                      card: card,
                      description: description.text.trim(),
                      category: category.text.trim(),
                      amount: double.tryParse(amount.text.replaceAll(',', '.')) ?? 0,
                      date: DateTime.now(),
                      type: type,
                      installments: installments,
                      store: store.text.trim(),
                      tags: tags.text.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _paymentDialog(DebtCard card) async {
    if (card.invoices.isEmpty) return;
    final value = TextEditingController();
    InvoiceCycle invoice = card.invoices.first;
    PaymentKind kind = PaymentKind.total;
    PaymentOrigin origin = PaymentOrigin.pix;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Decreto de pagamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<InvoiceCycle>(
                value: invoice,
                isExpanded: true,
                onChanged: (v) => setState(() => invoice = v ?? invoice),
                items: card.invoices
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text('${DateFormat('MM/yy').format(i.dueDate)} • em aberto R\$ ${i.openAmount.toStringAsFixed(2)}'),
                        ))
                    .toList(),
              ),
              TextField(controller: value, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
              DropdownButton<PaymentKind>(
                isExpanded: true,
                value: kind,
                onChanged: (v) => setState(() => kind = v ?? kind),
                items: PaymentKind.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),
              DropdownButton<PaymentOrigin>(
                isExpanded: true,
                value: origin,
                onChanged: (v) => setState(() => origin = v ?? origin),
                items: PaymentOrigin.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                await ref.read(debtsProvider.notifier).registerPayment(
                      card: card,
                      invoice: invoice,
                      value: double.tryParse(value.text.replaceAll(',', '.')) ?? 0,
                      kind: kind,
                      origin: origin,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Executar'),
            ),
          ],
        ),
      ),
    );
  }

  String _riskLevel(List<DebtCard> cards) {
    final avg = cards.isEmpty
        ? 0.0
        : cards.fold<double>(0, (s, c) => s + c.committedLimitNow) / cards.length;
    if (avg >= 0.85) return 'Crítico';
    if (avg >= 0.65) return 'Alerta';
    if (avg <= 0.25 && cards.isNotEmpty) return 'Vitória';
    return 'Calmo';
  }

  Color _riskColor(List<DebtCard> cards) {
    switch (_riskLevel(cards)) {
      case 'Crítico':
        return Colors.redAccent;
      case 'Alerta':
        return Colors.orangeAccent;
      case 'Vitória':
        return Colors.lightGreenAccent;
      default:
        return Colors.white;
    }
  }
}
