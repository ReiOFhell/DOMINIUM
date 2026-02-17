import 'package:dominium/domains/rituals/data/ritual_entry.dart';
import 'package:dominium/domains/rituals/data/ritual_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ritualRepositoryProvider = Provider<RitualRepository>((_) => RitualRepository.fromHive());

final ritualsProvider = StateNotifierProvider<RitualController, List<RitualEntry>>(
  (ref) => RitualController(ref.read(ritualRepositoryProvider)),
);

class RitualController extends StateNotifier<List<RitualEntry>> {
  RitualController(this._repository) : super(_repository.all());

  final RitualRepository _repository;

  Future<void> saveToday(String text) async {
    final entry = RitualEntry(date: DateTime.now(), text: text);
    await _repository.save(entry);
    state = _repository.all();
  }
}
