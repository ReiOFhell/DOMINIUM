import 'dart:math';

import 'package:dominium/domains/debts/data/debt_card.dart';
import 'package:dominium/domains/debts/data/debts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((_) => DebtsRepository.fromHive());

final debtsProvider = StateNotifierProvider<DebtsController, List<DebtCard>>(
  (ref) => DebtsController(ref.read(debtsRepositoryProvider)),
);

final debtAlertsProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(debtsProvider);
  final now = DateTime.now();
  final alerts = <String>[];

  for (final card in cards) {
    final daysToClosing = card.closingDay - now.day;
    if (daysToClosing >= 0 && daysToClosing <= 3) {
      alerts.add('${card.name}: fechamento em $daysToClosing dia(s); adiar compras pode aliviar o ciclo atual.');
    }
    if (card.committedLimitNow > 0.75) {
      alerts.add('${card.name}: limite comprometido em ${(card.committedLimitNow * 100).toStringAsFixed(0)}%. Risco de estrangulamento.');
    }
    if (card.state == DebtState.rotativo) {
      alerts.add('${card.name}: rotativo ativo. Prioridade máxima para decreto de quitação.');
    }
  }

  if (alerts.isEmpty) {
    alerts.add('Sem alertas críticos. Mantenha disciplina de fechamento e pagamento total.');
  }
  return alerts;
});

class MonthlyProjection {
  MonthlyProjection({
    required this.month,
    required this.predictedTotal,
    required this.liveInstallments,
    required this.futureCommittedLimit,
  });

  final DateTime month;
  final double predictedTotal;
  final int liveInstallments;
  final double futureCommittedLimit;
}

class PayoffMilestone {
  PayoffMilestone(this.month, this.remaining);

  final DateTime month;
  final double remaining;
}

class DebtsController extends StateNotifier<List<DebtCard>> {
  DebtsController(this._repository) : super(_repository.all());

  final DebtsRepository _repository;

  Future<void> createCard({
    required String name,
    required double limit,
    required String bank,
    required int closingDay,
    required int dueDay,
    required double interest,
    required double iof,
  }) async {
    final now = DateTime.now().toUtc();
    final card = DebtCard(
      id: const Uuid().v4(),
      name: name,
      limit: limit,
      bank: bank,
      closingDay: closingDay,
      dueDay: dueDay,
      defaultInterest: interest,
      iof: iof,
      purchases: const [],
      invoices: const [],
      payments: const [],
      charges: const [],
      state: DebtState.emDia,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      deviceId: 'local-device',
    );
    await _repository.upsert(card);
    state = _repository.all();
  }

  Future<void> registerPurchase({
    required DebtCard card,
    required String description,
    required String category,
    required double amount,
    required DateTime date,
    required PurchaseType type,
    required int installments,
    required String store,
    required List<String> tags,
  }) async {
    final purchase = CardPurchase(
      id: const Uuid().v4(),
      description: description,
      category: category,
      amount: amount,
      date: date,
      type: type,
      installments: max(1, installments),
      currentInstallment: 1,
      store: store,
      tags: tags,
    );

    final nextInvoices = [...card.invoices];
    final cycle = _resolveInvoiceCycle(card, date);
    final existing = nextInvoices.indexWhere((inv) => inv.id == cycle.id);
    if (existing >= 0) {
      final inv = nextInvoices[existing];
      final add = type == PurchaseType.vista ? amount : amount / max(1, installments);
      nextInvoices[existing] = InvoiceCycle(
        id: inv.id,
        closingDate: inv.closingDate,
        dueDate: inv.dueDate,
        total: inv.total + add,
        minimum: (inv.total + add) * 0.15,
        paid: inv.paid,
        openAmount: (inv.openAmount + add),
      );
    } else {
      final add = type == PurchaseType.vista ? amount : amount / max(1, installments);
      nextInvoices.add(InvoiceCycle(
        id: cycle.id,
        closingDate: cycle.closingDate,
        dueDate: cycle.dueDate,
        total: add,
        minimum: add * 0.15,
        paid: 0,
        openAmount: add,
      ));
    }

    final stateByRisk = (card.openDebt + amount) / card.limit > 0.85
        ? DebtState.atencao
        : card.state;

    await _repository.upsert(card.copyWith(
      purchases: [...card.purchases, purchase],
      invoices: nextInvoices,
      state: stateByRisk,
    ));
    state = _repository.all();
  }

