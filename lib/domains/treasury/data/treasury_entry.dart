class TreasuryEntry {
  TreasuryEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.amount,
    required this.date,
    required this.received,
    this.photoPath,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final double amount;
  final DateTime date;
  final bool received;
  final String? photoPath;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'amount': amount,
        'date': date.toIso8601String(),
        'received': received,
        'photoPath': photoPath,
      };

  factory TreasuryEntry.fromMap(Map map) => TreasuryEntry(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        location: map['location'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        received: map['received'] as bool,
        photoPath: map['photoPath'] as String?,
      );

  TreasuryEntry copyWith({
    String? title,
    String? description,
    String? location,
    double? amount,
    DateTime? date,
    bool? received,
    String? photoPath,
  }) {
    return TreasuryEntry(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      received: received ?? this.received,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
