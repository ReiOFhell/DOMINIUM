import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/debts/data/debt_card.dart';
import 'package:hive/hive.dart';

class DebtsRepository {
  DebtsRepository(this._box);

  final Box<Map> _box;

  factory DebtsRepository.fromHive() =>
      DebtsRepository(Hive.box<Map>(HiveBootstrap.debtsBox));

  List<DebtCard> all() => _box.values.map(DebtCard.fromMap).toList();

  Future<void> upsert(DebtCard card) => _box.put(card.id, card.toMap());

  Future<void> delete(String id) => _box.delete(id);
}
