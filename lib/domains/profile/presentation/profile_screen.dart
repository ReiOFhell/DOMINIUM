import 'package:dominium/domains/auth/application/auth_controller.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/codex/application/codex_provider.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts_direct/application/direct_debts_provider.dart';
import 'package:dominium/domains/liquidity/application/accounts_provider.dart';
import 'package:dominium/domains/monthly_closure/application/monthly_closure_provider.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/profile/application/profile_backup_controller.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/rituals/application/ritual_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final backupState = ref.watch(profileBackupControllerProvider);
    final backupController = ref.read(profileBackupControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identidade Imperial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Email: ${user?.email ?? 'modo offline'}'),
                  const SizedBox(height: 8),
                  Text('ID do usuário: ${user?.id ?? 'não autenticado'}'),
                  const SizedBox(height: 8),
                  Text('Último login: ${user?.lastSignInAt ?? 'indisponível'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup global por Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Último backup: ${_lastRunLabel(backupState.lastRunAt)}'),
                  const SizedBox(height: 6),
                  Text('Status: ${_statusLabel(backupState.status)}'),
                  const SizedBox(height: 6),
                  Text('Origem: ${_triggerLabel(backupState.lastTrigger)}'),
                  const SizedBox(height: 6),
                  Text('Fila pendente: ${backupState.queueSize} job(s)'),
                  const SizedBox(height: 6),
                  Text('Domínios cobertos: ${backupState.coveredDomains}'),
                  if (backupState.lastError != null) ...[
                    const SizedBox(height: 8),
                    Text('Última falha: ${backupState.lastError}', style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: backupState.status == GlobalBackupStatus.running
                        ? null
                        : () => _showBackupProgressDialog(context, ref, backupController),
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(backupState.status == GlobalBackupStatus.running
                        ? 'Executando backup...'
                        : 'Backup global agora'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: backupState.status == GlobalBackupStatus.running
                        ? null
                        : () async {
                            try {
                              await backupController.restoreLastBackup();
                              _refreshDomains(ref);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Último backup restaurado e domínios recarregados.')),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                              }
                            }
                          },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar último backup'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: user == null
                ? null
                : () async {
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Encerrar sessão'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupProgressDialog(
    BuildContext context,
    WidgetRef ref,
    ProfileBackupController backupController,
  ) async {
    final steps = <String>[];
    var started = false;
    var done = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> startIfNeeded() async {
            if (started) return;
            started = true;
            setState(() => steps.add('Iniciando backup global...'));

            try {
              final result = await backupController.runManualBackup(onDomain: (domain) {
                if (dialogContext.mounted) {
                  setState(() => steps.add('Processando: $domain'));
                }
              });

              if (!dialogContext.mounted) return;
              if (result.hasFailures) {
                final details = result.failedDomains.isEmpty
                    ? result.message
                    : 'Falha em: ${result.failedDomains.join(', ')}';
                setState(() => steps.add(details));
              } else {
                setState(() => steps.add(result.message));
              }
            } catch (error) {
              if (dialogContext.mounted) {
                setState(() => steps.add('Falha no backup: $error'));
              }
            } finally {
              if (dialogContext.mounted) {
                setState(() => done = true);
              }
            }
          }

          startIfNeeded();

          return AlertDialog(
            title: const Text('Backup global em andamento'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!done) const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: steps.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• ${steps[i]}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: done
                    ? () {
                        Navigator.of(dialogContext).pop();
                        _refreshDomains(ref);
                      }
                    : null,
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _refreshDomains(WidgetRef ref) {
    ref.invalidate(treasuryEntriesProvider);
    ref.invalidate(ordersProvider);
    ref.invalidate(campaignsProvider);
    ref.invalidate(ritualsProvider);
    ref.invalidate(debtsProvider);
    ref.invalidate(codexProvider);
    ref.invalidate(progressionProvider);
    ref.invalidate(directDebtsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(monthlyReportsProvider);
  }

  static String _lastRunLabel(DateTime? date) {
    if (date == null) return 'nunca executado';
    return date.toLocal().toIso8601String();
  }

  static String _statusLabel(GlobalBackupStatus status) => switch (status) {
        GlobalBackupStatus.idle => 'ocioso',
        GlobalBackupStatus.queued => 'pendente',
        GlobalBackupStatus.running => 'em execução',
        GlobalBackupStatus.success => 'ok',
        GlobalBackupStatus.failed => 'falha',
      };

  static String _triggerLabel(GlobalBackupTrigger? trigger) => switch (trigger) {
        null => 'indefinido',
        GlobalBackupTrigger.manual => 'manual',
        GlobalBackupTrigger.onChange => 'auto on-change',
        GlobalBackupTrigger.onStartup => 'auto on-startup',
        GlobalBackupTrigger.scheduledDaily => 'agendado diário',
      };
}
