import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/core/services/calculation_telemetry.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:dominium/domains/treasury/data/treasury_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

enum GlobalBackupTrigger { manual, onChange, onStartup, scheduledDaily }

enum GlobalBackupStatus { idle, queued, running, success, failed }

class GlobalBackupState {
  const GlobalBackupState({
    required this.queueSize,
    required this.status,
    required this.lastRunAt,
    required this.lastTrigger,
    required this.lastError,
    required this.coveredDomains,
  });

  final int queueSize;
  final GlobalBackupStatus status;
  final DateTime? lastRunAt;
  final GlobalBackupTrigger? lastTrigger;
  final String? lastError;
  final int coveredDomains;

  factory GlobalBackupState.initial() => const GlobalBackupState(
        queueSize: 0,
        status: GlobalBackupStatus.idle,
        lastRunAt: null,
        lastTrigger: null,
        lastError: null,
        coveredDomains: 0,
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
    int? coveredDomains,
  }) {
    return GlobalBackupState(
      queueSize: queueSize ?? this.queueSize,
      status: status ?? this.status,
      lastRunAt: lastRunAtSet ? lastRunAt : this.lastRunAt,
      lastTrigger: lastTriggerSet ? lastTrigger : this.lastTrigger,
      lastError: lastErrorSet ? lastError : this.lastError,
      coveredDomains: coveredDomains ?? this.coveredDomains,
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
      coveredDomains: map['coveredDomains'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'queueSize': queueSize,
        'status': status.name,
        'lastRunAt': lastRunAt?.toIso8601String(),
        'lastTrigger': lastTrigger?.name,
        'lastError': lastError,
        'coveredDomains': coveredDomains,
      };
}

class GlobalBackupRunResult {
  const GlobalBackupRunResult({
    required this.coveredDomains,
    required this.failedDomains,
    required this.status,
    required this.message,
  });

  final int coveredDomains;
  final List<String> failedDomains;
  final GlobalBackupStatus status;
  final String message;

  bool get hasFailures => failedDomains.isNotEmpty || status == GlobalBackupStatus.failed;
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
  static const _snapshotKey = 'global_backup.last_snapshot';

  final TreasurySyncService _treasurySyncService;
  Future<void>? _ongoingProcess;

  Box<Map> get _settings => Hive.box<Map>(HiveBootstrap.settingsBox);

  static const _backupBoxes = [
    HiveBootstrap.treasuryBox,
    HiveBootstrap.ordersBox,
    HiveBootstrap.campaignsBox,
    HiveBootstrap.ritualsBox,
    HiveBootstrap.debtsBox,
    HiveBootstrap.codexBox,
    HiveBootstrap.progressionBox,
    HiveBootstrap.directDebtsBox,
    HiveBootstrap.accountsBox,
    HiveBootstrap.accountMovementsBox,
    HiveBootstrap.monthlyReportsBox,
  ];

  Future<GlobalBackupRunResult> runManualBackup({void Function(String domain)? onDomain}) async {
    await _enqueue(GlobalBackupTrigger.manual);
    await processPending(onDomain: onDomain);
    final failedDomains = _failedDomainsFromMessage(state.lastError);
    final status = state.status;
    final message = status == GlobalBackupStatus.success
        ? 'Backup finalizado com sucesso.'
        : (state.lastError ?? 'Falha no backup global.');

    return GlobalBackupRunResult(
      coveredDomains: state.coveredDomains,
      failedDomains: failedDomains,
      status: status,
      message: message,
    );
  }

  Future<void> restoreLastBackup() async {
    final snapshot = _settings.get(_snapshotKey);
    if (snapshot == null) {
      throw const GlobalBackupRestoreException('Nenhum backup global encontrado para restaurar.');
    }

    final boxes = Map<String, dynamic>.from(snapshot['boxes'] as Map? ?? const {});

    for (final boxName in _backupBoxes) {
      final box = Hive.box<Map>(boxName);
      await box.clear();

      final rawEntries = boxes[boxName] as List? ?? const [];
      for (final item in rawEntries) {
        final entry = Map<String, dynamic>.from(item as Map);
        final key = entry['key'] as String;
        final value = Map<String, dynamic>.from(entry['value'] as Map? ?? const {});
        await box.put(key, value);
      }
    }

    final lastRunAtRaw = snapshot['createdAt'] as String?;
    await _persistState(state.copyWith(
      status: GlobalBackupStatus.success,
      lastRunAt: lastRunAtRaw == null ? DateTime.now().toUtc() : DateTime.parse(lastRunAtRaw),
      lastRunAtSet: true,
      lastTrigger: GlobalBackupTrigger.manual,
      lastTriggerSet: true,
      lastError: null,
      lastErrorSet: true,
      coveredDomains: _backupBoxes.length,
    ));
  }

  Future<void> processPending({void Function(String domain)? onDomain}) {
    final running = _ongoingProcess;
    if (running != null) return running;

    final task = _processInternal(onDomain: onDomain);
    _ongoingProcess = task;
    return task.whenComplete(() => _ongoingProcess = null);
  }

  Future<void> _processInternal({void Function(String domain)? onDomain}) async {
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
        final snapshotResult = await _captureLocalSnapshot(trigger: job.trigger, onDomain: onDomain);
        onDomain?.call('nuvem: treasury_entries');
        await _treasurySyncService.sync();

        queue.removeAt(0);
        await _writeQueue(queue);
        await _persistState(state.copyWith(
          queueSize: queue.length,
          status: snapshotResult.hasFailures ? GlobalBackupStatus.failed : GlobalBackupStatus.success,
          lastRunAt: DateTime.now().toUtc(),
          lastRunAtSet: true,
          lastTrigger: job.trigger,
          lastTriggerSet: true,
          lastError: snapshotResult.hasFailures
              ? 'Falhas em domínios: ${snapshotResult.failedDomains.join(', ')}'
              : null,
          lastErrorSet: true,
          coveredDomains: snapshotResult.coveredDomains,
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
      }
    }
  }

  Future<GlobalBackupRunResult> _captureLocalSnapshot({
    required GlobalBackupTrigger trigger,
    void Function(String domain)? onDomain,
  }) async {
    final now = DateTime.now().toUtc();
    final boxes = <String, dynamic>{};
    final failedDomains = <String>[];

    for (final boxName in _backupBoxes) {
      onDomain?.call(boxName);
      try {
        final box = Hive.box<Map>(boxName);
        final entries = <Map<String, dynamic>>[];
        for (final key in box.keys) {
          final value = box.get(key);
          if (value == null) continue;
          entries.add({'key': key.toString(), 'value': Map<String, dynamic>.from(value)});
        }
        boxes[boxName] = entries;
      } catch (_) {
        failedDomains.add(boxName);
      }
    }

    await _settings.put(_snapshotKey, {
      'createdAt': now.toIso8601String(),
      'trigger': trigger.name,
      'boxes': boxes,
      'failedDomains': failedDomains,
    });

    return GlobalBackupRunResult(
      coveredDomains: boxes.length,
      failedDomains: failedDomains,
    );
  }

  Future<void> _enqueue(GlobalBackupTrigger trigger) async {
    final queue = _readQueue();
    queue.add(GlobalBackupJob(id: const Uuid().v4(), trigger: trigger, createdAt: DateTime.now().toUtc()));

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

  List<String> _failedDomainsFromMessage(String? message) {
    if (message == null || !message.startsWith('Falhas em domínios:')) return const [];
    return message
        .replaceFirst('Falhas em domínios:', '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class GlobalBackupRestoreException implements Exception {
  const GlobalBackupRestoreException(this.message);
  final String message;
  @override
  String toString() => message;
}
