import 'dart:math';

import 'package:dominium/domains/campaigns/application/campaigns_provider.dart';
import 'package:dominium/domains/orders/application/orders_provider.dart';
import 'package:dominium/domains/treasury/application/treasury_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final throneTitleProvider = Provider<String>((ref) {
  final entries = ref.watch(treasuryEntriesProvider);
  final orders = ref.watch(ordersProvider);
  final campaigns = ref.watch(campaignsProvider);

  final received = entries.where((e) => e.received).fold<double>(0, (a, e) => a + e.amount);
  final score = received + orders.where((o) => o.executed).length * 100 + campaigns.length * 50;
  if (score >= 5000) return 'Soberano';
  if (score >= 1500) return 'Regente';
  return 'Noviço';
});

final imperialPhraseProvider = Provider<String>((_) {
  const phrases = [
    'O Império observa',
    'Comande sem ruído, execute sem hesitação',
    'Disciplina silenciosa constrói dinastias',
    'Sem culpa, apenas registro e avanço',
  ];
  return phrases[Random().nextInt(phrases.length)];
});
