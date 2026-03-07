import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/throne/data/empire_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final empireSettingsProvider =
    StateNotifierProvider<EmpireSettingsController, EmpireSettings>(
  (_) => EmpireSettingsController(),
);

class EmpireSettingsController extends StateNotifier<EmpireSettings> {
  EmpireSettingsController()
      : _box = Hive.box<Map>(HiveBootstrap.settingsBox),
        super(EmpireSettings.fromMap(Hive.box<Map>(HiveBootstrap.settingsBox).get('empire')));

  final Box<Map> _box;

  Future<void> update(EmpireSettings next) async {
    await _box.put('empire', next.toMap());
    state = next;
  }
}
