import 'package:local_auth/local_auth.dart';

class ImperialServices {
  final _auth = LocalAuthentication();

  Future<bool> requestBiometricGate() async {
    final can = await _auth.canCheckBiometrics;
    if (!can) return true;
    return _auth.authenticate(
      localizedReason: 'Confirme sua identidade para acessar o Império.',
    );
  }

  Future<void> initNotifications() async {
    // Placeholder: notificações ritualísticas removidas temporariamente
    // para evitar requisito de desugaring no Android deste MVP.
  }

  Future<void> scheduleRitualPrompt() async {
    // Placeholder para futura implementação com plugin + configuração Android.
  }
}
