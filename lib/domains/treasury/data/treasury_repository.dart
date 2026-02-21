import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/treasury/data/treasury_entry.dart';
import 'package:hive/hive.dart';

class TreasuryRepository {
  TreasuryRepository(this._box);

  final Box<Map> _box;

  factory TreasuryRepository.fromHive() {
    return TreasuryRepository(Hive.box<Map>(HiveBootstrap.treasuryBox));
  }

  List<TreasuryEntry> all({bool includeDeleted = false}) {
    final all = _box.values.map(TreasuryEntry.fromMap).toList();
    if (includeDeleted) return all;
    return all.where((entry) => !entry.isDeleted).toList();
  }

  Future<void> upsertLocal(
    TreasuryEntry entry, {
    required String deviceId,
  }) async {
    final existingMap = _box.get(entry.id);
    final now = DateTime.now().toUtc();

    if (existingMap == null) {
      await _box.put(
        entry.id,
        entry
            .copyWith(
              createdAt: entry.createdAt,
              updatedAt: now,
              version: 1,
              deviceId: deviceId,
            )
            .toMap(),
      );
      return;
    }

    final existing = TreasuryEntry.fromMap(existingMap);
    final merged = entry.copyWith(
      createdAt: existing.createdAt,
      updatedAt: now,
      version: existing.version + 1,
      deviceId: deviceId,
    );

    await _box.put(merged.id, merged.toMap());
  }

  Future<void> applyFromSync(TreasuryEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<void> softDeleteLocal(String id, {required String deviceId}) async {
    final existingMap = _box.get(id);
    if (existingMap == null) return;

    final existing = TreasuryEntry.fromMap(existingMap);
    final now = DateTime.now().toUtc();
    final deleted = existing.copyWith(
      updatedAt: now,
      deletedAt: now,
      deletedAtSet: true,
      version: existing.version + 1,
      deviceId: deviceId,
    );
    await _box.put(id, deleted.toMap());
  }
}
