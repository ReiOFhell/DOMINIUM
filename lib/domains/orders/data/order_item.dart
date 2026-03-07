enum OrderCategory { mental, fisico, financeiro }

class OrderItem {
  OrderItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.executed,
    this.lastFailedAt,
    this.campaignId,
  });

  final String id;
  final String title;
  final String description;
  final OrderCategory category;
  final DateTime dueDate;
  final bool executed;
  final DateTime? lastFailedAt;
  final String? campaignId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'dueDate': dueDate.toIso8601String(),
        'executed': executed,
        'lastFailedAt': lastFailedAt?.toIso8601String(),
        'campaignId': campaignId,
      };

  factory OrderItem.fromMap(Map map) => OrderItem(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        category: OrderCategory.values.byName(map['category'] as String),
        dueDate: DateTime.parse(map['dueDate'] as String),
        executed: map['executed'] as bool,
        lastFailedAt:
            map['lastFailedAt'] == null ? null : DateTime.parse(map['lastFailedAt'] as String),
        campaignId: map['campaignId'] as String?,
      );

  OrderItem copyWith({bool? executed, DateTime? lastFailedAt}) {
    return OrderItem(
      id: id,
      title: title,
      description: description,
      category: category,
      dueDate: dueDate,
      executed: executed ?? this.executed,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
      campaignId: campaignId,
    );
  }
}
