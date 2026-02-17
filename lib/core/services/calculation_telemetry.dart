import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:hive/hive.dart';

class CalculationTelemetry {
  CalculationTelemetry._();

  static Box<Map> get _box => Hive.box<Map>(HiveBootstrap.telemetryBox);

  static Future<void> record({
    required String area,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _box.put(id, {
      'area': area,
      'message': message,
      'context': context ?? <String, dynamic>{},
      'at': DateTime.now().toIso8601String(),
    });
  }
}
