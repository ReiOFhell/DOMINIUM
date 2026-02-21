import 'package:dominium/domains/profile/data/imperium_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileControllerProvider = Provider<ProfileController>((_) => ProfileController());

class ProfileController {
  Future<ImperiumProfile> getOrCreate({
    required String ownerId,
    required String email,
  }) async {
    final client = Supabase.instance.client;

    final existing = await client
        .from('imperium_profiles')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    if (existing != null) {
      return ImperiumProfile.fromMap(existing);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final inserted = await client
        .from('imperium_profiles')
        .insert({
          'owner_id': ownerId,
          'display_name': email.split('@').first,
          'identity_visual': <String, dynamic>{},
          'realm_summary': <String, dynamic>{},
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version': 1,
          'device_id': 'flutter-client',
        })
        .select()
        .single();

    return ImperiumProfile.fromMap(inserted);
  }
}
