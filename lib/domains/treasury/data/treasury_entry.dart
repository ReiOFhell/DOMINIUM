class TreasuryEntry {
  TreasuryEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.amount,
    required this.date,
    required this.received,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.deviceId,
    this.photoPath,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final double amount;
  final DateTime date;
  final bool received;
  final String? photoPath;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String deviceId;

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'amount': amount,
        'date': date.toIso8601String(),
        'received': received,
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'deviceId': deviceId,
      };

  Map<String, dynamic> toRemoteMap({required String ownerId}) => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'location': location,
        'amount': amount,
        'date': date.toIso8601String(),
        'received': received,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'version': version,
        'device_id': deviceId,
      };

  factory TreasuryEntry.fromMap(Map map) {
    final now = DateTime.now().toUtc();
    final createdAtRaw = (map['createdAt'] ?? map['created_at']) as String?;
    final updatedAtRaw = (map['updatedAt'] ?? map['updated_at']) as String?;
    final deletedAtRaw = (map['deletedAt'] ?? map['deleted_at']) as String?;

    return TreasuryEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      received: map['received'] as bool? ?? false,
      photoPath: (map['photoPath'] ?? map['photo_path']) as String?,
      createdAt: createdAtRaw == null ? now : DateTime.parse(createdAtRaw),
      updatedAt: updatedAtRaw == null ? now : DateTime.parse(updatedAtRaw),
      deletedAt: deletedAtRaw == null ? null : DateTime.parse(deletedAtRaw),
      version: map['version'] as int? ?? 1,
      deviceId: (map['deviceId'] ?? map['device_id']) as String? ?? 'local-device',
    );
  }

  TreasuryEntry copyWith({
    String? title,
    String? description,
    String? location,
    double? amount,
    DateTime? date,
    bool? received,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool deletedAtSet = false,
    int? version,
    String? deviceId,
  }) {
    return TreasuryEntry(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      received: received ?? this.received,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAtSet ? deletedAt : this.deletedAt,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  bool samePayload(TreasuryEntry other) {
    return title == other.title &&
        description == other.description &&
        location == other.location &&
        amount == other.amount &&
        date == other.date &&
        received == other.received &&
        photoPath == other.photoPath &&
        deletedAt == other.deletedAt;
  }
}
