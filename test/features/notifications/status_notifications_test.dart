import 'package:board_gamer_app/core/models/status_message_model.dart';
import 'package:board_gamer_app/features/notifications/status_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

StatusMessageModel msg(String id, String userId) => StatusMessageModel(
  id: id,
  userId: userId,
  userName: userId.toUpperCase(),
  text: 'Hallo',
  createdAt: DateTime(2026, 12, 4),
);

void main() {
  group('findNewIncoming', () {
    test('liefert nur neue Meldungen anderer', () {
      final result = findNewIncoming(
        seenIds: {'1'},
        messages: [msg('1', 'anna'), msg('2', 'anna'), msg('3', 'ben')],
        myUid: 'ben',
      );
      expect(result.map((m) => m.id), ['2']);
    });

    test('nichts Neues → leere Liste', () {
      expect(
        findNewIncoming(
          seenIds: {'1'},
          messages: [msg('1', 'anna')],
          myUid: 'ben',
        ),
        isEmpty,
      );
    });
  });

  group('Benachrichtigung in der App', () {
    late FakeFirebaseFirestore db;
    late String eventId;

    Future<void> addMessage(String userId, String text, int minute) =>
        db.collection('events').doc(eventId).collection('statusMessages').add({
          'userId': userId,
          'userName': userId.toUpperCase(),
          'text': text,
          'createdAt': Timestamp.fromDate(DateTime(2026, 11, 20, 11, minute)),
        });

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
      })).id;
    });

    Future<FakeNotificationService> openAsBen(
      WidgetTester tester, {
      bool foreground = true,
    }) async {
      final fake = FakeNotificationService();
      await pumpApp(
        tester,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'ben', email: 'ben@x.de'),
        ),
        firestore: db,
        notifications: fake,
        inForeground: () => foreground,
      );
      return fake;
    }

    testWidgets('Vordergrund: neue Meldung erscheint als Hinweis', (
      tester,
    ) async {
      final fake = await openAsBen(tester);
      await addMessage('anna', '+15 Min', 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ANNA: +15 Min'), findsOneWidget);
      expect(fake.shown, isEmpty);
    });

    testWidgets('Hintergrund: neue Meldung als lokale Benachrichtigung', (
      tester,
    ) async {
      final fake = await openAsBen(tester, foreground: false);
      await addMessage('anna', 'Fahre los', 1);
      await tester.pumpAndSettle();

      expect(fake.shown, ['ANNA: Fahre los']);
    });

    testWidgets('Eigene Meldungen lösen nichts aus', (tester) async {
      final fake = await openAsBen(tester, foreground: false);
      await addMessage('ben', 'Pünktlich', 1);
      await tester.pumpAndSettle();

      expect(fake.shown, isEmpty);
    });

    testWidgets('Alte Meldungen beim Start lösen nichts aus', (tester) async {
      await addMessage('anna', 'Alt', 0);
      final fake = await openAsBen(tester, foreground: false);
      await tester.pumpAndSettle();

      expect(fake.shown, isEmpty);
    });
  });
}
