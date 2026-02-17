import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/treasury/data/treasury_entry.dart';
import 'package:hive/hive.dart';

class TreasuryRepository {
  TreasuryRepository(this._box);

  final Box<Map> _box;

  factory TreasuryRepository.fromHive() {
    return TreasuryRepository(Hive.box<Map>(HiveBootstrap.treasuryBox));
  }

  List<TreasuryEntry> all() => _box.values.map(TreasuryEntry.fromMap).toList();

  Future<void> upsert(TreasuryEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<void> delete(String id) => _box.delete(id);
}
