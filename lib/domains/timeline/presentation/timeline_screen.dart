import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/timeline/application/timeline_provider.dart';
import 'package:dominium/domains/timeline/data/timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(filteredTimelineEventsProvider);
    final activeFilters = ref.watch(timelineFilterProvider);
    final notes = ref.watch(timelineNotesProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline Financeira Unificada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtros por domínio', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final domain in TimelineDomain.values)
                      FilterChip(
                        selected: activeFilters.contains(domain),
                        label: Text(_label(domain)),
                        onSelected: (_) {
                          final next = {...activeFilters};
                          if (next.contains(domain)) {
                            if (next.length > 1) next.remove(domain);
                          } else {
                            next.add(domain);
                          }
                          ref.read(timelineFilterProvider.notifier).state = next;
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const GlassCard(child: Text('Sem eventos para os filtros selecionados.'))
          else
            ...events.map((event) {
              final note = notes[event.id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  mood: _mood(event.domain),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM HH:mm').format(event.date),
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.subtitle),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(event.domainLabel, style: const TextStyle(fontSize: 11)),
                          ),
                          const Spacer(),
                          if (event.amount != null)
                            Text(
                              currency.format(event.amount),
                              style: TextStyle(
                                color: (event.amount ?? 0) >= 0 ? DominiumTheme.gold : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note == null || note.isEmpty ? 'Sem anotação.' : 'Nota: $note',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _quickNote(context, ref, event, note ?? ''),
                            child: const Text('Anotar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _quickNote(
    BuildContext context,
    WidgetRef ref,
    TimelineEvent event,
    String initial,
  ) async {
    final controller = TextEditingController(text: initial);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anotação rápida'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Nota do evento',
            hintText: 'Ex.: revisar em 3 dias, confirmar comprovante, etc.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(timelineNotesProvider.notifier).save(event.id, controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  String _label(TimelineDomain domain) => switch (domain) {
        TimelineDomain.contas => 'Contas',
        TimelineDomain.cartao => 'Cartão',
        TimelineDomain.dividaDireta => 'Dívida direta',
        TimelineDomain.pagamentos => 'Pagamentos',
        TimelineDomain.anomalias => 'Anomalias',
        TimelineDomain.progresso => 'Progresso',
      };

  ImperialMood _mood(TimelineDomain domain) => switch (domain) {
        TimelineDomain.anomalias => ImperialMood.alerta,
        TimelineDomain.progresso => ImperialMood.calmo,
        TimelineDomain.pagamentos => ImperialMood.calmo,
        TimelineDomain.contas => ImperialMood.neutro,
        TimelineDomain.cartao => ImperialMood.alerta,
        TimelineDomain.dividaDireta => ImperialMood.alerta,
      };
}
