import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Zeigt lokale Benachrichtigungen an (E-05, A-12).
///
/// „Lokal“ heißt: Die App selbst erzeugt die Benachrichtigung auf dem
/// Gerät. Es gibt keinen Server, der sie schickt (das wäre Push über FCM).
/// Deshalb funktioniert das nur, solange die App läuft oder im Hintergrund
/// noch aktiv ist.
abstract class NotificationService {
  Future<void> init();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// Umsetzung mit dem Paket `flutter_local_notifications`.
class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationDetails(
    'status_messages',
    'Statusmeldungen',
    channelDescription: 'Quick-Status der anderen Mitspieler:innen',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    // Ab Android 13 muss der Nutzer Benachrichtigungen erlauben.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

/// Wird in `main.dart` mit einer gestarteten [LocalNotificationService]
/// überschrieben, in Tests mit einer Attrappe.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('in main.dart überschreiben'),
);
