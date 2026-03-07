class RitualEntry {
  RitualEntry({required this.date, required this.text});

  final DateTime date;
  final String text;

  Map<String, dynamic> toMap() => {'date': date.toIso8601String(), 'text': text};

  factory RitualEntry.fromMap(Map map) => RitualEntry(
        date: DateTime.parse(map['date'] as String),
        text: map['text'] as String,
      );
}
