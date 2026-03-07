import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/codex/application/codex_provider.dart';
import 'package:dominium/domains/codex/data/codex_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codex = ref.watch(codexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Codex Imperial')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GlassCard(
            child: Text(
              'Biblioteca do Sistema: tudo que foi descoberto, por que existe, quando usar e como dominar.',
            ),
          ),
          const SizedBox(height: 12),
          ...ImperialSystem.values.map(
            (system) {
              final entry = codex[system] ?? CodexEntry.initial(system);
              final meta = _meta(system);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  mood: _mood(entry.state),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(meta.description),
                      const SizedBox(height: 8),
                      Text('Quando usar: ${meta.whenUse}'),
                      Text('Impacto: ${meta.impact}'),
                      const SizedBox(height: 8),
                      Text('Estado: ${_stateLabel(entry.state)} • Uso pessoal: ${entry.uses} vez(es)'),
                      if (entry.lastUsedAt != null)
                        Text('Último uso: ${DateFormat('dd/MM/yyyy HH:mm').format(entry.lastUsedAt!)}'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => ref.read(codexProvider.notifier).registerUsage(system),
                        child: const Text('Iniciar modo guiado'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ImperialMood _mood(KnowledgeState state) {
    return switch (state) {
      KnowledgeState.naoDescoberto => ImperialMood.alerta,
      KnowledgeState.descobertoNaoUsado => ImperialMood.alerta,
      KnowledgeState.usadoSuperficialmente => ImperialMood.calmo,
      KnowledgeState.dominado => ImperialMood.vitoria,
    };
  }

  String _stateLabel(KnowledgeState state) => switch (state) {
        KnowledgeState.naoDescoberto => 'Não descoberto',
        KnowledgeState.descobertoNaoUsado => 'Descoberto, não usado',
        KnowledgeState.usadoSuperficialmente => 'Usado superficialmente',
        KnowledgeState.dominado => 'Dominado',
      };

  _SystemMeta _meta(ImperialSystem s) {
    return switch (s) {
      ImperialSystem.ordens => const _SystemMeta(
          title: 'Ordens Imperiais',
          description: 'Converte intenção em execução rastreável.',
          whenUse: 'Quando há objetivos sem cadência diária.',
          impact: 'Aumenta consistência e reduz dispersão.'),
      ImperialSystem.campanhas => const _SystemMeta(
          title: 'Campanhas',
          description: 'Operações de médio/longo prazo para metas complexas.',
          whenUse: 'Quando ameaça financeira exige estratégia contínua.',
          impact: 'Reduz caos e organiza priorização tática.'),
      ImperialSystem.dividas => const _SystemMeta(
          title: 'Trono das Dívidas',
          description: 'Controle de cartão, faturas, juros e guerra de quitação.',
          whenUse: 'Ao existir saldo em aberto ou risco de rotativo.',
          impact: 'Previne bola de neve e protege o caixa do império.'),
      ImperialSystem.calculadora => const _SystemMeta(
          title: 'Calculadora de Possibilidades',
          description: 'Julga aquisição por cenário e risco.',
          whenUse: 'Antes de compras relevantes ou parcelamentos.',
          impact: 'Evita decisões que comprimem renda futura.'),
      ImperialSystem.loja => const _SystemMeta(
          title: 'Loja Imperial',
          description: 'Camada de recompensas e progressão do sistema.',
          whenUse: 'Quando moeda interna e marcos de execução surgirem.',
          impact: 'Reforça aderência sem infantilização.'),
    };
  }
}

class _SystemMeta {
  const _SystemMeta({
    required this.title,
    required this.description,
    required this.whenUse,
    required this.impact,
  });

  final String title;
  final String description;
  final String whenUse;
  final String impact;
}
