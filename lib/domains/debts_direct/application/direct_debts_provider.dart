import 'package:dominium/domains/debts_direct/data/direct_debt.dart';
import 'package:dominium/domains/debts_direct/data/direct_debts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final directDebtsRepositoryProvider =
    Provider<DirectDebtsRepository>((_) => DirectDebtsRepository.fromHive());

final directDebtsProvider = StateNotifierProvider<DirectDebtsController, List<DirectDebt>>(
  (ref) => DirectDebtsController(ref.read(directDebtsRepositoryProvider)),
);

final totalDirectDebtsProvider = Provider<double>((ref) {
  return ref.watch(directDebtsProvider).fold<double>(0, (s, d) => s + d.remainingValue);
});

class DirectDebtsController extends StateNotifier<List<DirectDebt>> {
  DirectDebtsController(this._repository) : super(_repository.all());

  final DirectDebtsRepository _repository;

  Future<void> createDebt({
    required String name,
    required String description,
    required String creditor,
    required double totalValue,
    DateTime? dueDate,
  }) async {
    final debt = DirectDebt(
      id: const Uuid().v4(),
      name: name,
      description: description,
      creditor: creditor,
      totalValue: totalValue,
      remainingValue: totalValue,
      originDate: DateTime.now(),
      dueDate: dueDate,
      payments: const [],
      state: DirectDebtState.ativa,
    );

    await _repository.upsert(debt);
    state = _repository.all();
  }

  Future<void> addPayment({
    required DirectDebt debt,
    required double value,
    required String note,
  }) async {
    final payment = DirectDebtPayment(
      id: const Uuid().v4(),
      date: DateTime.now(),
      value: value,
      note: note,
    );

    final remaining = (debt.remainingValue - value).clamp(0.0, double.infinity).toDouble();
    final nextState = remaining <= 0
        ? DirectDebtState.quitada
        : (remaining < debt.totalValue ? DirectDebtState.emQuitacao : DirectDebtState.ativa);

    await _repository.upsert(
      debt.copyWith(
        remainingValue: remaining,
        payments: [...debt.payments, payment],
        state: nextState,
      ),
    );
    state = _repository.all();
  }
}
