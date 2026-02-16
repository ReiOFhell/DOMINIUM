import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/codex/data/codex_entry.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class MentorIntervention {
  const MentorIntervention({
    required this.system,
    required this.title,
    required this.message,
    required this.action,
  });

  final ImperialSystem system;
  final String title;
  final String message;
  final String action;
}

final codexProvider = StateNotifierProvider<CodexController, Map<ImperialSystem, CodexEntry>>(
  (_) => CodexController(),
);

final mentorInterventionsProvider = Provider<List<MentorIntervention>>((ref) {
  final codex = ref.watch(codexProvider);
  final debts = ref.watch(debtsProvider);
  final campaigns = ref.watch(campaignsProvider);
  final orders = ref.watch(ordersProvider);
  final treasury = ref.watch(treasuryEntriesProvider);

  final interventions = <MentorIntervention>[];

  final debtsOpen = debts.fold<double>(0, (s, c) => s + c.openDebt);
  if (debtsOpen > 0 && campaigns.isEmpty) {
    interventions.add(const MentorIntervention(
      system: ImperialSystem.campanhas,
      title: 'Estrutura sugerida: Campanhas',
      message:
          'Seu Império está sob pressão de dívida. Campanhas são operações estruturadas para neutralizar ameaças financeiras.',
      action: 'Iniciar campanha de contenção',
    ));
  }

  if (debtsOpen > 0 && (codex[ImperialSystem.dividas]?.uses ?? 0) < 2) {
    interventions.add(const MentorIntervention(
      system: ImperialSystem.dividas,
      title: 'Risco de rotativo detectado',
      message:
          'Recomendamos decreto de pagamento guiado. Ignorar este ponto amplia custo por juros e reduz seu poder de comando.',
      action: 'Executar modo guiado de pagamento',
    ));
  }

  if (treasury.isNotEmpty && orders.isEmpty) {
    interventions.add(const MentorIntervention(
      system: ImperialSystem.ordens,
      title: 'Ordem Imperial ainda não utilizada',
      message:
          'Sem ordens, o avanço fica aleatório. Ordens transformam intenção em execução rastreável e disciplina real.',
      action: 'Emitir primeira ordem',
    ));
  }

  return interventions;
});

final pendingRevelationsProvider = Provider<List<ImperialSystem>>((ref) {
  final codex = ref.watch(codexProvider);
  final debts = ref.watch(debtsProvider);
  final campaigns = ref.watch(campaignsProvider);
  final treasury = ref.watch(treasuryEntriesProvider);

  final pending = <ImperialSystem>[];

  if (debts.isNotEmpty &&
      (codex[ImperialSystem.dividas]?.state ?? KnowledgeState.naoDescoberto) ==
          KnowledgeState.naoDescoberto) {
    pending.add(ImperialSystem.dividas);
  }

  if (treasury.isNotEmpty &&
      (codex[ImperialSystem.ordens]?.state ?? KnowledgeState.naoDescoberto) ==
          KnowledgeState.naoDescoberto) {
    pending.add(ImperialSystem.ordens);
  }

  if (debts.isNotEmpty && campaigns.isEmpty &&
      (codex[ImperialSystem.campanhas]?.state ?? KnowledgeState.naoDescoberto) ==
          KnowledgeState.naoDescoberto) {
    pending.add(ImperialSystem.campanhas);
  }

  return pending;
});

class CodexController extends StateNotifier<Map<ImperialSystem, CodexEntry>> {
  CodexController()
      : _box = Hive.box<Map>(HiveBootstrap.codexBox),
        super(_load());

  final Box<Map> _box;

  static Map<ImperialSystem, CodexEntry> _load() {
    final box = Hive.box<Map>(HiveBootstrap.codexBox);
    final map = <ImperialSystem, CodexEntry>{};
    for (final system in ImperialSystem.values) {
      final raw = box.get(system.name);
      map[system] = raw == null ? CodexEntry.initial(system) : CodexEntry.fromMap(raw);
    }
    return map;
  }

  Future<void> reveal(ImperialSystem system) async {
    final current = state[system] ?? CodexEntry.initial(system);
    if (current.state != KnowledgeState.naoDescoberto) return;
    final next = current.copyWith(
      state: KnowledgeState.descobertoNaoUsado,
      discoveredAt: DateTime.now(),
    );
    await _persist(system, next);
  }

  Future<void> registerUsage(ImperialSystem system) async {
    final current = state[system] ?? CodexEntry.initial(system);
    final uses = current.uses + 1;
    final nextState = uses >= 8
        ? KnowledgeState.dominado
        : uses >= 2
            ? KnowledgeState.usadoSuperficialmente
            : KnowledgeState.descobertoNaoUsado;
    final next = current.copyWith(
      state: nextState,
      uses: uses,
      discoveredAt: current.discoveredAt ?? DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
    await _persist(system, next);
  }

  Future<void> _persist(ImperialSystem system, CodexEntry next) async {
    await _box.put(system.name, next.toMap());
    state = {...state, system: next};
  }
}
