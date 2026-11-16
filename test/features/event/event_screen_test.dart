import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  late FakeFirebaseFirestore db;

  Future<void> addUser(String uid, int day, {String address = 'Weg 1'}) =>
      db.collection('users').doc(uid).set({
        'displayName': uid.toUpperCase(),
        'email': '$uid@x.de',
        'address': address,
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, day)),
      });

  Future<String> addEvent({String status = 'planned'}) async {
    final doc = await db.collection('events').add({
      'date': Timestamp.fromDate(DateTime(2026, 12, 4, 19)),
      'hostId': 'anna',
      'hostName': 'ANNA',
      'address': 'Hauptstr. 1, 10115 Berlin',
      'status': status,
    });
    return doc.id;
  }

  /// Scrollt [finder] vollständig ins Bild (nicht nur angeschnitten).
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
  }

  Future<void> openAs(WidgetTester tester, String uid) => pumpApp(
    tester,
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, email: '$uid@x.de', displayName: uid),
    ),
    firestore: db,
  );

  setUp(() async {
    db = FakeFirebaseFirestore();
    await addUser('anna', 1, address: 'Hauptstr. 1, 10115 Berlin');
    await addUser('ben', 2);
  });

  group('Kein Termin (Empty State)', () {
    testWidgets('Nächster Gastgeber sieht „Termin ansetzen“', (tester) async {
      await openAs(tester, 'anna');
      expect(find.text('Du bist als Nächstes Gastgeber:in'), findsOneWidget);
      expect(find.text('Termin ansetzen'), findsOneWidget);
    });

    testWidgets('Andere sehen, wer als Nächstes einlädt', (tester) async {
      await openAs(tester, 'ben');
      expect(find.text('Noch kein Termin'), findsOneWidget);
      expect(
        find.text('Als Nächstes lädt ANNA ein und legt den Termin fest.'),
        findsOneWidget,
      );
      expect(find.text('Termin ansetzen'), findsNothing);
    });

    testWidgets('Gastgeber ohne Adresse wird zum Profil geschickt', (
      tester,
    ) async {
      await db.collection('users').doc('anna').update({'address': ''});
      await openAs(tester, 'anna');
      await tester.tap(find.text('Zum Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Profil'), findsWidgets);
      expect(find.byKey(const Key('profileAddressField')), findsOneWidget);
    });
  });

  group('Termin vorhanden', () {
    testWidgets('Karte zeigt Datum, Uhrzeit, Countdown, Gastgeber, Adresse', (
      tester,
    ) async {
      await addEvent();
      await openAs(tester, 'ben');

      expect(find.text('Freitag, 4. Dezember 2026'), findsOneWidget);
      expect(find.text('19:00 Uhr'), findsOneWidget);
      expect(find.text('in 14 Tagen und 7 Stunden'), findsOneWidget);
      expect(find.text('ANNA'), findsOneWidget);
      expect(find.text('Hauptstr. 1, 10115 Berlin'), findsOneWidget);
      expect(find.text('In Karten öffnen'), findsOneWidget);
      expect(find.text('Geplant'), findsOneWidget);
      // ben ist nicht Gastgeber → keine Host-Aktionen
      expect(find.byKey(const Key('startButton')), findsNothing);
    });

    testWidgets('Gastgeber startet und beendet den Abend', (tester) async {
      final id = await addEvent();
      await openAs(tester, 'anna');
      expect(find.text('ANNA (du)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('startButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Starten'));
      await tester.pumpAndSettle();

      expect(find.text('Läuft gerade'), findsOneWidget);
      expect((await db.collection('events').doc(id).get())['status'], 'active');

      await tester.tap(find.byKey(const Key('finishButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beenden'));
      await tester.pumpAndSettle();

      expect(
        (await db.collection('events').doc(id).get())['status'],
        'completed',
      );
      // Abgeschlossen → kein kommender Termin mehr; ben ist nun dran
      expect(find.text('Noch kein Termin'), findsOneWidget);
    });

    testWidgets('Gastgeber sagt den Termin ab', (tester) async {
      final id = await addEvent();
      await openAs(tester, 'anna');

      await scrollTo(tester, find.byKey(const Key('cancelButton')));
      await tester.tap(find.byKey(const Key('cancelButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Absagen'));
      await tester.pumpAndSettle();

      expect((await db.collection('events').doc(id).get()).exists, isFalse);
      expect(find.text('Termin ansetzen'), findsOneWidget);
    });
  });

  group('Quick-Status', () {
    testWidgets('Leerer Verlauf zeigt Hinweis', (tester) async {
      await addEvent();
      await openAs(tester, 'ben');
      await scrollTo(tester, find.text('Noch keine Statusmeldungen'));
      expect(find.text('Noch keine Statusmeldungen'), findsOneWidget);
    });

    testWidgets('Chip sendet Meldung, sie erscheint im Verlauf', (
      tester,
    ) async {
      final id = await addEvent();
      await openAs(tester, 'ben');

      await scrollTo(tester, find.text('+15 Min'));
      await tester.tap(find.text('+15 Min'));
      await tester.pumpAndSettle();

      final msgs = await db
          .collection('events')
          .doc(id)
          .collection('statusMessages')
          .get();
      expect(msgs.docs.single['text'], '+15 Min');
      expect(msgs.docs.single['userId'], 'ben');
      expect(msgs.docs.single['userName'], 'BEN');
      await scrollTo(tester, find.textContaining('Du ·'));
      expect(find.textContaining('Du ·'), findsOneWidget);
    });

    testWidgets('Freitext über Dialog', (tester) async {
      final id = await addEvent();
      await openAs(tester, 'ben');

      await scrollTo(tester, find.byKey(const Key('freeTextChip')));
      await tester.tap(find.byKey(const Key('freeTextChip')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('freeTextField')),
        'Bringe Chips mit',
      );
      await tester.tap(find.text('Senden'));
      await tester.pumpAndSettle();

      final msgs = await db
          .collection('events')
          .doc(id)
          .collection('statusMessages')
          .get();
      expect(msgs.docs.single['text'], 'Bringe Chips mit');
    });
  });
}
