enum PurchaseType { vista, parcelado }
enum PaymentKind { total, parcial, minimo }
enum PaymentOrigin { debito, pix, dinheiro }
enum ChargeType { jurosRotativo, multa, atraso, parcelamentoFatura }
enum DebtState { emDia, atencao, atraso, rotativo, renegociada, quitada }
enum DebtStrategy { pagarTotal, pagarMinimo, pagarParcial, parcelarFatura }

class CardPurchase {
  CardPurchase({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    required this.installments,
    required this.currentInstallment,
    required this.store,
    required this.tags,
  });

  final String id;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final PurchaseType type;
  final int installments;
  final int currentInstallment;
  final String store;
  final List<String> tags;

  double get installmentValue => amount / installments;

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.name,
        'installments': installments,
        'currentInstallment': currentInstallment,
        'store': store,
        'tags': tags,
      };

  factory CardPurchase.fromMap(Map map) => CardPurchase(
        id: map['id'] as String,
        description: map['description'] as String,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        type: PurchaseType.values.byName(map['type'] as String),
        installments: map['installments'] as int,
        currentInstallment: map['currentInstallment'] as int,
        store: map['store'] as String,
        tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      );
}

class InvoiceCycle {
  InvoiceCycle({
    required this.id,
    required this.closingDate,
    required this.dueDate,
    required this.total,
    required this.minimum,
    required this.paid,
    required this.openAmount,
  });

  final String id;
  final DateTime closingDate;
  final DateTime dueDate;
  final double total;
  final double minimum;
  final double paid;
  final double openAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'closingDate': closingDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'total': total,
        'minimum': minimum,
        'paid': paid,
        'openAmount': openAmount,
      };

  factory InvoiceCycle.fromMap(Map map) => InvoiceCycle(
        id: map['id'] as String,
        closingDate: DateTime.parse(map['closingDate'] as String),
        dueDate: DateTime.parse(map['dueDate'] as String),
        total: (map['total'] as num).toDouble(),
        minimum: (map['minimum'] as num).toDouble(),
        paid: (map['paid'] as num).toDouble(),
        openAmount: (map['openAmount'] as num).toDouble(),
      );
}

class DebtPayment {
  DebtPayment({
    required this.id,
    required this.date,
    required this.value,
    required this.kind,
    required this.origin,
    required this.invoiceId,
  });

  final String id;
  final DateTime date;
  final double value;
  final PaymentKind kind;
  final PaymentOrigin origin;
  final String invoiceId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'value': value,
        'kind': kind.name,
        'origin': origin.name,
        'invoiceId': invoiceId,
      };

  factory DebtPayment.fromMap(Map map) => DebtPayment(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        value: (map['value'] as num).toDouble(),
        kind: PaymentKind.values.byName(map['kind'] as String),
        origin: PaymentOrigin.values.byName(map['origin'] as String),
        invoiceId: map['invoiceId'] as String,
      );
}

class DebtCharge {
  DebtCharge({
    required this.id,
    required this.date,
    required this.value,
    required this.type,
    required this.note,
  });

  final String id;
  final DateTime date;
  final double value;
  final ChargeType type;
  final String note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'value': value,
        'type': type.name,
        'note': note,
      };

  factory DebtCharge.fromMap(Map map) => DebtCharge(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        value: (map['value'] as num).toDouble(),
        type: ChargeType.values.byName(map['type'] as String),
        note: map['note'] as String,
      );
}

class DebtCard {
  DebtCard({
    required this.id,
    required this.name,
    required this.limit,
    required this.bank,
    required this.closingDay,
    required this.dueDay,
    required this.defaultInterest,
    required this.iof,
    required this.purchases,
    required this.invoices,
    required this.payments,
    required this.charges,
    required this.state,
  });

  final String id;
  final String name;
  final double limit;
  final String bank;
  final int closingDay;
  final int dueDay;
  final double defaultInterest;
  final double iof;
  final List<CardPurchase> purchases;
  final List<InvoiceCycle> invoices;
  final List<DebtPayment> payments;
  final List<DebtCharge> charges;
  final DebtState state;

  double get openDebt {
    final purchaseTotal = purchases.fold<double>(0, (sum, p) {
      if (p.type == PurchaseType.vista) return sum + p.amount;
      final remaining = p.installments - p.currentInstallment + 1;
      return sum + (p.installmentValue * remaining.clamp(0, p.installments).toDouble());
    });
    final paid = payments.fold<double>(0, (sum, p) => sum + p.value);
    final extra = charges.fold<double>(0, (sum, c) => sum + c.value);
    return (purchaseTotal + extra - paid).clamp(0.0, double.infinity).toDouble();
  }

  double get committedLimitNow => (openDebt / limit).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'limit': limit,
        'bank': bank,
        'closingDay': closingDay,
        'dueDay': dueDay,
        'defaultInterest': defaultInterest,
        'iof': iof,
        'purchases': purchases.map((e) => e.toMap()).toList(),
        'invoices': invoices.map((e) => e.toMap()).toList(),
        'payments': payments.map((e) => e.toMap()).toList(),
        'charges': charges.map((e) => e.toMap()).toList(),
        'state': state.name,
      };

  factory DebtCard.fromMap(Map map) => DebtCard(
        id: map['id'] as String,
        name: map['name'] as String,
        limit: (map['limit'] as num).toDouble(),
        bank: map['bank'] as String,
        closingDay: map['closingDay'] as int,
        dueDay: map['dueDay'] as int,
        defaultInterest: (map['defaultInterest'] as num).toDouble(),
        iof: (map['iof'] as num).toDouble(),
        purchases: ((map['purchases'] as List?) ?? const [])
            .map((e) => CardPurchase.fromMap(e as Map))
            .toList(),
        invoices: ((map['invoices'] as List?) ?? const [])
            .map((e) => InvoiceCycle.fromMap(e as Map))
            .toList(),
        payments: ((map['payments'] as List?) ?? const [])
            .map((e) => DebtPayment.fromMap(e as Map))
            .toList(),
        charges: ((map['charges'] as List?) ?? const [])
            .map((e) => DebtCharge.fromMap(e as Map))
            .toList(),
        state: DebtState.values.byName(map['state'] as String),
      );

  DebtCard copyWith({
    List<CardPurchase>? purchases,
    List<InvoiceCycle>? invoices,
    List<DebtPayment>? payments,
    List<DebtCharge>? charges,
    DebtState? state,
  }) {
    return DebtCard(
      id: id,
      name: name,
      limit: limit,
      bank: bank,
      closingDay: closingDay,
      dueDay: dueDay,
      defaultInterest: defaultInterest,
      iof: iof,
      purchases: purchases ?? this.purchases,
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
      charges: charges ?? this.charges,
      state: state ?? this.state,
    );
  }
}
