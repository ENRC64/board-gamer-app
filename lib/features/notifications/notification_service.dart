import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Zeigt lokale Benachrichtigungen an und plant sie ein (E-05, A-12).
///
/// „Lokal“ heißt: Die App selbst erzeugt die Benachrichtigung auf dem
/// Gerät. Es gibt keinen Server, der sie schickt (das wäre Push über FCM).
/// - [show] zeigt sofort etwas an. Das klappt nur, solange die App läuft
///   oder im Hintergrund noch aktiv ist.
/// - [schedule] übergibt die Benachrichtigung an Android, das sie zur
///   angegebenen Zeit anzeigt, auch wenn die App dann geschlossen ist
///   (Erinnerungen, T-61).
abstract class NotificationService {
  Future<void> init();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });

  /// Plant eine Benachrichtigung für [at]. Eine bereits geplante mit
  /// derselben [id] wird dabei ersetzt.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });

  /// Entfernt eine geplante Benachrichtigung (falls vorhanden).
  Future<void> cancel(int id);
}

/// Umsetzung mit dem Paket `flutter_local_notifications`.
class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _statusChannel = AndroidNotificationDetails(
    'status_messages',
    'Statusmeldungen',
    channelDescription: 'Quick-Status der anderen Mitspieler:innen',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'reminders',
    'Erinnerungen',
    channelDescription: 'Erinnerungen an Abstimmungen und Fristen',
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
        android: _statusChannel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // Zeitpunkt in der Zeitzone des Geräts (in main.dart: Europe/Berlin).
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: _reminderChannel,
        iOS: DarwinNotificationDetails(),
      ),
      // „Ungefähr pünktlich, auch im Energiesparmodus“: Android darf die
      // Erinnerung um einige Minuten verschieben. Dafür braucht die App
      // keine zusätzliche Berechtigung für exakte Wecker.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}

/// Wird in `main.dart` mit einer gestarteten [LocalNotificationService]
/// überschrieben, in Tests mit einer Attrappe.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('in main.dart überschreiben'),
);
