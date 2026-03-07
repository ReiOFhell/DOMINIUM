import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imperialAdvisorProvider = Provider<List<String>>((ref) {
  final treasury = ref.watch(treasuryEntriesProvider);
  final orders = ref.watch(ordersProvider);
  final campaigns = ref.watch(campaignsProvider);

  final received = treasury.where((e) => e.received).fold<double>(0, (a, e) => a + e.amount);
  final pending = treasury.where((e) => !e.received).fold<double>(0, (a, e) => a + e.amount);
  final completedOrders = orders.where((o) => o.executed).length;

  final insights = <String>[];

  if (pending > received) {
    insights.add('Lord Inkosi, priorize conversões de pendências; o passivo supera o ouro recebido.');
  }
  if (orders.isNotEmpty && completedOrders / orders.length < 0.5) {
    insights.add('Lord Inkosi, reduza o volume de ordens e preserve apenas decretos de alto impacto.');
  }
  if (campaigns.where((c) => c.status.name == 'estagnada').isNotEmpty) {
    insights.add('Há campanhas estagnadas. Realoque recursos para destravar uma frente por vez.');
  }
  if (insights.isEmpty) {
    insights.add('Seu império está coeso. Mantenha ritmo estável e refine execução semanal.');
  }

  return insights;
});
