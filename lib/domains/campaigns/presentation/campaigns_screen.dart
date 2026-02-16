import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/campaigns/data/campaign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campanhas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref),
        label: const Text('Nova Campanha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: campaigns.isEmpty
            ? const Center(
                child: Text(
                  'Nenhuma campanha ativa. Toda guerra longa começa com um decreto claro.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                itemBuilder: (_, i) {
                  final c = campaigns[i];
                  return GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(c.description),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: c.progress / 100),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${c.status.name} • Progresso: ${c.progress.toStringAsFixed(0)}% • Início: ${DateFormat('dd/MM/yyyy').format(c.startDate)}',
                        ),
                        const SizedBox(height: 8),
                        if (c.milestones.isNotEmpty)
                          Text('Marcos: ${c.milestones.join(' • ')}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: campaigns.length,
              ),
      ),
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final invested = TextEditingController(text: '0');
    final milestones = TextEditingController();
    double progress = 0;
    CampaignStatus status = CampaignStatus.avanco;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Forjar Campanha'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
                const SizedBox(height: 8),
                TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
                const SizedBox(height: 8),
                TextField(
                  controller: invested,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor investido'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: milestones,
                  decoration: const InputDecoration(
                    labelText: 'Marcos (separados por ;)',
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: progress,
                  onChanged: (v) => setState(() => progress = v),
                  max: 100,
                  label: progress.toStringAsFixed(0),
                ),
                DropdownButton<CampaignStatus>(
                  isExpanded: true,
                  value: status,
                  onChanged: (v) => setState(() => status = v ?? CampaignStatus.avanco),
                  items: CampaignStatus.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await ref.read(campaignsProvider.notifier).save(
                      Campaign(
                        id: const Uuid().v4(),
                        name: name.text.trim(),
                        description: description.text.trim(),
                        startDate: DateTime.now(),
                        progress: progress,
                        investedValue: double.tryParse(invested.text) ?? 0,
                        status: status,
                        milestones: milestones.text
                            .split(';')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        orderIds: const [],
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
