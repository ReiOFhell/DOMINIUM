enum MovementType { entrada, saida }

class AccountMovement {
  AccountMovement({
    required this.id,
    required this.accountId,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  final String id;
  final String accountId;
  final String description;
  final double amount;
  final MovementType type;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountId': accountId,
        'description': description,
        'amount': amount,
        'type': type.name,
        'date': date.toIso8601String(),
      };

  factory AccountMovement.fromMap(Map map) => AccountMovement(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: MovementType.values.byName(map['type'] as String),
        date: DateTime.parse(map['date'] as String),
      );
}

class FinancialAccount {
  FinancialAccount({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String kind;
  final double balance;
  final int colorHex;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'kind': kind,
        'balance': balance,
        'colorHex': colorHex,
      };

  factory FinancialAccount.fromMap(Map map) => FinancialAccount(
        id: map['id'] as String,
        name: map['name'] as String,
        kind: map['kind'] as String,
        balance: (map['balance'] as num).toDouble(),
        colorHex: map['colorHex'] as int? ?? 0xFFB2873F,
      );

  FinancialAccount copyWith({double? balance}) => FinancialAccount(
        id: id,
        name: name,
        kind: kind,
        balance: balance ?? this.balance,
        colorHex: colorHex,
      );
}
