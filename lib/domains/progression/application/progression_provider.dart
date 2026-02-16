import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/codex/application/codex_provider.dart';
import 'package:dominium/domains/debts/application/debts_provider.dart';
import 'package:dominium/domains/debts/data/debt_card.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/progression/data/progression_models.dart';
import 'package:dominium/domains/rituals/application/ritual_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final progressionStoreItemsProvider = Provider<List<StoreItem>>((_) {
  return const [
    StoreItem(
      id: 'oracle_advanced',
      name: 'Oráculo de Projeção Profunda',
      category: 'Oráculos',
      price: 120,
      currency: 'influencia',
      effect: 'Desbloqueia relatórios avançados de risco por 12 meses.',
      minLevel: 3,
    ),
    StoreItem(
      id: 'decree_auto',
      name: 'Decreto de Vigilância',
      category: 'Decretos',
      price: 90,
      currency: 'disciplina',
      effect: 'Ativa lembretes estratégicos automáticos de fechamento e vencimento.',
      minLevel: 2,
    ),
    StoreItem(
      id: 'relic_skin_obsidian',
      name: 'Relíquia: Moldura Ônix',
      category: 'Relíquias',
      price: 80,
      currency: 'gloria',
      effect: 'Concede moldura imperial exclusiva para o Trono.',
      minLevel: 2,
    ),
    StoreItem(
      id: 'blessing_redemption',
      name: 'Bênção da Redenção',
      category: 'Bênçãos',
      price: 3,
      currency: 'selos',
      effect: 'Anula uma penalidade grave de um ciclo (uso raro).',
      minLevel: 4,
    ),
  ];
});

final progressionProvider = StateNotifierProvider<ProgressionController, ProgressionState>(
  (_) => ProgressionController(),
);

final imperialPenaltyProvider = Provider<PenaltyLevel>((ref) {
  final cards = ref.watch(debtsProvider);
  final hasRotativo = cards.any((c) => c.state == DebtState.rotativo);
  final hasAtraso = cards.any((c) => c.state == DebtState.atraso);
  final highCommit = cards.any((c) => c.committedLimitNow >= 0.95);

  if (hasRotativo || hasAtraso) return PenaltyLevel.critical;
  if (highCommit) return PenaltyLevel.severe;
  if (cards.any((c) => c.committedLimitNow >= 0.75)) return PenaltyLevel.warning;
  return PenaltyLevel.none;
});

final currentImperialTitleProvider = Provider<ImperialTitle>((ref) {
  final p = ref.watch(progressionProvider);
  final penalty = ref.watch(imperialPenaltyProvider);

  if (penalty == PenaltyLevel.critical) {
    return const ImperialTitle(
      name: 'Devedor em Guerra',
      rank: ImperialRank.ferro,
      temporary: true,
      requirement: 'Entrou em estado crítico de dívida ou atraso.',
      effect: 'Campanha de contenção obrigatória e bloqueio de risco recomendado.',
    );
  }

  if (p.level >= 8) {
    return const ImperialTitle(
      name: 'Arquiduque do Cofre',
      rank: ImperialRank.onix,
      temporary: false,
      requirement: 'Nível 8+ com estabilidade e execução consistente.',
      effect: 'Acesso total a Oráculos e Decretos avançados.',
    );
  }
  if (p.level >= 6) {
    return const ImperialTitle(
      name: 'Executor do Orçamento',
      rank: ImperialRank.ouro,
      temporary: false,
      requirement: 'Nível 6+, caixa positivo recorrente e controle de risco.',
      effect: 'Relatórios automáticos e bônus de Influência em decisões boas.',
    );
  }
  if (p.level >= 4) {
    return const ImperialTitle(
      name: 'Conselheiro do Caixa',
      rank: ImperialRank.prata,
      temporary: false,
      requirement: 'Nível 4+ com disciplina financeira e previsibilidade.',
      effect: 'Desbloqueia ferramentas de planejamento intermediárias.',
    );
  }
  return const ImperialTitle(
    name: 'Regente em Formação',
    rank: ImperialRank.bronze,
    temporary: false,
    requirement: 'Base inicial de execução e registro.',
    effect: 'Acesso à base do sistema e campanhas guiadas.',
  );
});

