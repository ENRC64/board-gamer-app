import 'package:board_gamer_app/core/models/event_model.dart';
import 'package:board_gamer_app/features/food/domain/food_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 20, 12);
  final eventDate = DateTime(2026, 12, 4, 19);
  final deadline = DateTime(2026, 12, 2, 19);

  EventModel event({
    EventStatus status = EventStatus.planned,
    DateTime? foodDeadline,
    bool noDeadline = false,
  }) => EventModel(
    id: 'e1',
    date: eventDate,
    hostId: 'anna',
    hostName: 'Anna',
    address: 'Weg 1',
    status: status,
    foodVotingDeadline: noDeadline ? null : (foodDeadline ?? deadline),
  );

  group('defaultDeadline', () {
    test('Normalfall: 48 Stunden vor dem Termin (A-13)', () {
      expect(FoodReminderRules.defaultDeadline(eventDate, now), deadline);
    });

    test('Kurzfristiger Termin: Mitte zwischen jetzt und Termin', () {
      final soon = DateTime(2026, 11, 21, 12); // in 24 h
      expect(
        FoodReminderRules.defaultDeadline(soon, now),
        DateTime(2026, 11, 21),
      );
    });
  });

  group('voterReminderTime (A-14)', () {
    test('noch nicht gewählt → 24 h vor der Frist', () {
      expect(
        FoodReminderRules.voterReminderTime(
          event: event(),
          hasVoted: false,
          now: now,
        ),
        DateTime(2026, 12, 1, 19),
      );
    });

    test('schon gewählt → keine Erinnerung', () {
      expect(
        FoodReminderRules.voterReminderTime(
          event: event(),
          hasVoted: true,
          now: now,
        ),
        isNull,
      );
    });

    test('Erinnerungszeitpunkt schon vorbei → keine Erinnerung', () {
      expect(
        FoodReminderRules.voterReminderTime(
          event: event(foodDeadline: DateTime(2026, 11, 21, 6)),
          hasVoted: false,
          now: now,
        ),
        isNull,
      );
    });

    test('Abend läuft schon oder keine Frist → keine Erinnerung', () {
      expect(
        FoodReminderRules.voterReminderTime(
          event: event(status: EventStatus.active),
          hasVoted: false,
          now: now,
        ),
        isNull,
      );
      expect(
        FoodReminderRules.voterReminderTime(
          event: event(noDeadline: true),
          hasVoted: false,
          now: now,
        ),
        isNull,
      );
    });
  });

  group('hostResultTime (US-08)', () {
    test('Gastgeber → zur Frist', () {
      expect(
        FoodReminderRules.hostResultTime(
          event: event(),
          myUid: 'anna',
          now: now,
        ),
        deadline,
      );
    });

    test('andere Mitglieder → nichts', () {
      expect(
        FoodReminderRules.hostResultTime(
          event: event(),
          myUid: 'ben',
          now: now,
        ),
        isNull,
      );
    });

    test('Frist schon vorbei → nichts', () {
      expect(
        FoodReminderRules.hostResultTime(
          event: event(),
          myUid: 'anna',
          now: DateTime(2026, 12, 3),
        ),
        isNull,
      );
    });
  });
}
