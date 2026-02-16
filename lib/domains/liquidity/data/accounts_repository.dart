import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/liquidity/data/account.dart';
import 'package:hive/hive.dart';

class AccountsRepository {
  AccountsRepository(this._accounts, this._movements);

  final Box<Map> _accounts;
  final Box<Map> _movements;

  factory AccountsRepository.fromHive() => AccountsRepository(
        Hive.box<Map>(HiveBootstrap.accountsBox),
        Hive.box<Map>(HiveBootstrap.accountMovementsBox),
      );

  List<FinancialAccount> accounts() => _accounts.values.map(FinancialAccount.fromMap).toList();

  List<AccountMovement> movements() => _movements.values.map(AccountMovement.fromMap).toList();

  Future<void> upsertAccount(FinancialAccount account) => _accounts.put(account.id, account.toMap());

  Future<void> addMovement(AccountMovement movement) => _movements.put(movement.id, movement.toMap());
}
