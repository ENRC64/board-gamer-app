import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/event_model.dart';
import '../auth/data/auth_repository.dart';
import '../event/data/event_repository.dart';
import '../food/data/food_vote_reader.dart';
import '../food/domain/food_reminder.dart';
import 'notification_service.dart';
import 'status_notifications.dart';

/// Feste IDs, damit eine neue Planung die alte ersetzt statt zu verdoppeln.
abstract final class FoodReminderIds {
  static const voter = 7001;
  static const hostDeadline = 7002;
  static const hostResult = 7003;
}

/// Liefert „jetzt“. In Tests durch eine feste Zeit ersetzt.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Hält die Erinnerungen zur Essensabstimmung aktuell (T-61, US-07, US-08):
///
/// 1. **Mitglieder, die noch nicht gewählt haben:** Erinnerung 24 h vor der
///    Frist (A-14). Sobald gewählt wurde, wird sie gelöscht.
/// 2. **Gastgeber:** Benachrichtigung zur Frist, dass die Abstimmung beendet
///    ist und das Ergebnis feststeht (US-08).
/// 3. **Gastgeber, App läuft:** Wird das Ergebnis (`selectedFoodCategory`,
///    gesetzt durch T-60) eingetragen, kommt sofort ein Hinweis mit der
///    gewählten Richtung.
///
/// 1 und 2 werden bei Android eingeplant und erscheinen deshalb auch, wenn
/// die App zum Zeitpunkt geschlossen ist (A-12). Der Provider wird von der
/// App-Shell beobachtet, rechnet also bei jeder Änderung von Termin,
/// Anmeldung oder eigener Stimme neu.
final foodReminderSyncProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final uid = ref.watch(authStateProvider).value?.uid;
  final event = ref.watch(nextEventProvider).value;

  if (uid == null || event == null) {
    service.cancel(FoodReminderIds.voter);
    service.cancel(FoodReminderIds.hostDeadline);
    return;
  }

  final hasVoted = ref.watch(hasVotedForFoodProvider(event.id)).value;
  // Solange unbekannt ist, ob schon gewählt wurde, nichts ändern.
  if (hasVoted == null) return;

  final now = ref.read(nowProvider)();
  _apply(
    service,
    id: FoodReminderIds.voter,
    at: FoodReminderRules.voterReminderTime(
      event: event,
      hasVoted: hasVoted,
      now: now,
    ),
    title: 'Essensabstimmung',
    body:
        'Noch 24 Stunden: Wähle deine Lieblingsessensrichtung '
        'für den Spieleabend.',
  );
  _apply(
    service,
    id: FoodReminderIds.hostDeadline,
    at: FoodReminderRules.hostResultTime(event: event, myUid: uid, now: now),
    title: 'Essensabstimmung beendet',
    body:
        'Das Ergebnis steht fest. Öffne die App und such einen '
        'passenden Lieferdienst aus.',
  );
});

void _apply(
  NotificationService service, {
  required int id,
  required DateTime? at,
  required String title,
  required String body,
}) {
  if (at == null) {
    service.cancel(id);
  } else {
    service.schedule(id: id, title: title, body: body, at: at);
  }
}

/// Meldet dem Gastgeber sofort, wenn das Ergebnis eingetragen wird
/// (Punkt 3 oben). Getrennt vom Einplanen, weil hier ein Übergang
/// „noch kein Ergebnis → Ergebnis“ erkannt werden muss.
final foodResultNotifierProvider = Provider<void>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return;

  ref.listen<AsyncValue<EventModel?>>(nextEventProvider, (previous, next) {
    final before = previous?.value;
    final after = next.value;
    if (after == null || after.hostId != uid) return;
    final result = after.selectedFoodCategory;
    final hadResult =
        before?.id == after.id && before?.selectedFoodCategory != null;
    if (result == null || hadResult || before?.id != after.id) return;

    const title = 'Ergebnis der Essensabstimmung';
    final body = 'Die Mehrheit wünscht sich: $result';
    if (ref.read(isAppInForegroundProvider)()) {
      showInAppHint('$title: $result');
    } else {
      ref
          .read(notificationServiceProvider)
          .show(id: FoodReminderIds.hostResult, title: title, body: body);
    }
  });
});
