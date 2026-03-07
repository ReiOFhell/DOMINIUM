class ImperiumProfile {
  const ImperiumProfile({
    required this.profileId,
    required this.ownerId,
    required this.displayName,
    required this.identityVisual,
    required this.realmSummary,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.deviceId,
  });

  final String profileId;
  final String ownerId;
  final String displayName;
  final Map<String, dynamic> identityVisual;
  final Map<String, dynamic> realmSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String deviceId;

  factory ImperiumProfile.fromMap(Map<String, dynamic> map) {
    return ImperiumProfile(
      profileId: map['profile_id'] as String,
      ownerId: map['owner_id'] as String,
      displayName: map['display_name'] as String,
      identityVisual: Map<String, dynamic>.from(map['identity_visual'] as Map? ?? const {}),
      realmSummary: Map<String, dynamic>.from(map['realm_summary'] as Map? ?? const {}),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] == null ? null : DateTime.parse(map['deleted_at'] as String),
      version: map['version'] as int? ?? 1,
      deviceId: map['device_id'] as String? ?? 'mobile-client',
    );
  }
}
