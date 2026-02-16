import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/core/widgets/glass_card.dart';
import 'package:dominium/domains/progression/application/progression_provider.dart';
import 'package:dominium/domains/progression/data/progression_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionProvider);
    final title = ref.watch(currentImperialTitleProvider);
    final penalty = ref.watch(imperialPenaltyProvider);
    final pulse = ref.watch(progressionPulseProvider);
    final arc = ref.watch(activeCampaignArcProvider);
    final mentor = ref.watch(progressionMentorProvider);
    final items = ref.watch(progressionStoreItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sistema de Progressão Imperial')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            mood: _penaltyMood(penalty),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Nível ${state.level} • XP ${state.xp}/120 • Rango ${title.rank.name.toUpperCase()}'),
                Text('Requisito: ${title.requirement}'),
                Text('Efeito: ${title.effect}'),
                const SizedBox(height: 8),
                Text('Estado do Império: ${_penaltyLabel(penalty)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ordem Imperial (Doutrina)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<ImperialOrderDoctrine>(
                  value: state.order,
                  isExpanded: true,
                  onChanged: (v) => ref.read(progressionProvider.notifier).setOrder(v ?? state.order),
                  items: const [
                    DropdownMenuItem(
                      value: ImperialOrderDoctrine.cofreNegro,
                      child: Text('Ordem do Cofre Negro • Segurança e reserva'),
                    ),
                    DropdownMenuItem(
                      value: ImperialOrderDoctrine.laminaRubra,
                      child: Text('Ordem da Lâmina Rubra • Quitação agressiva'),
                    ),
                    DropdownMenuItem(
                      value: ImperialOrderDoctrine.tronoDourado,
                      child: Text('Ordem do Trono Dourado • Crescimento patrimonial'),
                    ),
                    DropdownMenuItem(
                      value: ImperialOrderDoctrine.conclave,
                      child: Text('Ordem do Conclave • Consistência e ritual'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pontuação por prova real', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _pulse('Crescimento real', pulse[ProgressClass.crescimentoReal] ?? 0, DominiumTheme.gold),
                _pulse('Manutenção estratégica', pulse[ProgressClass.manutencaoEstrategica] ?? 0, Colors.white),
                _pulse('Vitória tática', pulse[ProgressClass.vitoriaTatica] ?? 0, Colors.redAccent),
                _pulse('Disciplina', pulse[ProgressClass.disciplina] ?? 0, Colors.lightBlueAccent),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    await ref.read(progressionProvider.notifier).syncFromPulse(pulse);
                    await ref.read(progressionProvider.notifier).applyPenalty(penalty);
                  },
                  child: const Text('Consolidar progresso do ciclo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            mood: ImperialMood.alerta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Campanha do Arco (automática)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Objetivo Supremo: ${arc.supremeGoal}'),
                const SizedBox(height: 6),
                ...arc.weeklyMissions.map((m) => Text('• $m')),
                const SizedBox(height: 6),
                Text('Chefe do Arco: ${arc.bossChallenge}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Economia do Império', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _currencySeal('Glória', state.currencies.gloria, DominiumTheme.gold),
                    _currencySeal('Disciplina', state.currencies.disciplina, Colors.white),
                    _currencySeal('Influência', state.currencies.influencia, Colors.lightBlueAccent),
                    _currencySeal('Selos', state.currencies.selos, Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loja Imperial', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final unlocked = state.storeUnlocks.contains(item.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.name} • ${item.category}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(item.effect),
                          Text('Custo: ${item.price} ${item.currency} • Nível mínimo: ${item.minLevel}'),
                          const SizedBox(height: 6),
                          FilledButton.tonal(
                            onPressed: unlocked
                                ? null
                                : () async {
                                    final ok = await ref.read(progressionProvider.notifier).buyItem(item);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(ok ? 'Item adquirido com sucesso.' : 'Condições insuficientes para aquisição.')),
                                      );
                                    }
                                  },
                            child: Text(unlocked ? 'Adquirido' : 'Adquirir'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mentor Estratégico do Progresso', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...mentor.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $m'),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulse(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _currencySeal(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
        color: Colors.black.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  ImperialMood _penaltyMood(PenaltyLevel level) => switch (level) {
        PenaltyLevel.none => ImperialMood.vitoria,
        PenaltyLevel.warning => ImperialMood.alerta,
        PenaltyLevel.severe => ImperialMood.critico,
        PenaltyLevel.critical => ImperialMood.critico,
      };

  String _penaltyLabel(PenaltyLevel level) => switch (level) {
        PenaltyLevel.none => 'Estável',
        PenaltyLevel.warning => 'Atenção',
        PenaltyLevel.severe => 'Severo',
        PenaltyLevel.critical => 'Crítico',
      };
}
