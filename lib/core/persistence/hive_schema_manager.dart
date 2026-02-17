import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:hive/hive.dart';

class HiveSchemaManager {
  HiveSchemaManager._();

  static const currentVersion = 2;
  static const _metaKey = '_schema_meta';

  static Future<void> migrate() async {
    final settings = Hive.box<Map>(HiveBootstrap.settingsBox);
    final meta = settings.get(_metaKey);
    var version = (meta?['version'] as int?) ?? 0;

    while (version < currentVersion) {
      final next = version + 1;
      switch (next) {
        case 1:
          await _migrateWarCoffers(settings);
        case 2:
          await _migrateTimelineNotes(settings);
      }
      version = next;
      await settings.put(_metaKey, {'version': version, 'migratedAt': DateTime.now().toIso8601String()});
    }
  }

  static Future<void> _migrateWarCoffers(Box<Map> settings) async {
    final coffers = settings.get('war_coffers');
    if (coffers == null || coffers.isEmpty) return;
    final items = (coffers['items'] as List?)?.cast<Map>() ?? const [];
    final normalized = [
      for (final item in items)
        {
          'type': item['type'],
          'weight': (item['weight'] as num?)?.toDouble() ?? 0.0,
        },
    ];
    await settings.put('war_coffers', {'items': normalized});
  }

  static Future<void> _migrateTimelineNotes(Box<Map> settings) async {
    final notes = settings.get('timeline_notes');
    if (notes == null || notes.isEmpty) return;
    final normalized = notes.map((key, value) => MapEntry(key.toString(), value.toString()));
    await settings.put('timeline_notes', normalized);
  }
}
