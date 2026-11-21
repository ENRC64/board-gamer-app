import 'package:board_gamer_app/core/models/event_model.dart';
import 'package:board_gamer_app/features/event/data/event_failure.dart';
import 'package:board_gamer_app/features/event/data/event_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 20, 12);
  final future = DateTime(2026, 12, 4, 19);
  late FakeFirebaseFirestore db;
  late EventRepository repo;

  Future<void> addUser(String uid, int day, {String address = 'Weg 1'}) =>
      db.collection('users').doc(uid).set({
        'displayName': uid.toUpperCase(),
        'email': '$uid@x.de',
        'address': address,
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, day)),
      });

  Matcher failure(String text) => throwsA(
    isA<EventFailure>().having((f) => f.message, 'message', contains(text)),
  );

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = EventRepository(db, clock: () => now);
    await addUser('anna', 1, address: 'Hauptstr. 1, Berlin');
    await addUser('ben', 2);
  });

  group('createNextEvent', () {
    test('legt Termin für den berechneten Gastgeber an', () async {
      final event = await repo.createNextEvent(
        currentUserId: 'anna',
        date: future,
      );

      expect(event.hostId, 'anna');
      expect(event.hostName, 'ANNA');
      expect(event.address, 'Hauptstr. 1, Berlin'); // A-03: Kopie
      expect(event.status, EventStatus.planned);
      final stored = await db.collection('events').doc(event.id).get();
      expect(stored.data()!['status'], 'planned');
      // T-61: Essensfrist 48 h vor dem Termin
      expect(event.foodVotingDeadline, DateTime(2026, 12, 2, 19));
    });

    test('verweigert, wenn jemand anderes an der Reihe ist', () {
      expect(
        repo.createNextEvent(currentUserId: 'ben', date: future),
        failure('ANNA'),
      );
    });

    test('verweigert ohne Adresse im Profil (A-02)', () async {
      await db.collection('users').doc('anna').update({'address': ''});
      expect(
        repo.createNextEvent(currentUserId: 'anna', date: future),
        failure('Adresse'),
      );
    });

    test('verweigert Datum in der Vergangenheit', () {
      expect(
        repo.createNextEvent(currentUserId: 'anna', date: DateTime(2026, 11)),
        failure('Zukunft'),
      );
    });

    test('verweigert zweiten kommenden Termin (A-04)', () async {
      await repo.createNextEvent(currentUserId: 'anna', date: future);
      expect(
        repo.createNextEvent(currentUserId: 'anna', date: future),
        failure('bereits'),
      );
    });
  });

  group('Status, Datum, Löschen', () {
    late String id;

    setUp(() async {
      id = (await repo.createNextEvent(currentUserId: 'anna', date: future)).id;
    });

    test('Gastgeber startet und beendet den Abend', () async {
      await repo.updateStatus(
        eventId: id,
        next: EventStatus.active,
        currentUserId: 'anna',
      );
      await repo.updateStatus(
        eventId: id,
        next: EventStatus.completed,
        currentUserId: 'anna',
      );
      final doc = await db.collection('events').doc(id).get();
      expect(doc.data()!['status'], 'completed');
    });

    test('Statuswechsel nur durch Gastgeber', () {
      expect(
        repo.updateStatus(
          eventId: id,
          next: EventStatus.active,
          currentUserId: 'ben',
        ),
        failure('Gastgeber'),
      );
    });

    test('Stufe überspringen ist verboten (A-06)', () {
      expect(
        repo.updateStatus(
          eventId: id,
          next: EventStatus.completed,
          currentUserId: 'anna',
        ),
        failure('nicht erlaubt'),
      );
    });

    test('Datum ändern und Absagen nur, solange geplant', () async {
      final later = DateTime(2026, 12, 5, 18);
      await repo.updateDate(eventId: id, date: later, currentUserId: 'anna');
      final doc = await db.collection('events').doc(id).get();
      final moved = EventModel.fromMap(id, doc.data()!);
      expect(moved.date, later);
      // Essensfrist wandert mit (48 h vor neuem Termin)
      expect(moved.foodVotingDeadline, DateTime(2026, 12, 3, 18));

      await repo.updateStatus(
        eventId: id,
        next: EventStatus.active,
        currentUserId: 'anna',
      );
      expect(
        repo.deleteEvent(eventId: id, currentUserId: 'anna'),
        failure('geplante'),
      );
    });

    test('Absagen löscht den Termin', () async {
      await repo.deleteEvent(eventId: id, currentUserId: 'anna');
      expect((await db.collection('events').doc(id).get()).exists, isFalse);
    });
  });

  group('Streams', () {
    test(
      'watchNextEvent liefert nur geplante/aktive, frühester zuerst',
      () async {
        await db.collection('events').add({
          'date': Timestamp.fromDate(DateTime(2026, 10, 1)),
          'hostId': 'ben',
          'status': 'completed',
        });
        expect(await repo.watchNextEvent().first, isNull);

        await repo.createNextEvent(currentUserId: 'anna', date: future);
        final next = await repo.watchNextEvent().first;
        expect(next?.hostId, 'anna');
      },
    );

    test('watchPastEvents sortiert neueste zuerst', () async {
      for (final d in [1, 20, 10]) {
        await db.collection('events').add({
          'date': Timestamp.fromDate(DateTime(2026, 10, d)),
          'hostId': 'ben',
          'status': 'completed',
        });
      }
      final past = await repo.watchPastEvents().first;
      expect(past.map((e) => e.date.day), [20, 10, 1]);
    });

    test('Rotation berücksichtigt abgeschlossene Termine', () async {
      await db.collection('events').add({
        'date': Timestamp.fromDate(DateTime(2026, 11, 1)),
        'hostId': 'anna',
        'status': 'completed',
      });
      // anna war zuletzt Gastgeber → ben ist dran
      final event = await repo.createNextEvent(
        currentUserId: 'ben',
        date: future,
      );
      expect(event.hostId, 'ben');
    });
  });
}
