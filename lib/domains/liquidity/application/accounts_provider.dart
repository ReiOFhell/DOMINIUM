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

enum MovementExecutionStatus { executed, warning, blocked }

class MovementExecutionResult {
  const MovementExecutionResult({required this.status, required this.message});

  final MovementExecutionStatus status;
  final String message;

  bool get applied => status != MovementExecutionStatus.blocked;
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

  Future<MovementExecutionResult> move({
    required FinancialAccount account,
    required String description,
    required double amount,
    required MovementType type,
    double? essentialGuardBalance,
    double? warningGuardBalance,
  }) async {
    final projectedTotal = state.totalBalance + (type == MovementType.entrada ? amount : -amount);

    if (type == MovementType.saida && essentialGuardBalance != null && projectedTotal < essentialGuardBalance) {
      return const MovementExecutionResult(
        status: MovementExecutionStatus.blocked,
        message: 'Bloqueado: saída ameaça o cofre Essencial.',
      );
    }

    final updatedBalance = account.balance + (type == MovementType.entrada ? amount : -amount);
    if (updatedBalance < 0) {
      return const MovementExecutionResult(
        status: MovementExecutionStatus.blocked,
        message: 'Bloqueado: conta não pode ficar negativa.',
      );
    }

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

    if (type == MovementType.saida && warningGuardBalance != null && projectedTotal < warningGuardBalance) {
      return const MovementExecutionResult(
        status: MovementExecutionStatus.warning,
        message: 'Alerta: saída encosta no limite do cofre Essencial.',
      );
    }

    return const MovementExecutionResult(
      status: MovementExecutionStatus.executed,
      message: 'Movimento executado dentro dos limites.',
    );
  }

  void _refresh() {
    state = AccountsState(accounts: _repository.accounts(), movements: _repository.movements());
  }
}
