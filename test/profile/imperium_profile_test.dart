import 'package:dominium/domains/profile/data/imperium_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ImperiumProfile.fromMap parseia payload completo', () {
    final profile = ImperiumProfile.fromMap({
      'profile_id': 'p-1',
      'owner_id': 'u-1',
      'display_name': 'Inkosi',
      'identity_visual': {'palette': 'crimson'},
      'realm_summary': {'level': 2},
      'created_at': '2026-01-01T12:00:00.000Z',
      'updated_at': '2026-01-02T12:00:00.000Z',
      'deleted_at': null,
      'version': 3,
      'device_id': 'android-a',
    });

    expect(profile.profileId, 'p-1');
    expect(profile.ownerId, 'u-1');
    expect(profile.displayName, 'Inkosi');
    expect(profile.identityVisual['palette'], 'crimson');
    expect(profile.realmSummary['level'], 2);
    expect(profile.version, 3);
    expect(profile.deviceId, 'android-a');
    expect(profile.deletedAt, isNull);
  });

  test('ImperiumProfile.fromMap aplica defaults quando campos opcionais faltam', () {
    final profile = ImperiumProfile.fromMap({
      'profile_id': 'p-2',
      'owner_id': 'u-2',
      'display_name': 'Nova',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    expect(profile.identityVisual, isEmpty);
    expect(profile.realmSummary, isEmpty);
    expect(profile.version, 1);
    expect(profile.deviceId, 'mobile-client');
  });
}
