enum ImperialSystem { ordens, campanhas, dividas, calculadora, loja }

enum KnowledgeState {
  naoDescoberto,
  descobertoNaoUsado,
  usadoSuperficialmente,
  dominado,
}

class CodexEntry {
  const CodexEntry({
    required this.system,
    required this.state,
    required this.uses,
    this.discoveredAt,
    this.lastUsedAt,
  });

  final ImperialSystem system;
  final KnowledgeState state;
  final int uses;
  final DateTime? discoveredAt;
  final DateTime? lastUsedAt;

  static CodexEntry initial(ImperialSystem system) => CodexEntry(
        system: system,
        state: KnowledgeState.naoDescoberto,
        uses: 0,
      );

  Map<String, dynamic> toMap() => {
        'system': system.name,
        'state': state.name,
        'uses': uses,
        'discoveredAt': discoveredAt?.toIso8601String(),
        'lastUsedAt': lastUsedAt?.toIso8601String(),
      };

  factory CodexEntry.fromMap(Map map) => CodexEntry(
        system: ImperialSystem.values.byName(map['system'] as String),
        state: KnowledgeState.values.byName(map['state'] as String),
        uses: map['uses'] as int? ?? 0,
        discoveredAt: map['discoveredAt'] == null
            ? null
            : DateTime.parse(map['discoveredAt'] as String),
        lastUsedAt: map['lastUsedAt'] == null
            ? null
            : DateTime.parse(map['lastUsedAt'] as String),
      );

  CodexEntry copyWith({
    KnowledgeState? state,
    int? uses,
    DateTime? discoveredAt,
    DateTime? lastUsedAt,
  }) {
    return CodexEntry(
      system: system,
      state: state ?? this.state,
      uses: uses ?? this.uses,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
