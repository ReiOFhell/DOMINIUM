import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/liquidity/data/war_coffer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class WarBudgetSummary {
  const WarBudgetSummary({
    required this.coffers,
    required this.totalBalance,
    required this.openDebts,
    required this.essentialAllocated,
    required this.debtAllocated,
    required this.criticalCommitments,
    required this.warFreeBalance,
  });

  final List<(WarCoffer coffer, double allocated)> coffers;
  final double totalBalance;
  final double openDebts;
  final double essentialAllocated;
  final double debtAllocated;
  final double criticalCommitments;
  final double warFreeBalance;
}

final warCoffersProvider =
    StateNotifierProvider<WarCoffersController, List<WarCoffer>>((_) => WarCoffersController());

final warBudgetSummaryProvider = Provider<WarBudgetSummary>((ref) {
  final coffers = ref.watch(warCoffersProvider);
  final totalBalance = ref.watch(accountsProvider).totalBalance;
  final openCardDebts = ref.watch(debtsProvider).fold<double>(0, (sum, debt) => sum + debt.openDebt);
  final directDebts = ref.watch(totalDirectDebtsProvider);
  final openDebts = openCardDebts + directDebts;

  final allocations = [
    for (final coffer in coffers) (coffer, totalBalance * coffer.weight),
  ];

  double allocatedOf(WarCofferType type) {
    final match = allocations.where((entry) => entry.$1.type == type);
    if (match.isEmpty) return 0;
    return match.first.$2;
  }

  final essentialAllocated = allocatedOf(WarCofferType.essencial);
  final debtAllocated = allocatedOf(WarCofferType.divida);
  final criticalCommitments = essentialAllocated + (openDebts > debtAllocated ? openDebts : debtAllocated);
  final warFreeBalance = totalBalance - criticalCommitments;

  return WarBudgetSummary(
    coffers: allocations,
    totalBalance: totalBalance,
    openDebts: openDebts,
    essentialAllocated: essentialAllocated,
    debtAllocated: debtAllocated,
    criticalCommitments: criticalCommitments,
    warFreeBalance: warFreeBalance,
  );
});

class WarCoffersController extends StateNotifier<List<WarCoffer>> {
  WarCoffersController()
      : _box = Hive.box<Map>(HiveBootstrap.settingsBox),
        super(_load(Hive.box<Map>(HiveBootstrap.settingsBox).get(_storageKey)));

  static const _storageKey = 'war_coffers';
  final Box<Map> _box;

  static List<WarCoffer> _load(Map? map) {
    if (map == null || map.isEmpty) return defaultWarCoffers;
    final raw = (map['items'] as List?)?.cast<Map>() ?? const [];
    final parsed = raw.map(WarCoffer.fromMap).toList();
    if (parsed.length != WarCofferType.values.length) return defaultWarCoffers;
    return parsed;
  }

  Future<void> rebalancePercentages(Map<WarCofferType, double> percentages) async {
    final sanitized = <WarCofferType, double>{};
    var total = 0.0;
    for (final type in WarCofferType.values) {
      final value = percentages[type] ?? 0;
      final safe = value < 0 ? 0.0 : value.toDouble();
      sanitized[type] = safe;
      total += safe;
    }

    if (total <= 0) {
      sanitized
        ..[WarCofferType.essencial] = 40.0
        ..[WarCofferType.divida] = 30.0
        ..[WarCofferType.reserva] = 20.0
        ..[WarCofferType.projetos] = 10.0;
      total = 100.0;
    }

    final updated = [
      for (final type in WarCofferType.values)
        WarCoffer(type: type, weight: (sanitized[type]! / total).toDouble()),
    ];

    await _box.put(_storageKey, {
      'items': updated.map((coffer) => coffer.toMap()).toList(),
    });
    state = updated;
  }
}
