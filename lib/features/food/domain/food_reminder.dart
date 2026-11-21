import '../../../core/models/event_model.dart';

/// Regeln für Frist und Erinnerungen der Essensabstimmung (T-61, A-13, A-14).
///
/// Alles hier sind reine Funktionen: Sie bekommen „jetzt“ als Parameter und
/// rechnen nur. Das Einplanen der Benachrichtigungen übernimmt
/// `food_reminders.dart`.
abstract final class FoodReminderRules {
  /// Standardfrist: 48 Stunden vor dem Termin (A-13).
  static const deadlineBeforeEvent = Duration(hours: 48);

  /// Erinnerung: 24 Stunden vor der Frist (A-14).
  static const reminderBeforeDeadline = Duration(hours: 24);

  /// Frist für einen Termin am [eventDate].
  ///
  /// Normalfall: 48 h vorher. Wird der Termin kurzfristig angesetzt (weniger
  /// als 48 h im Voraus), liegt die Frist in der Mitte zwischen jetzt und
  /// Termin, damit trotzdem Zeit zum Abstimmen und Bestellen bleibt.
  static DateTime defaultDeadline(DateTime eventDate, DateTime now) {
    final regular = eventDate.subtract(deadlineBeforeEvent);
    if (regular.isAfter(now)) return regular;
    return now.add(eventDate.difference(now) ~/ 2);
  }

  /// Wann soll ein Mitglied an die Abstimmung erinnert werden?
  ///
  /// `null` heißt: keine Erinnerung, weil der Termin nicht mehr geplant ist,
  /// es keine Frist gibt, schon abgestimmt wurde oder der Zeitpunkt
  /// (24 h vor Frist) schon vorbei ist.
  static DateTime? voterReminderTime({
    required EventModel event,
    required bool hasVoted,
    required DateTime now,
  }) {
    final deadline = event.foodVotingDeadline;
    if (event.status != EventStatus.planned || deadline == null || hasVoted) {
      return null;
    }
    final at = deadline.subtract(reminderBeforeDeadline);
    return at.isAfter(now) ? at : null;
  }

  /// Wann soll der Gastgeber erfahren, dass die Abstimmung beendet ist
  /// (US-08)? Nur für den Gastgeber und nur, wenn die Frist noch kommt.
  static DateTime? hostResultTime({
    required EventModel event,
    required String myUid,
    required DateTime now,
  }) {
    final deadline = event.foodVotingDeadline;
    if (event.hostId != myUid ||
        event.status != EventStatus.planned ||
        deadline == null) {
      return null;
    }
    return deadline.isAfter(now) ? deadline : null;
  }
}
