import 'package:board_gamer_app/core/models/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = EventModel(
    id: 'e1',
    date: DateTime(2026, 12, 1, 19),
    hostId: 'u1',
    hostName: 'Enrico',
    address: 'Hauptstr. 1',
    status: EventStatus.active,
    createdAt: DateTime(2026, 11, 15),
    votingDeadline: DateTime(2026, 11, 30, 12),
    foodReminderAt: DateTime(2026, 12, 1, 15),
    selectedFoodCategory: 'Pizza',
  );

  test('toMap/fromMap Round-Trip ergibt dasselbe Modell', () {
    expect(EventModel.fromMap('e1', event.toMap()), event);
  });

  test('Round-Trip ohne optionale Felder', () {
    final minimal = EventModel(
      id: 'e2',
      date: DateTime(2026, 12, 15, 19),
      hostId: 'u2',
      hostName: 'Roland',
      address: 'Nebenstr. 3',
    );
    final map = minimal.toMap();
    expect(map.containsKey('votingDeadline'), isFalse);
    expect(EventModel.fromMap('e2', map), minimal);
  });

  test('Status wird als Name gespeichert, unbekannt → planned', () {
    expect(event.toMap()['status'], 'active');
    expect(EventStatus.fromName('quatsch'), EventStatus.planned);
    expect(EventStatus.fromName(null), EventStatus.planned);
  });

  test('Statusübergänge nur eine Stufe vorwärts (A-06)', () {
    expect(EventStatus.planned.canTransitionTo(EventStatus.active), isTrue);
    expect(EventStatus.active.canTransitionTo(EventStatus.completed), isTrue);
    expect(EventStatus.planned.canTransitionTo(EventStatus.completed), isFalse);
    expect(EventStatus.completed.canTransitionTo(EventStatus.planned), isFalse);
    expect(EventStatus.active.canTransitionTo(EventStatus.active), isFalse);
  });

  test('copyWith ändert Status', () {
    expect(
      event.copyWith(status: EventStatus.completed).status,
      EventStatus.completed,
    );
  });
}
