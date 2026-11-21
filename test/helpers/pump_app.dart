import 'package:board_gamer_app/app.dart';
import 'package:board_gamer_app/core/providers/clock_provider.dart';
import 'package:board_gamer_app/core/providers/firebase_providers.dart';
import 'package:board_gamer_app/features/notifications/food_reminders.dart';
import 'package:board_gamer_app/features/notifications/notification_service.dart';
import 'package:board_gamer_app/features/notifications/status_notifications.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

/// Feste „Jetzt“-Zeit für Tests mit Countdown und Zeitangaben.
final testNow = DateTime(2026, 11, 20, 12);

/// Attrappe: merkt sich, welche Benachrichtigungen gezeigt bzw. eingeplant
/// worden wären.
class FakeNotificationService implements NotificationService {
  /// Sofort gezeigte Benachrichtigungen als „Titel: Text“.
  final shown = <String>[];

  /// Aktuell eingeplante Erinnerungen: ID → Zeitpunkt.
  final scheduled = <int, DateTime>{};

  @override
  Future<void> init() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async => shown.add('$title: $body');

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async => scheduled[id] = at;

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}

/// Startet die komplette App mit gemocktem Firebase und fester Uhrzeit.
///
/// [inForeground] steuert, ob die App als „im Vordergrund“ gilt
/// (Snackbar) oder als „im Hintergrund“ (lokale Benachrichtigung).
Future<void> pumpApp(
  WidgetTester tester, {
  required MockFirebaseAuth auth,
  FakeFirebaseFirestore? firestore,
  FakeNotificationService? notifications,
  bool Function()? inForeground,
}) async {
  await initializeDateFormatting('de_DE');
  // Hochformat wie ein Handy (logisch 400 × 900), damit alles sichtbar ist.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(
          firestore ?? FakeFirebaseFirestore(),
        ),
        clockProvider.overrideWithValue(AsyncData(testNow)),
        nowProvider.overrideWithValue(() => testNow),
        notificationServiceProvider.overrideWithValue(
          notifications ?? FakeNotificationService(),
        ),
        isAppInForegroundProvider.overrideWithValue(inForeground ?? () => true),
      ],
      child: const BoardGamerApp(),
    ),
  );
  await tester.pumpAndSettle();
}