  Future<void> registerPayment({
    required DebtCard card,
    required InvoiceCycle invoice,
    required double value,
    required PaymentKind kind,
    required PaymentOrigin origin,
  }) async {
    final payment = DebtPayment(
      id: const Uuid().v4(),
      date: DateTime.now(),
      value: value,
      kind: kind,
      origin: origin,
      invoiceId: invoice.id,
    );

    final invoices = card.invoices.map((inv) {
      if (inv.id != invoice.id) return inv;
      final paid = inv.paid + value;
      final open = (inv.total - paid).clamp(0, double.infinity).toDouble();
      return InvoiceCycle(
        id: inv.id,
        closingDate: inv.closingDate,
        dueDate: inv.dueDate,
        total: inv.total,
        minimum: inv.minimum,
        paid: paid,
        openAmount: open,
      );
    }).toList();

    final debtState = invoices.every((i) => i.openAmount <= 0)
        ? DebtState.quitada
        : (kind == PaymentKind.minimo ? DebtState.rotativo : DebtState.emDia);

    await _repository.upsert(card.copyWith(
      payments: [...card.payments, payment],
      invoices: invoices,
      state: debtState,
    ));
    state = _repository.all();
  }

  List<MonthlyProjection> projectInvoice(DebtCard card, {int months = 6}) {
    final now = DateTime.now();
    final result = <MonthlyProjection>[];

    for (var i = 0; i < months; i++) {
      final monthDate = DateTime(now.year, now.month + i, 1);
      var total = 0.0;
      var live = 0;

      for (final purchase in card.purchases) {
        if (purchase.type == PurchaseType.vista) {
          final billMonth = _billingMonth(card, purchase.date);
          if (billMonth.year == monthDate.year && billMonth.month == monthDate.month) {
            total += purchase.amount;
          }
          continue;
        }

        final firstBilling = _billingMonth(card, purchase.date);
        final diff = (monthDate.year - firstBilling.year) * 12 + monthDate.month - firstBilling.month;
        if (diff >= 0 && diff < purchase.installments) {
          total += purchase.installmentValue;
          live += 1;
        }
      }

      final committed = (total / card.limit).clamp(0.0, 1.0).toDouble();
      result.add(MonthlyProjection(
        month: monthDate,
        predictedTotal: total,
        liveInstallments: live,
        futureCommittedLimit: committed,
      ));
    }

    return result;
  }

  List<PayoffMilestone> buildWarPlan({
    required DebtCard card,
    required double monthlyBudget,
    int maxMonths = 24,
  }) {
    final timeline = <PayoffMilestone>[];
    var remaining = card.openDebt;
    var cursor = DateTime(DateTime.now().year, DateTime.now().month, 1);

    for (var i = 0; i < maxMonths && remaining > 0; i++) {
      remaining = (remaining * (1 + card.defaultInterest / 100)) - monthlyBudget;
      timeline.add(PayoffMilestone(cursor, remaining.clamp(0.0, double.infinity).toDouble()));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return timeline;
  }

  InvoiceCycle _resolveInvoiceCycle(DebtCard card, DateTime date) {
    final billingMonth = _billingMonth(card, date);
    final closingDate = DateTime(billingMonth.year, billingMonth.month, card.closingDay);
    final dueDate = DateTime(billingMonth.year, billingMonth.month, card.dueDay);
    return InvoiceCycle(
      id: '${card.id}-${billingMonth.year}-${billingMonth.month}',
      closingDate: closingDate,
      dueDate: dueDate,
      total: 0,
      minimum: 0,
      paid: 0,
      openAmount: 0,
    );
  }

  DateTime _billingMonth(DebtCard card, DateTime purchaseDate) {
    if (purchaseDate.day <= card.closingDay) {
      return DateTime(purchaseDate.year, purchaseDate.month, 1);
    }
    return DateTime(purchaseDate.year, purchaseDate.month + 1, 1);
  }
}
