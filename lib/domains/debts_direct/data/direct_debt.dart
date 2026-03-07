enum DirectDebtState { ativa, emQuitacao, quitada, atrasada }

class DirectDebtPayment {
  DirectDebtPayment({
    required this.id,
    required this.date,
    required this.value,
    required this.note,
  });

  final String id;
  final DateTime date;
  final double value;
  final String note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'value': value,
        'note': note,
      };

  factory DirectDebtPayment.fromMap(Map map) => DirectDebtPayment(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        value: (map['value'] as num).toDouble(),
        note: map['note'] as String,
      );
}

class DirectDebt {
  DirectDebt({
    required this.id,
    required this.name,
    required this.description,
    required this.creditor,
    required this.totalValue,
    required this.remainingValue,
    required this.originDate,
    this.dueDate,
    required this.payments,
    required this.state,
  });

  final String id;
  final String name;
  final String description;
  final String creditor;
  final double totalValue;
  final double remainingValue;
  final DateTime originDate;
  final DateTime? dueDate;
  final List<DirectDebtPayment> payments;
  final DirectDebtState state;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'creditor': creditor,
        'totalValue': totalValue,
        'remainingValue': remainingValue,
        'originDate': originDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'payments': payments.map((e) => e.toMap()).toList(),
        'state': state.name,
      };

  factory DirectDebt.fromMap(Map map) => DirectDebt(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        creditor: map['creditor'] as String,
        totalValue: (map['totalValue'] as num).toDouble(),
        remainingValue: (map['remainingValue'] as num).toDouble(),
        originDate: DateTime.parse(map['originDate'] as String),
        dueDate: map['dueDate'] == null ? null : DateTime.parse(map['dueDate'] as String),
        payments: ((map['payments'] as List?) ?? const [])
            .map((e) => DirectDebtPayment.fromMap(e as Map))
            .toList(),
        state: DirectDebtState.values.byName(map['state'] as String),
      );

  DirectDebt copyWith({
    double? remainingValue,
    List<DirectDebtPayment>? payments,
    DirectDebtState? state,
  }) {
    return DirectDebt(
      id: id,
      name: name,
      description: description,
      creditor: creditor,
      totalValue: totalValue,
      remainingValue: remainingValue ?? this.remainingValue,
      originDate: originDate,
      dueDate: dueDate,
      payments: payments ?? this.payments,
      state: state ?? this.state,
    );
  }
}
