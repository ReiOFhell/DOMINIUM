import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/core/services/calculation_telemetry.dart';
import 'package:dominium/domains/treasury/data/treasury_entry.dart';
import 'package:dominium/domains/treasury/data/treasury_repository.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TreasurySyncService {
  TreasurySyncService(this._repository);

  final TreasuryRepository _repository;

  Box<Map> get _settings => Hive.box<Map>(HiveBootstrap.settingsBox);

  Future<void> sync() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final checkpoint = TreasurySyncCheckpoint.fromMap(
      _settings.get(TreasurySyncCheckpoint.storageKey) ?? const {},
    );

    try {
      final remoteRows = await client
          .from('treasury_entries')
          .select()
          .eq('owner_id', user.id);

      final remoteEntries = remoteRows
          .map((row) => TreasuryEntry.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      final localEntries = _repository.all(includeDeleted: true);
      final localById = {for (final entry in localEntries) entry.id: entry};
      final remoteById = {for (final entry in remoteEntries) entry.id: entry};
      final allIds = {...localById.keys, ...remoteById.keys};

      final pushQueue = <TreasuryEntry>[];
      for (final id in allIds) {
        final local = localById[id];
        final remote = remoteById[id];

        if (local == null && remote != null) {
          await _repository.applyFromSync(remote);
          continue;
        }
        if (remote == null && local != null) {
          pushQueue.add(local);
          continue;
        }
        if (local == null || remote == null) continue;

        final winner = chooseWinner(local, remote);
        if (winner == local) {
          pushQueue.add(local);
        } else {
          await _repository.applyFromSync(remote);
        }
      }

      if (pushQueue.isNotEmpty) {
        final payload = pushQueue.map((entry) => entry.toRemoteMap(ownerId: user.id)).toList();
        await client.from('treasury_entries').upsert(payload, onConflict: 'id');
      }

      final merged = _repository.all(includeDeleted: true);
      final successHash = sha1
          .convert(utf8.encode(jsonEncode(merged.map((entry) => entry.toMap()).toList())))
          .toString();

      final nextCheckpoint = checkpoint.copyWith(
        lastSyncAt: DateTime.now().toUtc(),
        pendingWrites: 0,
        lastSuccessHash: successHash,
      );

      await _settings.put(TreasurySyncCheckpoint.storageKey, nextCheckpoint.toMap());
    } catch (error) {
      await CalculationTelemetry.record(
        area: 'sync.treasury',
        message: 'Falha no sync do domínio treasury.',
        context: {
          'error': error.toString(),
          'lastSyncAt': checkpoint.lastSyncAt?.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  static TreasuryEntry chooseWinner(TreasuryEntry local, TreasuryEntry remote) {
    if (local.updatedAt.isAfter(remote.updatedAt)) return local;
    if (remote.updatedAt.isAfter(local.updatedAt)) return remote;

    if (local.version > remote.version) return local;
    if (remote.version > local.version) return remote;

    return local.deviceId.compareTo(remote.deviceId) >= 0 ? local : remote;
  }
}

class TreasurySyncCheckpoint {
  const TreasurySyncCheckpoint({
    required this.lastSyncAt,
    required this.lastCursor,
    required this.lastSuccessHash,
    required this.pendingWrites,
  });

  static const storageKey = 'sync_state.treasury';

  final DateTime? lastSyncAt;
  final String? lastCursor;
  final String? lastSuccessHash;
  final int pendingWrites;

  factory TreasurySyncCheckpoint.fromMap(Map map) {
    final lastSync = map['lastSyncAt'] as String?;
    return TreasurySyncCheckpoint(
      lastSyncAt: lastSync == null ? null : DateTime.parse(lastSync),
      lastCursor: map['lastCursor'] as String?,
      lastSuccessHash: map['lastSuccessHash'] as String?,
      pendingWrites: map['pendingWrites'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'lastCursor': lastCursor,
        'lastSuccessHash': lastSuccessHash,
        'pendingWrites': pendingWrites,
      };

  TreasurySyncCheckpoint copyWith({
    DateTime? lastSyncAt,
    String? lastCursor,
    String? lastSuccessHash,
    int? pendingWrites,
  }) {
    return TreasurySyncCheckpoint(
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastCursor: lastCursor ?? this.lastCursor,
      lastSuccessHash: lastSuccessHash ?? this.lastSuccessHash,
      pendingWrites: pendingWrites ?? this.pendingWrites,
    );
  }
}
