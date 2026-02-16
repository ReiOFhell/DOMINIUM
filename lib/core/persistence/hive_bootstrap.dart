import 'package:hive_flutter/hive_flutter.dart';

class HiveBootstrap {
  static const treasuryBox = 'treasury_entries';
  static const ordersBox = 'orders';
  static const campaignsBox = 'campaigns';
  static const ritualsBox = 'rituals';
  static const debtsBox = 'debts';
  static const codexBox = 'codex';
  static const progressionBox = 'progression';
  static const directDebtsBox = 'direct_debts';
  static const accountsBox = 'accounts';
  static const accountMovementsBox = 'account_movements';
  static const settingsBox = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(treasuryBox),
      Hive.openBox<Map>(ordersBox),
      Hive.openBox<Map>(campaignsBox),
      Hive.openBox<Map>(ritualsBox),
      Hive.openBox<Map>(debtsBox),
      Hive.openBox<Map>(codexBox),
      Hive.openBox<Map>(progressionBox),
      Hive.openBox<Map>(directDebtsBox),
      Hive.openBox<Map>(accountsBox),
      Hive.openBox<Map>(accountMovementsBox),
      Hive.openBox<Map>(settingsBox),
    ]);
  }
}
