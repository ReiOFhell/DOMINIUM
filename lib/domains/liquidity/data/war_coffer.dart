enum WarCofferType { essencial, divida, reserva, projetos }

class WarCoffer {
  const WarCoffer({
    required this.type,
    required this.weight,
  });

  final WarCofferType type;
  final double weight;

  String get label => switch (type) {
        WarCofferType.essencial => 'Essencial',
        WarCofferType.divida => 'Dívida',
        WarCofferType.reserva => 'Reserva',
        WarCofferType.projetos => 'Projetos',
      };

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'weight': weight,
      };

  factory WarCoffer.fromMap(Map map) => WarCoffer(
        type: WarCofferType.values.byName(map['type'] as String),
        weight: (map['weight'] as num).toDouble(),
      );

  WarCoffer copyWith({double? weight}) => WarCoffer(type: type, weight: weight ?? this.weight);
}

const defaultWarCoffers = <WarCoffer>[
  WarCoffer(type: WarCofferType.essencial, weight: 0.4),
  WarCoffer(type: WarCofferType.divida, weight: 0.3),
  WarCoffer(type: WarCofferType.reserva, weight: 0.2),
  WarCoffer(type: WarCofferType.projetos, weight: 0.1),
];
