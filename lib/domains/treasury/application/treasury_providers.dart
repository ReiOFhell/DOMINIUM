import 'package:dominium/domains/treasury/data/treasury_entry.dart';
import 'package:dominium/domains/treasury/data/treasury_repository.dart';
import 'package:dominium/domains/treasury/data/treasury_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TreasurySort { date, amount, status }

final treasuryRepositoryProvider = Provider<TreasuryRepository>(
  (_) => TreasuryRepository.fromHive(),
);

final treasurySyncServiceProvider = Provider<TreasurySyncService>((ref) {
  return TreasurySyncService(ref.read(treasuryRepositoryProvider));
});

final treasuryEntriesProvider = StateNotifierProvider<TreasuryController, List<TreasuryEntry>>(
  (ref) => TreasuryController(
    ref.read(treasuryRepositoryProvider),
    ref.read(treasurySyncServiceProvider),
  ),
);

final treasurySearchProvider = StateProvider<String>((_) => '');
final treasurySortProvider = StateProvider<TreasurySort>((_) => TreasurySort.date);

final treasuryFilteredProvider = Provider<List<TreasuryEntry>>((ref) {
  final query = ref.watch(treasurySearchProvider).toLowerCase();
  final sort = ref.watch(treasurySortProvider);
  final source = [...ref.watch(treasuryEntriesProvider)]
      .where((e) =>
          e.title.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query) ||
          e.location.toLowerCase().contains(query))
      .toList();

  switch (sort) {
    case TreasurySort.amount:
      source.sort((a, b) => b.amount.compareTo(a.amount));
      break;
    case TreasurySort.status:
      source.sort((a, b) => a.received == b.received ? 0 : (a.received ? -1 : 1));
      break;
    case TreasurySort.date:
      source.sort((a, b) => b.date.compareTo(a.date));
      break;
  }
  return source;
});

class TreasuryController extends StateNotifier<List<TreasuryEntry>> {
  TreasuryController(this._repository, this._syncService) : super(_repository.all());

  final TreasuryRepository _repository;
  final TreasurySyncService _syncService;

  Future<void> save(TreasuryEntry entry) async {
    await _repository.upsertLocal(entry, deviceId: 'flutter-client');
    state = _repository.all();
  }

  Future<void> remove(String id) async {
    await _repository.softDeleteLocal(id, deviceId: 'flutter-client');
    state = _repository.all();
  }

  Future<TreasurySyncReport> syncNow() async {
    final report = await _syncService.sync();
    state = _repository.all();
    return report;
  }
}
