import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/monthly_closure/data/monthly_report.dart';
import 'package:hive/hive.dart';

class MonthlyReportRepository {
  MonthlyReportRepository(this._box);

  final Box<Map> _box;

  factory MonthlyReportRepository.fromHive() =>
      MonthlyReportRepository(Hive.box<Map>(HiveBootstrap.monthlyReportsBox));

  List<MonthlyReport> all() => _box.values.map(MonthlyReport.fromMap).toList()
    ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

  Future<void> save(MonthlyReport report) => _box.put(report.id, report.toMap());
}
