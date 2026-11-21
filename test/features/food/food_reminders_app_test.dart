import 'package:board_gamer_app/features/notifications/food_reminders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  late FakeFirebaseFirestore db;
  late String eventId;
  final deadline = DateTime(2026, 12, 2, 19);

  setUp(() async {
    db = FakeFirebaseFirestore();
    for (final (uid, day) in [('anna', 1), ('ben', 2)]) {
      await db.collection('users').doc(uid).set({
        'displayName': uid.toUpperCase(),
        'email': '$uid@x.de',
        'address': 'Weg 1',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, day)),
      });
    }
    eventId = (await db.collection('events').add({
      'date': Timestamp.fromDate(DateTime(2026, 12, 4, 19)),
      'hostId': 'anna',
      'hostName': 'ANNA',
      'address': 'Weg 1',
      'status': 'planned',
      'foodVotingDeadline': Timestamp.fromDate(deadline),
    })).id;
  });

  Future<FakeNotificationService> openAs(
    WidgetTester tester,
    String uid, {
    bool foreground = true,
  }) async {
    final fake = FakeNotificationService();
    await pumpApp(
      tester,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: uid, email: '$uid@x.de'),
      ),
      firestore: db,
      notifications: fake,
      inForeground: () => foreground,
    );
    return fake;
  }

  testWidgets('Mitglied ohne Stimme bekommt Erinnerung 24 h vor Frist', (
    tester,
  ) async {
    final fake = await openAs(tester, 'ben');
    expect(fake.scheduled[FoodReminderIds.voter], DateTime(2026, 12, 1, 19));
    expect(fake.scheduled.containsKey(FoodReminderIds.hostDeadline), isFalse);
  });

  testWidgets('Nach der Stimmabgabe wird die Erinnerung gelöscht', (
    tester,
  ) async {
    final fake = await openAs(tester, 'ben');
    await db
        .collection('events')
        .doc(eventId)
        .collection('foodVotes')
        .doc('ben')
        .set({'category': 'Italienisch'});
    await tester.pumpAndSettle();

    expect(fake.scheduled.containsKey(FoodReminderIds.voter), isFalse);
  });

  testWidgets('Gastgeber bekommt zusätzlich die Benachrichtigung zur Frist', (
    tester,
  ) async {
    final fake = await openAs(tester, 'anna');
    expect(fake.scheduled[FoodReminderIds.hostDeadline], deadline);
    expect(fake.scheduled[FoodReminderIds.voter], DateTime(2026, 12, 1, 19));
  });

  testWidgets('Termin abgesagt → alle Erinnerungen gelöscht', (tester) async {
    final fake = await openAs(tester, 'anna');
    await db.collection('events').doc(eventId).delete();
    await tester.pumpAndSettle();

    expect(fake.scheduled, isEmpty);
  });

  testWidgets('Ergebnis steht fest → Hinweis an den Gastgeber (Vordergrund)', (
    tester,
  ) async {
    await openAs(tester, 'anna');
    await db.collection('events').doc(eventId).update({
      'selectedFoodCategory': 'Italienisch',
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Ergebnis der Essensabstimmung: Italienisch'),
      findsOneWidget,
    );
  });

  testWidgets('Ergebnis steht fest → Benachrichtigung (Hintergrund)', (
    tester,
  ) async {
    final fake = await openAs(tester, 'anna', foreground: false);
    await db.collection('events').doc(eventId).update({
      'selectedFoodCategory': 'Italienisch',
    });
    await tester.pumpAndSettle();

    expect(fake.shown, [
      'Ergebnis der Essensabstimmung: Die Mehrheit wünscht sich: Italienisch',
    ]);
  });

  testWidgets('Andere Mitglieder bekommen keinen Ergebnis-Hinweis', (
    tester,
  ) async {
    final fake = await openAs(tester, 'ben', foreground: false);
    await db.collection('events').doc(eventId).update({
      'selectedFoodCategory': 'Italienisch',
    });
    await tester.pumpAndSettle();

    expect(fake.shown, isEmpty);
  });
}
