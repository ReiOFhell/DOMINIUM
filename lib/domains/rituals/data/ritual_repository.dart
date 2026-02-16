import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/rituals/data/ritual_entry.dart';
import 'package:hive/hive.dart';

class RitualRepository {
  RitualRepository(this._box);

  final Box<Map> _box;

  factory RitualRepository.fromHive() => RitualRepository(Hive.box<Map>(HiveBootstrap.ritualsBox));

  List<RitualEntry> all() => _box.values.map(RitualEntry.fromMap).toList();

  Future<void> save(RitualEntry entry) => _box.put(entry.date.toIso8601String(), entry.toMap());
}
