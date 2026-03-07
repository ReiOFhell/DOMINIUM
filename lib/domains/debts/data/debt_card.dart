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
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.deviceId,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String deviceId;

  bool get isDeleted => deletedAt != null;

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
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'deviceId': deviceId,
      };

  Map<String, dynamic> toRemoteMap({required String ownerId}) => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'limit': limit,
        'bank': bank,
        'closing_day': closingDay,
        'due_day': dueDay,
        'default_interest': defaultInterest,
        'iof': iof,
        'purchases': purchases.map((e) => e.toMap()).toList(),
        'invoices': invoices.map((e) => e.toMap()).toList(),
        'payments': payments.map((e) => e.toMap()).toList(),
        'charges': charges.map((e) => e.toMap()).toList(),
        'state': state.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'version': version,
        'device_id': deviceId,
      };

  factory DebtCard.fromMap(Map map) {
    final now = DateTime.now().toUtc();
    final createdAtRaw = (map['createdAt'] ?? map['created_at']) as String?;
    final updatedAtRaw = (map['updatedAt'] ?? map['updated_at']) as String?;
    final deletedAtRaw = (map['deletedAt'] ?? map['deleted_at']) as String?;

    return DebtCard(
      id: map['id'] as String,
      name: map['name'] as String,
      limit: (map['limit'] as num).toDouble(),
      bank: map['bank'] as String,
      closingDay: (map['closingDay'] ?? map['closing_day']) as int,
      dueDay: (map['dueDay'] ?? map['due_day']) as int,
      defaultInterest: (map['defaultInterest'] ?? map['default_interest'] as num).toDouble(),
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
      createdAt: createdAtRaw == null ? now : DateTime.parse(createdAtRaw),
      updatedAt: updatedAtRaw == null ? now : DateTime.parse(updatedAtRaw),
      deletedAt: deletedAtRaw == null ? null : DateTime.parse(deletedAtRaw),
      version: map['version'] as int? ?? 1,
      deviceId: (map['deviceId'] ?? map['device_id']) as String? ?? 'local-device',
    );
  }

  DebtCard copyWith({
    List<CardPurchase>? purchases,
    List<InvoiceCycle>? invoices,
    List<DebtPayment>? payments,
    List<DebtCharge>? charges,
    DebtState? state,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool deletedAtSet = false,
    int? version,
    String? deviceId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAtSet ? deletedAt : this.deletedAt,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  bool samePayload(DebtCard other) {
    return name == other.name &&
        limit == other.limit &&
        bank == other.bank &&
        closingDay == other.closingDay &&
        dueDay == other.dueDay &&
        defaultInterest == other.defaultInterest &&
        iof == other.iof &&
        state == other.state &&
        purchases.length == other.purchases.length &&
        invoices.length == other.invoices.length &&
        payments.length == other.payments.length &&
        charges.length == other.charges.length &&
        deletedAt == other.deletedAt;
  }
}
