import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/analytics/application/analytics_provider.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/timeline/data/timeline_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final timelineFilterProvider = StateProvider<Set<TimelineDomain>>(
  (_) => TimelineDomain.values.toSet(),
);

final timelineEventsProvider = Provider<List<TimelineEvent>>((ref) {
  final movements = ref.watch(accountsProvider).movements;
  final cards = ref.watch(debtsProvider);
  final directDebts = ref.watch(directDebtsProvider);
  final anomalies = ref.watch(anomalyAlertsProvider);
  final progression = ref.watch(progressionProvider);

  final events = <TimelineEvent>[
    ...movements.map(
      (movement) => TimelineEvent(
        id: 'account-${movement.id}',
        date: movement.date,
        domain: TimelineDomain.contas,
        title: movement.type.name == 'entrada' ? 'Entrada em conta' : 'Saída de conta',
        subtitle: movement.description,
        amount: movement.type.name == 'entrada' ? movement.amount : -movement.amount,
      ),
    ),
    ...cards.expand(
      (card) => card.purchases.map(
        (purchase) => TimelineEvent(
          id: 'card-purchase-${card.id}-${purchase.id}',
          date: purchase.date,
          domain: TimelineDomain.cartao,
          title: 'Compra no cartão ${card.name}',
          subtitle: purchase.description,
          amount: -purchase.amount,
        ),
      ),
    ),
    ...cards.expand(
      (card) => card.payments.map(
        (payment) => TimelineEvent(
          id: 'card-payment-${card.id}-${payment.id}',
          date: payment.date,
          domain: TimelineDomain.pagamentos,
          title: 'Pagamento de fatura ${card.name}',
          subtitle: 'Origem: ${payment.origin.name}',
          amount: -payment.value,
        ),
      ),
    ),
    ...directDebts.map(
      (debt) => TimelineEvent(
        id: 'direct-debt-${debt.id}',
        date: debt.originDate,
        domain: TimelineDomain.dividaDireta,
        title: 'Dívida direta criada: ${debt.name}',
        subtitle: 'Credor: ${debt.creditor}',
        amount: -debt.totalValue,
      ),
    ),
    ...directDebts.expand(
      (debt) => debt.payments.map(
        (payment) => TimelineEvent(
          id: 'direct-payment-${debt.id}-${payment.id}',
          date: payment.date,
          domain: TimelineDomain.pagamentos,
          title: 'Pagamento de dívida direta ${debt.name}',
          subtitle: payment.note,
          amount: -payment.value,
        ),
      ),
    ),
    ...anomalies.asMap().entries.map(
      (entry) => TimelineEvent(
        id: 'anomaly-${entry.key}-${entry.value.hashCode}',
        date: DateTime.now().subtract(Duration(minutes: entry.key)),
        domain: TimelineDomain.anomalias,
        title: 'Alerta de anomalia',
        subtitle: entry.value,
      ),
    ),
    ...progression.dailyImpactHash.entries.map((entry) {
      final date = DateTime.tryParse(entry.key) ?? DateTime.now();
      return TimelineEvent(
        id: 'progress-${entry.key}',
        date: date,
        domain: TimelineDomain.progresso,
        title: 'Pulso de progressão registrado',
        subtitle: 'Impacto diário: ${entry.value} • Nível atual: ${progression.level}',
      );
    }),
  ];

  events.sort((a, b) => b.date.compareTo(a.date));
  return events;
});

final filteredTimelineEventsProvider = Provider<List<TimelineEvent>>((ref) {
  final filters = ref.watch(timelineFilterProvider);
  final events = ref.watch(timelineEventsProvider);
  return events.where((event) => filters.contains(event.domain)).toList();
});

final timelineNotesProvider =
    StateNotifierProvider<TimelineNotesController, Map<String, String>>((_) => TimelineNotesController());

class TimelineNotesController extends StateNotifier<Map<String, String>> {
  TimelineNotesController()
      : _box = Hive.box<Map>(HiveBootstrap.settingsBox),
        super(_load(Hive.box<Map>(HiveBootstrap.settingsBox).get(_storageKey)));

  static const _storageKey = 'timeline_notes';
  final Box<Map> _box;

  static Map<String, String> _load(Map? map) {
    if (map == null || map.isEmpty) return {};
    return map.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> save(String eventId, String note) async {
    final normalized = note.trim();
    final next = {...state};
    if (normalized.isEmpty) {
      next.remove(eventId);
    } else {
      next[eventId] = normalized;
    }

    await _box.put(_storageKey, next);
    state = next;
  }
}
