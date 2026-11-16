import 'package:board_gamer_app/core/models/event_model.dart';
import 'package:board_gamer_app/core/models/user_model.dart';
import 'package:board_gamer_app/features/event/domain/host_rotation.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel user(String uid, int registeredDay) => UserModel(
  uid: uid,
  displayName: uid,
  email: '$uid@x.de',
  createdAt: DateTime(2026, 11, registeredDay),
);

EventModel done(String hostId, DateTime date, {EventStatus? status}) =>
    EventModel(
      id: '${hostId}_${date.toIso8601String()}',
      date: date,
      hostId: hostId,
      hostName: hostId,
      address: 'x',
      status: status ?? EventStatus.completed,
    );

void main() {
  final anna = user('anna', 1);
  final ben = user('ben', 2);
  final cem = user('cem', 3);
  final all = [cem, anna, ben]; // absichtlich unsortiert

  test('Keine Mitglieder → null', () {
    expect(calculateNextHost([], []), isNull);
  });

  test('Keine Historie → frühste Registrierung', () {
    expect(calculateNextHost(all, [])?.uid, 'anna');
  });

  test('Ein einziges Mitglied ist immer Gastgeber, auch direkt wieder', () {
    final past = [done('anna', DateTime(2026, 11, 20))];
    expect(calculateNextHost([anna], past)?.uid, 'anna');
  });

  test('Letzter Gastgeber ist ausgeschlossen', () {
    final past = [done('anna', DateTime(2026, 11, 20))];
    expect(calculateNextHost(all, past)?.uid, 'ben');
  });

  test('Wenigste Einsätze haben Vorrang', () {
    final past = [
      done('anna', DateTime(2026, 10, 1)),
      done('ben', DateTime(2026, 10, 15)),
      done('anna', DateTime(2026, 11, 1)),
      done('ben', DateTime(2026, 11, 15)),
    ];
    // cem hatte 0 Einsätze
    expect(calculateNextHost(all, past)?.uid, 'cem');
  });

  test('Gleichstand bei Einsätzen → am längsten her', () {
    final past = [
      done('ben', DateTime(2026, 10, 1)),
      done('anna', DateTime(2026, 10, 15)),
      done('cem', DateTime(2026, 11, 1)),
    ];
    // alle je 1×, cem zuletzt (ausgeschlossen), ben länger her als anna
    expect(calculateNextHost(all, past)?.uid, 'ben');
  });

  test('Neues Mitglied (noch nie Gastgeber) kommt vor allen mit Einsätzen', () {
    final dora = user('dora', 20);
    final past = [
      done('anna', DateTime(2026, 10, 1)),
      done('ben', DateTime(2026, 10, 15)),
      done('cem', DateTime(2026, 11, 1)),
    ];
    expect(calculateNextHost([...all, dora], past)?.uid, 'dora');
  });

  test('Nur abgeschlossene Termine zählen', () {
    final past = [
      done('anna', DateTime(2026, 11, 1), status: EventStatus.active),
      done('ben', DateTime(2026, 11, 8), status: EventStatus.planned),
    ];
    // keine abgeschlossenen → Registrierung, niemand ausgeschlossen
    expect(calculateNextHost(all, past)?.uid, 'anna');
  });

  test('Fehlendes Registrierungsdatum kommt zuletzt', () {
    const ohne = UserModel(uid: 'aaa', displayName: 'x', email: 'x');
    expect(calculateNextHost([ohne, cem], [])?.uid, 'cem');
  });

  test('Zwei Mitglieder wechseln sich ab', () {
    var past = <EventModel>[];
    final hosts = <String>[];
    for (var i = 0; i < 4; i++) {
      final next = calculateNextHost([anna, ben], past)!;
      hosts.add(next.uid);
      past = [...past, done(next.uid, DateTime(2026, 12, 1 + i * 14))];
    }
    expect(hosts, ['anna', 'ben', 'anna', 'ben']);
  });
}
