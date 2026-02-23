import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/core/services/calculation_telemetry.dart';
import 'package:dominium/domains/treasury/data/treasury_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:dominium/domains/treasury/application/treasury_providers.dart';

enum GlobalBackupTrigger { manual, onChange, onStartup, scheduledDaily }

enum GlobalBackupStatus { idle, queued, running, success, failed }

class GlobalBackupState {
  const GlobalBackupState({
    required this.queueSize,
    required this.status,
    required this.lastRunAt,
    required this.lastTrigger,
    required this.lastError,
  });

  final int queueSize;
  final GlobalBackupStatus status;
  final DateTime? lastRunAt;
  final GlobalBackupTrigger? lastTrigger;
  final String? lastError;

  factory GlobalBackupState.initial() => const GlobalBackupState(
        queueSize: 0,
        status: GlobalBackupStatus.idle,
        lastRunAt: null,
        lastTrigger: null,
        lastError: null,
      );

  GlobalBackupState copyWith({
    int? queueSize,
    GlobalBackupStatus? status,
    DateTime? lastRunAt,
    bool lastRunAtSet = false,
    GlobalBackupTrigger? lastTrigger,
    bool lastTriggerSet = false,
    String? lastError,
    bool lastErrorSet = false,
  }) {
    return GlobalBackupState(
      queueSize: queueSize ?? this.queueSize,
      status: status ?? this.status,
      lastRunAt: lastRunAtSet ? lastRunAt : this.lastRunAt,
      lastTrigger: lastTriggerSet ? lastTrigger : this.lastTrigger,
      lastError: lastErrorSet ? lastError : this.lastError,
    );
  }

  factory GlobalBackupState.fromMap(Map map) {
    final lastRunAtRaw = map['lastRunAt'] as String?;
    final triggerRaw = map['lastTrigger'] as String?;
    final statusRaw = map['status'] as String?;

    return GlobalBackupState(
      queueSize: map['queueSize'] as int? ?? 0,
      status: statusRaw == null
          ? GlobalBackupStatus.idle
          : GlobalBackupStatus.values.firstWhere(
              (v) => v.name == statusRaw,
              orElse: () => GlobalBackupStatus.idle,
            ),
      lastRunAt: lastRunAtRaw == null ? null : DateTime.parse(lastRunAtRaw),
      lastTrigger: triggerRaw == null
          ? null
          : GlobalBackupTrigger.values.firstWhere(
              (v) => v.name == triggerRaw,
              orElse: () => GlobalBackupTrigger.manual,
            ),
      lastError: map['lastError'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'queueSize': queueSize,
        'status': status.name,
        'lastRunAt': lastRunAt?.toIso8601String(),
        'lastTrigger': lastTrigger?.name,
        'lastError': lastError,
      };
}

class GlobalBackupJob {
  const GlobalBackupJob({
    required this.id,
    required this.trigger,
    required this.createdAt,
  });

  final String id;
  final GlobalBackupTrigger trigger;
  final DateTime createdAt;

  factory GlobalBackupJob.fromMap(Map map) {
    return GlobalBackupJob(
      id: map['id'] as String,
      trigger: GlobalBackupTrigger.values.firstWhere(
        (v) => v.name == map['trigger'],
        orElse: () => GlobalBackupTrigger.manual,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'trigger': trigger.name,
        'createdAt': createdAt.toIso8601String(),
      };
}

final profileBackupControllerProvider =
    StateNotifierProvider<ProfileBackupController, GlobalBackupState>((ref) {
  final controller = ProfileBackupController(ref.read(treasurySyncServiceProvider));
  controller.processPending();
  return controller;
});

class ProfileBackupController extends StateNotifier<GlobalBackupState> {
  ProfileBackupController(this._treasurySyncService) : super(GlobalBackupState.initial()) {
    _hydrateFromDisk();
  }

  static const _stateKey = 'global_backup.state';
  static const _queueKey = 'global_backup.queue';

  final TreasurySyncService _treasurySyncService;
  bool _processing = false;

  Box<Map> get _settings => Hive.box<Map>(HiveBootstrap.settingsBox);

  Future<void> runManualBackup() async {
    await _enqueue(GlobalBackupTrigger.manual);
    await processPending();
  }

  Future<void> processPending() async {
    if (_processing) return;
    _processing = true;

    try {
      while (true) {
        final queue = _readQueue();
        if (queue.isEmpty) {
          final fallbackStatus = state.status == GlobalBackupStatus.running
              ? GlobalBackupStatus.idle
              : state.status;
          await _persistState(state.copyWith(queueSize: 0, status: fallbackStatus));
          break;
        }

        final job = queue.first;
        await _persistState(state.copyWith(
          queueSize: queue.length,
          status: GlobalBackupStatus.running,
          lastTrigger: job.trigger,
          lastTriggerSet: true,
          lastError: null,
          lastErrorSet: true,
        ));

        try {
          await _treasurySyncService.sync();

          queue.removeAt(0);
          await _writeQueue(queue);
          await _persistState(state.copyWith(
            queueSize: queue.length,
            status: GlobalBackupStatus.success,
            lastRunAt: DateTime.now().toUtc(),
            lastRunAtSet: true,
            lastTrigger: job.trigger,
            lastTriggerSet: true,
            lastError: null,
            lastErrorSet: true,
          ));
        } catch (error) {
          queue.removeAt(0);
          await _writeQueue(queue);

          await CalculationTelemetry.record(
            area: 'sync.global_backup',
            message: 'Falha no backup global por perfil.',
            context: {'error': error.toString(), 'trigger': job.trigger.name},
          );

          await _persistState(state.copyWith(
            queueSize: queue.length,
            status: GlobalBackupStatus.failed,
            lastRunAt: DateTime.now().toUtc(),
            lastRunAtSet: true,
            lastTrigger: job.trigger,
            lastTriggerSet: true,
            lastError: error.toString(),
            lastErrorSet: true,
          ));
          break;
        }
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _enqueue(GlobalBackupTrigger trigger) async {
    final queue = _readQueue();
    queue.add(GlobalBackupJob(
      id: const Uuid().v4(),
      trigger: trigger,
      createdAt: DateTime.now().toUtc(),
    ));

    await _writeQueue(queue);
    await _persistState(state.copyWith(
      queueSize: queue.length,
      status: GlobalBackupStatus.queued,
      lastTrigger: trigger,
      lastTriggerSet: true,
    ));
  }

  void _hydrateFromDisk() {
    final persisted = _settings.get(_stateKey);
    final queue = _readQueue();
    if (persisted == null) {
      state = state.copyWith(queueSize: queue.length);
      return;
    }

    state = GlobalBackupState.fromMap(persisted).copyWith(queueSize: queue.length);
  }

  List<GlobalBackupJob> _readQueue() {
    final raw = (_settings.get(_queueKey)?['jobs'] as List?) ?? const [];
    return raw.map((item) => GlobalBackupJob.fromMap(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> _writeQueue(List<GlobalBackupJob> jobs) async {
    await _settings.put(_queueKey, {'jobs': jobs.map((e) => e.toMap()).toList()});
  }

  Future<void> _persistState(GlobalBackupState next) async {
    state = next;
    await _settings.put(_stateKey, next.toMap());
  }
}
