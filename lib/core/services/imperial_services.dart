import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';

class ImperialServices {
  final _auth = LocalAuthentication();
  final _notifications = FlutterLocalNotificationsPlugin();

  Future<bool> requestBiometricGate() async {
    final can = await _auth.canCheckBiometrics;
    if (!can) return true;
    return _auth.authenticate(
      localizedReason: 'Confirme sua identidade para acessar o Império.',
    );
  }

  Future<void> initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(const InitializationSettings(android: android));
  }

  Future<void> scheduleRitualPrompt() async {
    await _notifications.show(
      1,
      'DOMINIUM',
      'O Império aguarda sua ordem.',
      const NotificationDetails(
        android: AndroidNotificationDetails('ritual', 'Rituais', importance: Importance.low),
      ),
    );
  }
}
