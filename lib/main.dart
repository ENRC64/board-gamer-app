import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'features/notifications/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Deutsche Monats- und Wochentagsnamen für Datumsanzeigen laden.
  await initializeDateFormatting('de_DE');
  // Lokale Benachrichtigungen vorbereiten (fragt ab Android 13 nach Erlaubnis).
  final notifications = LocalNotificationService();
  await notifications.init();
  runApp(
    ProviderScope(
      overrides: [notificationServiceProvider.overrideWithValue(notifications)],
      child: const BoardGamerApp(),
    ),
  );
}
