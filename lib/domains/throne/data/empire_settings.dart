enum ImperialPalette { crimson, royal }

class EmpireSettings {
  const EmpireSettings({
    required this.throneLabel,
    required this.treasuryLabel,
    required this.ordersLabel,
    required this.campaignsLabel,
    required this.palette,
  });

  final String throneLabel;
  final String treasuryLabel;
  final String ordersLabel;
  final String campaignsLabel;
  final ImperialPalette palette;

  static const defaults = EmpireSettings(
    throneLabel: 'Trono',
    treasuryLabel: 'Tesouro',
    ordersLabel: 'Ordens',
    campaignsLabel: 'Campanhas',
    palette: ImperialPalette.crimson,
  );

  Map<String, dynamic> toMap() => {
        'throneLabel': throneLabel,
        'treasuryLabel': treasuryLabel,
        'ordersLabel': ordersLabel,
        'campaignsLabel': campaignsLabel,
        'palette': palette.name,
      };

  factory EmpireSettings.fromMap(Map? map) {
    if (map == null || map.isEmpty) return defaults;
    return EmpireSettings(
      throneLabel: map['throneLabel'] as String? ?? defaults.throneLabel,
      treasuryLabel: map['treasuryLabel'] as String? ?? defaults.treasuryLabel,
      ordersLabel: map['ordersLabel'] as String? ?? defaults.ordersLabel,
      campaignsLabel: map['campaignsLabel'] as String? ?? defaults.campaignsLabel,
      palette: ImperialPalette.values.byName(
        map['palette'] as String? ?? defaults.palette.name,
      ),
    );
  }

  EmpireSettings copyWith({
    String? throneLabel,
    String? treasuryLabel,
    String? ordersLabel,
    String? campaignsLabel,
    ImperialPalette? palette,
  }) {
    return EmpireSettings(
      throneLabel: throneLabel ?? this.throneLabel,
      treasuryLabel: treasuryLabel ?? this.treasuryLabel,
      ordersLabel: ordersLabel ?? this.ordersLabel,
      campaignsLabel: campaignsLabel ?? this.campaignsLabel,
      palette: palette ?? this.palette,
    );
  }
}
