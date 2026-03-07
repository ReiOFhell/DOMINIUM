import 'package:dominium/core/services/calculation_telemetry.dart';
import 'package:dominium/domains/profile/application/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(profileControllerProvider));
});

class AuthController {
  AuthController(this._profileController);

  final ProfileController _profileController;

  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> ensureProfileForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _profileController.getOrCreate(
        ownerId: user.id,
        email: user.email ?? 'unknown@dominium.local',
      );
    } catch (error) {
      await CalculationTelemetry.record(
        area: 'auth.profile.ensure',
        message: 'Falha ao garantir perfil do usuário autenticado; mantendo modo local.',
        context: {'error': error.toString(), 'userId': user.id},
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return;

      await _profileController.getOrCreate(
        ownerId: user.id,
        email: user.email ?? email,
      );
    } on AuthException catch (error) {
      await CalculationTelemetry.record(
        area: 'auth.signin',
        message: error.message,
        context: {'email': email},
      );
      rethrow;
    } catch (error) {
      await CalculationTelemetry.record(
        area: 'auth.signin',
        message: 'Falha inesperada no sign in.',
        context: {'email': email, 'error': error.toString()},
      );
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (error) {
      await CalculationTelemetry.record(
        area: 'auth.signup',
        message: error.message,
        context: {'email': email},
      );
      rethrow;
    } catch (error) {
      await CalculationTelemetry.record(
        area: 'auth.signup',
        message: 'Falha inesperada no sign up.',
        context: {'email': email, 'error': error.toString()},
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      await CalculationTelemetry.record(
        area: 'auth.signout',
        message: 'Falha ao encerrar sessão.',
        context: {'error': error.toString()},
      );
      rethrow;
    }
  }
}