final progressionPulseProvider = Provider<Map<ProgressClass, int>>((ref) {
  final treasury = ref.watch(treasuryEntriesProvider);
  final debts = ref.watch(debtsProvider);
  final orders = ref.watch(ordersProvider);
  final campaigns = ref.watch(campaignsProvider);
  final rituals = ref.watch(ritualsProvider);

  final received = treasury.where((e) => e.received).fold<double>(0, (s, e) => s + e.amount);
  final pending = treasury.where((e) => !e.received).fold<double>(0, (s, e) => s + e.amount);
  final debtOpen = debts.fold<double>(0, (s, c) => s + c.openDebt);
  final paid = debts.expand((c) => c.payments).fold<double>(0, (s, p) => s + p.value);
  final ordersDone = orders.where((o) => o.executed).length;
  final campaignProgress = campaigns.fold<double>(0, (s, c) => s + c.progress);

  final growth = ((paid / 250).floor() + (received > pending ? 10 : 0) + (debtOpen == 0 ? 25 : 0));
  final maintenance = ((received > 0 ? 6 : 0) + (pending < received ? 8 : 0));
  final tactical = ((paid / 600).floor() * 15 + (campaignProgress / 25).floor() * 5);
  final discipline = (ordersDone + rituals.length.clamp(0, 10)).toInt();

  return {
    ProgressClass.crescimentoReal: growth,
    ProgressClass.manutencaoEstrategica: maintenance,
    ProgressClass.vitoriaTatica: tactical,
    ProgressClass.disciplina: discipline,
  };
});

final activeCampaignArcProvider = Provider<CampaignArc>((ref) {
  final debts = ref.watch(debtsProvider);
  final penalty = ref.watch(imperialPenaltyProvider);

  if (penalty == PenaltyLevel.critical || debts.any((c) => c.state == DebtState.rotativo)) {
    return const CampaignArc(
      id: 'containment-auto',
      supremeGoal: 'Sair do rotativo e restaurar soberania de caixa',
      weeklyMissions: [
        'Registrar 100% das compras do cartão da semana',
        'Executar decreto de pagamento acima do mínimo',
        'Bloquear novas compras impulsivas até o fechamento',
      ],
      bossChallenge: 'Fechar mês no positivo e reduzir dívida total em pelo menos 12%',
      autoGenerated: true,
    );
  }

  return const CampaignArc(
    id: 'reserve-auto',
    supremeGoal: 'Erguer reserva estratégica de emergência',
    weeklyMissions: [
      'Direcionar parte fixa da renda para o cofre de emergência',
      'Manter faturas sem atraso no ciclo',
      'Executar revisão semanal do orçamento imperial',
    ],
    bossChallenge: 'Encerrar ciclo com caixa positivo e sem avanço de risco',
    autoGenerated: true,
  );
});

class ProgressionController extends StateNotifier<ProgressionState> {
  ProgressionController()
      : _box = Hive.box<Map>(HiveBootstrap.progressionBox),
        super(ProgressionState.fromMap(Hive.box<Map>(HiveBootstrap.progressionBox).get('state')));

  final Box<Map> _box;

  Future<void> setOrder(ImperialOrderDoctrine doctrine) async {
    await _save(state.copyWith(order: doctrine));
  }

