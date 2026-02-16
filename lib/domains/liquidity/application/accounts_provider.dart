import 'package:dominium/domains/liquidity/data/account.dart';
import 'package:dominium/domains/liquidity/data/accounts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AccountsState {
  AccountsState({required this.accounts, required this.movements});

  final List<FinancialAccount> accounts;
  final List<AccountMovement> movements;

  double get totalBalance => accounts.fold<double>(0, (s, a) => s + a.balance);
}

final accountsRepositoryProvider = Provider<AccountsRepository>((_) => AccountsRepository.fromHive());

final accountsProvider = StateNotifierProvider<AccountsController, AccountsState>(
  (ref) => AccountsController(ref.read(accountsRepositoryProvider)),
);

final realBalanceHistoryProvider = Provider<List<(DateTime, double)>>((ref) {
  final movements = ref.watch(accountsProvider).movements..sort((a, b) => a.date.compareTo(b.date));
  double running = 0;
  final history = <(DateTime, double)>[];
  for (final m in movements) {
    running += m.type == MovementType.entrada ? m.amount : -m.amount;
    history.add((m.date, running));
  }
  return history;
});

class AccountsController extends StateNotifier<AccountsState> {
  AccountsController(this._repository)
      : super(AccountsState(accounts: _repository.accounts(), movements: _repository.movements()));

  final AccountsRepository _repository;

  Future<void> createAccount({
    required String name,
    required String kind,
    required double initialBalance,
    required int colorHex,
  }) async {
    final account = FinancialAccount(
      id: const Uuid().v4(),
      name: name,
      kind: kind,
      balance: initialBalance,
      colorHex: colorHex,
    );
    await _repository.upsertAccount(account);
    if (initialBalance > 0) {
      await _repository.addMovement(
        AccountMovement(
          id: const Uuid().v4(),
          accountId: account.id,
          description: 'Saldo inicial',
          amount: initialBalance,
          type: MovementType.entrada,
          date: DateTime.now(),
        ),
      );
    }
    _refresh();
  }

  Future<void> move({
    required FinancialAccount account,
    required String description,
    required double amount,
    required MovementType type,
  }) async {
    final updatedBalance = account.balance + (type == MovementType.entrada ? amount : -amount);
    await _repository.upsertAccount(account.copyWith(balance: updatedBalance));
    await _repository.addMovement(
      AccountMovement(
        id: const Uuid().v4(),
        accountId: account.id,
        description: description,
        amount: amount,
        type: type,
        date: DateTime.now(),
      ),
    );
    _refresh();
  }

  void _refresh() {
    state = AccountsState(accounts: _repository.accounts(), movements: _repository.movements());
  }
}
