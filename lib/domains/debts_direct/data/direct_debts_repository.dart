import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/debts_direct/data/direct_debt.dart';
import 'package:hive/hive.dart';

class DirectDebtsRepository {
  DirectDebtsRepository(this._box);

  final Box<Map> _box;

  factory DirectDebtsRepository.fromHive() =>
      DirectDebtsRepository(Hive.box<Map>(HiveBootstrap.directDebtsBox));

  List<DirectDebt> all() => _box.values.map(DirectDebt.fromMap).toList();

  Future<void> upsert(DirectDebt debt) => _box.put(debt.id, debt.toMap());
}
