enum TimelineDomain { contas, cartao, dividaDireta, pagamentos, anomalias, progresso }

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.date,
    required this.domain,
    required this.title,
    required this.subtitle,
    this.amount,
  });

  final String id;
  final DateTime date;
  final TimelineDomain domain;
  final String title;
  final String subtitle;
  final double? amount;

  String get domainLabel => switch (domain) {
        TimelineDomain.contas => 'Contas',
        TimelineDomain.cartao => 'Cartão',
        TimelineDomain.dividaDireta => 'Dívida Direta',
        TimelineDomain.pagamentos => 'Pagamento',
        TimelineDomain.anomalias => 'Anomalia',
        TimelineDomain.progresso => 'Progresso',
      };
}
