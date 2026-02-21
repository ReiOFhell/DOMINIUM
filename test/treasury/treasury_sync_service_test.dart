import 'package:dominium/domains/treasury/data/treasury_entry.dart';
import 'package:dominium/domains/treasury/data/treasury_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TreasuryEntry buildEntry({
    required String id,
    required DateTime updatedAt,
    required int version,
    required String deviceId,
  }) {
    return TreasuryEntry(
      id: id,
      title: 'Receita',
      description: '',
      location: '',
      amount: 10,
      date: DateTime.utc(2026, 1, 1),
      received: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: updatedAt,
      deletedAt: null,
      version: version,
      deviceId: deviceId,
    );
  }

  test('LWW: updatedAt mais recente vence', () {
    final local = buildEntry(
      id: '1',
      updatedAt: DateTime.utc(2026, 1, 2),
      version: 1,
      deviceId: 'a',
    );
    final remote = buildEntry(
      id: '1',
      updatedAt: DateTime.utc(2026, 1, 3),
      version: 1,
      deviceId: 'b',
    );

    final winner = TreasurySyncService.chooseWinner(local, remote);
    expect(winner, remote);
  });

  test('LWW: empate em updatedAt usa version', () {
    final updated = DateTime.utc(2026, 1, 3);
    final local = buildEntry(id: '1', updatedAt: updated, version: 3, deviceId: 'a');
    final remote = buildEntry(id: '1', updatedAt: updated, version: 2, deviceId: 'z');

    final winner = TreasurySyncService.chooseWinner(local, remote);
    expect(winner, local);
  });

  test('LWW: empate total usa deviceId lexical', () {
    final updated = DateTime.utc(2026, 1, 3);
    final local = buildEntry(id: '1', updatedAt: updated, version: 2, deviceId: 'android-z');
    final remote = buildEntry(id: '1', updatedAt: updated, version: 2, deviceId: 'android-a');

    final winner = TreasurySyncService.chooseWinner(local, remote);
    expect(winner, local);
  });
}
