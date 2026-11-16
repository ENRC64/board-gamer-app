import '../../../core/models/event_model.dart';
import '../../../core/models/user_model.dart';

/// Bestimmt den Gastgeber des nächsten Termins nach Annahme A-05.
///
/// Regeln in dieser Reihenfolge:
/// 1. Der Gastgeber des letzten abgeschlossenen Termins ist ausgeschlossen,
///    solange die Gruppe mehr als ein Mitglied hat.
/// 2. Vorrang hat, wer am seltensten Gastgeber war (nur abgeschlossene Termine).
/// 3. Bei Gleichstand: wessen letzter Einsatz am längsten zurückliegt;
///    „noch nie“ gilt als am längsten her.
/// 4. Bei Gleichstand: wer sich früher registriert hat (`createdAt`).
/// 5. Zuletzt die UID, damit das Ergebnis immer eindeutig ist.
///
/// Gibt `null` zurück, wenn es keine Mitglieder gibt.
UserModel? calculateNextHost(
  List<UserModel> users,
  List<EventModel> pastEvents,
) {
  if (users.isEmpty) return null;

  final completed =
      pastEvents.where((e) => e.status == EventStatus.completed).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  // Wie oft war jemand Gastgeber, und wann zuletzt?
  final hostCount = <String, int>{};
  final lastHosted = <String, DateTime>{};
  for (final event in completed) {
    hostCount[event.hostId] = (hostCount[event.hostId] ?? 0) + 1;
    lastHosted[event.hostId] = event.date;
  }

  var candidates = users;
  if (users.length > 1 && completed.isNotEmpty) {
    final lastHostId = completed.last.hostId;
    candidates = users.where((u) => u.uid != lastHostId).toList();
  }

  final sorted = [...candidates]
    ..sort((a, b) {
      // Regel 2: wenigste Einsätze zuerst
      final byCount = (hostCount[a.uid] ?? 0).compareTo(hostCount[b.uid] ?? 0);
      if (byCount != 0) return byCount;

      // Regel 3: am längsten her zuerst, „nie“ vor allen anderen
      final lastA = lastHosted[a.uid];
      final lastB = lastHosted[b.uid];
      if (lastA != lastB) {
        if (lastA == null) return -1;
        if (lastB == null) return 1;
        return lastA.compareTo(lastB);
      }

      // Regel 4: frühere Registrierung zuerst, fehlendes Datum zuletzt
      final createdA = a.createdAt;
      final createdB = b.createdAt;
      if (createdA != createdB) {
        if (createdA == null) return 1;
        if (createdB == null) return -1;
        return createdA.compareTo(createdB);
      }

      // Regel 5: eindeutige Reihenfolge
      return a.uid.compareTo(b.uid);
    });

  return sorted.first;
}
