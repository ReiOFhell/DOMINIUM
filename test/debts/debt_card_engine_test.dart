import 'package:dominium/domains/debts/data/debt_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('openDebt calcula compras, encargos e pagamentos corretamente', () {
    final card = DebtCard(
      id: '1',
      name: 'Card',
      limit: 1000,
      bank: 'Bank',
      closingDay: 10,
      dueDay: 20,
      defaultInterest: 3,
      iof: 0.38,
      purchases: [
        CardPurchase(
          id: 'p1',
          description: 'À vista',
          category: 'geral',
          amount: 200,
          date: DateTime(2026, 1, 1),
          type: PurchaseType.vista,
          installments: 1,
          currentInstallment: 1,
          store: 'Loja',
          tags: const [],
        ),
        CardPurchase(
          id: 'p2',
          description: 'Parcelada',
          category: 'geral',
          amount: 600,
          date: DateTime(2026, 1, 2),
          type: PurchaseType.parcelado,
          installments: 6,
          currentInstallment: 3,
          store: 'Loja',
          tags: const [],
        ),
      ],
      invoices: const [],
      payments: [
        DebtPayment(
          id: 'pay',
          date: DateTime(2026, 1, 10),
          value: 150,
          kind: PaymentKind.parcial,
          origin: PaymentOrigin.pix,
          invoiceId: 'i1',
        ),
      ],
      charges: [
        DebtCharge(
          id: 'c1',
          date: DateTime(2026, 1, 15),
          value: 20,
          type: ChargeType.jurosRotativo,
          note: 'juros',
        ),
      ],
      state: DebtState.emDia,
    );

    // 200 + (600/6 * 4 parcelas restantes = 400) + 20 - 150 = 470
    expect(card.openDebt, 470);
    expect(card.committedLimitNow, closeTo(0.47, 0.0001));
  });
}