  Future<void> syncFromPulse(Map<ProgressClass, int> pulse) async {
    final nowKey = DateTime.now().toIso8601String().substring(0, 10);
    final currentImpact = state.dailyImpactHash[nowKey] ?? 0;
    final rawPoints = pulse.values.fold<int>(0, (s, v) => s + v);
    final antiFarm = rawPoints <= currentImpact ? 0 : ((rawPoints - currentImpact) ~/ 2) + 1;

    if (antiFarm <= 0) return;

    final gloryGain = pulse[ProgressClass.crescimentoReal] ?? 0;
    final disciplineGain = pulse[ProgressClass.disciplina] ?? 0;
    final influenceGain = pulse[ProgressClass.manutencaoEstrategica] ?? 0;
    final tactical = pulse[ProgressClass.vitoriaTatica] ?? 0;
    final sealGain = tactical >= 30 ? 1 : 0;

    final updatedCurrencies = state.currencies.copyWith(
      gloria: state.currencies.gloria + gloryGain,
      disciplina: state.currencies.disciplina + disciplineGain,
      influencia: state.currencies.influencia + influenceGain,
      selos: state.currencies.selos + sealGain,
    );

    final nextXp = state.xp + antiFarm + tactical;
    final levelUp = nextXp ~/ 120;

    await _save(state.copyWith(
      currencies: updatedCurrencies,
      xp: nextXp % 120,
      level: (state.level + levelUp).clamp(1, 99),
      dailyImpactHash: {...state.dailyImpactHash, nowKey: rawPoints},
    ));
  }

  Future<bool> buyItem(StoreItem item) async {
    if (state.level < item.minLevel || state.storeUnlocks.contains(item.id)) {
      return false;
    }

    final c = state.currencies;
    final canPay = switch (item.currency) {
      'gloria' => c.gloria >= item.price,
      'disciplina' => c.disciplina >= item.price,
      'influencia' => c.influencia >= item.price,
      'selos' => c.selos >= item.price,
      _ => false,
    };
    if (!canPay) return false;

    final updated = switch (item.currency) {
      'gloria' => c.copyWith(gloria: c.gloria - item.price),
      'disciplina' => c.copyWith(disciplina: c.disciplina - item.price),
      'influencia' => c.copyWith(influencia: c.influencia - item.price),
      'selos' => c.copyWith(selos: c.selos - item.price),
      _ => c,
    };

    await _save(state.copyWith(
      currencies: updated,
      storeUnlocks: [...state.storeUnlocks, item.id],
    ));
    return true;
  }

  Future<void> applyPenalty(PenaltyLevel level) async {
    if (level == PenaltyLevel.none) return;
    final reduction = switch (level) {
      PenaltyLevel.warning => 8,
      PenaltyLevel.severe => 20,
      PenaltyLevel.critical => 35,
      PenaltyLevel.none => 0,
    };

    await _save(state.copyWith(
      xp: (state.xp - reduction).clamp(0, 120).toInt(),
      level: level == PenaltyLevel.critical ? (state.level - 1).clamp(1, 99).toInt() : state.level,
    ));
  }

  Future<void> _save(ProgressionState next) async {
    await _box.put('state', next.toMap());
    state = next;
  }
}

final progressionMentorProvider = Provider<List<String>>((ref) {
  final title = ref.watch(currentImperialTitleProvider);
  final order = ref.watch(progressionProvider).order;
  final arc = ref.watch(activeCampaignArcProvider);
  final codex = ref.watch(codexProvider);
  final msgs = <String>[
    'Título vigente: ${title.name}. Efeito prático: ${title.effect}',
    'Ordem atual: ${_orderName(order)}. Ajuste doutrina se seu foco mudou.',
    'Campanha ativa: ${arc.supremeGoal}. Chefe do arco: ${arc.bossChallenge}',
  ];

  final debtKnowledge = codex[ImperialSystem.dividas]?.state;
  if (debtKnowledge == KnowledgeState.descobertoNaoUsado) {
    msgs.add('Você descobriu o Trono das Dívidas, mas ainda não consolidou uso. Execute o modo guiado hoje.');
  }
  return msgs;
});

String _orderName(ImperialOrderDoctrine o) => switch (o) {
      ImperialOrderDoctrine.cofreNegro => 'Ordem do Cofre Negro',
      ImperialOrderDoctrine.laminaRubra => 'Ordem da Lâmina Rubra',
      ImperialOrderDoctrine.tronoDourado => 'Ordem do Trono Dourado',
      ImperialOrderDoctrine.conclave => 'Ordem do Conclave',
    };
