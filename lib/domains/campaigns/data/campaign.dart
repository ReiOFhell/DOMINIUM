enum CampaignStatus { avanco, estagnada, fracassada }

class Campaign {
  Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.progress,
    required this.investedValue,
    required this.status,
    required this.milestones,
    required this.orderIds,
  });

  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final double progress;
  final double investedValue;
  final CampaignStatus status;
  final List<String> milestones;
  final List<String> orderIds;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'progress': progress,
        'investedValue': investedValue,
        'status': status.name,
        'milestones': milestones,
        'orderIds': orderIds,
      };

  factory Campaign.fromMap(Map map) => Campaign(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        startDate: DateTime.parse(map['startDate'] as String),
        progress: (map['progress'] as num).toDouble(),
        investedValue: (map['investedValue'] as num).toDouble(),
        status: CampaignStatus.values.byName(map['status'] as String),
        milestones: (map['milestones'] as List).cast<String>(),
        orderIds: (map['orderIds'] as List).cast<String>(),
      );
}
