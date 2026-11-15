import 'package:cloud_firestore/cloud_firestore.dart';

/// Wandelt Firestore-Werte (Timestamp, DateTime, ISO-String, Millisekunden)
/// in [DateTime] um. Gibt `null` zurück, wenn kein Wert vorhanden ist,
/// z. B. solange ein `serverTimestamp` noch nicht aufgelöst ist.
DateTime? dateFromFirestore(Object? value) {
  return switch (value) {
    Timestamp t => t.toDate(),
    DateTime d => d,
    String s => DateTime.tryParse(s),
    int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    _ => null,
  };
}

/// Wandelt [DateTime] in einen Firestore-[Timestamp] um.
Timestamp? dateToFirestore(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
