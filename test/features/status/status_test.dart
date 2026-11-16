import 'package:board_gamer_app/core/models/event_model.dart';
import 'package:board_gamer_app/core/models/status_message_model.dart';
import 'package:board_gamer_app/features/event/data/event_failure.dart';
import 'package:board_gamer_app/features/status/data/status_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = EventModel(
    id: 'e1',
    date: DateTime(2026, 12, 4, 19),
    hostId: 'anna',
    hostName: 'Anna',
    address: 'Weg 1',
  );

  test('StatusMessageModel Round-Trip', () {
    final m = StatusMessageModel(
      id: 'm1',
      userId: 'ben',
      userName: 'Ben',
      text: '+15 Min',
      createdAt: DateTime(2026, 12, 4, 18, 50),
    );
    expect(StatusMessageModel.fromMap('m1', m.toMap()), m);
  });

  group('StatusRepository', () {
    late FakeFirebaseFirestore db;
    late StatusRepository repo;
    var minute = 0;

    setUp(() {
      db = FakeFirebaseFirestore();
      minute = 0;
      repo = StatusRepository(
        db,
        clock: () => DateTime(2026, 12, 4, 18, minute++),
      );
    });

    Future<void> send(String text, {EventModel? on}) => repo.send(
      event: on ?? event,
      userId: 'ben',
      userName: 'Ben',
      text: text,
    );

    test('Senden speichert unter dem Termin, neueste zuerst', () async {
      await send('Pünktlich');
      await send('  +15 Min  ');
      final list = await repo.watchMessages('e1').first;
      expect(list.map((m) => m.text), ['+15 Min', 'Pünktlich']);
      expect(list.first.userId, 'ben');
    });

    test('Leerer Text wird abgelehnt', () {
      expect(send('   '), throwsA(isA<EventFailure>()));
    });

    test('Mehr als 140 Zeichen werden abgelehnt (A-11)', () {
      expect(send('x' * 141), throwsA(isA<EventFailure>()));
    });

    test('Genau 140 Zeichen sind erlaubt', () async {
      await send('x' * 140);
      expect(await repo.watchMessages('e1').first, hasLength(1));
    });

    test('Nach Abschluss des Abends kein Senden mehr', () {
      expect(
        send('Hallo', on: event.copyWith(status: EventStatus.completed)),
        throwsA(isA<EventFailure>()),
      );
    });
  });
}
