import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/event_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../food/domain/food_reminder.dart';
import '../../profile/data/user_repository.dart';
import '../domain/host_rotation.dart';
import 'event_failure.dart';

/// Lesen und Ändern der Spieltermine unter `/events`.
///
/// Alle Geschäftsregeln (A-04 bis A-06) werden hier vor dem Schreiben
/// geprüft; die Security Rules prüfen die wichtigsten noch einmal auf dem
/// Server.
class EventRepository {
  EventRepository(this._firestore, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _now;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  static const _upcomingStatus = ['planned', 'active'];

  /// Der nächste (geplante oder laufende) Termin; `null`, wenn es keinen gibt.
  ///
  /// Sortiert wird in der App statt in Firestore, weil eine Abfrage mit
  /// `whereIn` und `orderBy` auf verschiedenen Feldern einen zusammen-
  /// gesetzten Index bräuchte. Nach A-04 gibt es ohnehin höchstens einen.
  Stream<EventModel?> watchNextEvent() {
    return _events.where('status', whereIn: _upcomingStatus).snapshots().map((
      query,
    ) {
      final events =
          query.docs.map((d) => EventModel.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      return events.isEmpty ? null : events.first;
    });
  }

  /// Alle abgeschlossenen Termine, neueste zuerst (Historie, Rotation).
  Stream<List<EventModel>> watchPastEvents() {
    return _events
        .where('status', isEqualTo: EventStatus.completed.name)
        .snapshots()
        .map(
          (query) =>
              query.docs.map((d) => EventModel.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => b.date.compareTo(a.date)),
        );
  }

  /// Legt den nächsten Termin an (US-01, US-02).
  ///
  /// Prüft: Datum liegt in der Zukunft; es gibt noch keinen kommenden Termin
  /// (A-04); der aktuelle Nutzer ist laut Rotation der nächste Gastgeber
  /// (A-05); der Gastgeber hat eine Adresse (A-02). Die Adresse wird in den
  /// Termin kopiert (A-03).
  Future<EventModel> createNextEvent({
    required String currentUserId,
    required DateTime date,
  }) async {
    if (!date.isAfter(_now())) {
      throw const EventFailure('Der Termin muss in der Zukunft liegen.');
    }

    final upcoming = await _events
        .where('status', whereIn: _upcomingStatus)
        .limit(1)
        .get();
    if (upcoming.docs.isNotEmpty) {
      throw const EventFailure('Es gibt bereits einen kommenden Termin.');
    }

    final usersSnap = await _firestore.collection('users').get();
    final users = usersSnap.docs
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .toList();
    final pastSnap = await _events
        .where('status', isEqualTo: EventStatus.completed.name)
        .get();
    final past = pastSnap.docs
        .map((d) => EventModel.fromMap(d.id, d.data()))
        .toList();

    final host = calculateNextHost(users, past);
    if (host == null) {
      throw const EventFailure('Es sind noch keine Mitglieder registriert.');
    }
    if (host.uid != currentUserId) {
      throw EventFailure('Den nächsten Termin legt ${host.displayName} fest.');
    }
    if (!host.hasAddress) {
      throw const EventFailure(
        'Bitte zuerst im Profil deine Adresse eintragen.',
      );
    }

    final doc = _events.doc();
    final event = EventModel(
      id: doc.id,
      date: date,
      hostId: host.uid,
      hostName: host.displayName,
      address: host.address,
      createdAt: _now(),
      // Frist der Essensabstimmung, Standard 48 h vorher (A-13, T-61).
      foodVotingDeadline: FoodReminderRules.defaultDeadline(date, _now()),
    );
    await doc.set(event.toMap());
    return event;
  }

  /// Wechselt den Status (A-06): nur der Gastgeber, nur eine Stufe vorwärts.
  Future<void> updateStatus({
    required String eventId,
    required EventStatus next,
    required String currentUserId,
  }) async {
    final event = await _load(eventId);
    _requireHost(event, currentUserId);
    if (!event.status.canTransitionTo(next)) {
      throw const EventFailure('Dieser Statuswechsel ist nicht erlaubt.');
    }
    await _events.doc(eventId).update({'status': next.name});
  }

  /// Verschiebt einen geplanten Termin (US-01, nur Gastgeber).
  Future<void> updateDate({
    required String eventId,
    required DateTime date,
    required String currentUserId,
  }) async {
    final event = await _load(eventId);
    _requireHost(event, currentUserId);
    _requirePlanned(event);
    if (!date.isAfter(_now())) {
      throw const EventFailure('Der Termin muss in der Zukunft liegen.');
    }
    // Die Essensfrist wandert mit dem Termin mit (wieder 48 h vorher).
    await _events.doc(eventId).update({
      'date': Timestamp.fromDate(date),
      'foodVotingDeadline': Timestamp.fromDate(
        FoodReminderRules.defaultDeadline(date, _now()),
      ),
    });
  }

  /// Sagt einen geplanten Termin ab, indem er gelöscht wird (A-06).
  Future<void> deleteEvent({
    required String eventId,
    required String currentUserId,
  }) async {
    final event = await _load(eventId);
    _requireHost(event, currentUserId);
    _requirePlanned(event);
    await _events.doc(eventId).delete();
  }

  Future<EventModel> _load(String eventId) async {
    final snap = await _events.doc(eventId).get();
    final data = snap.data();
    if (data == null) {
      throw const EventFailure('Der Termin existiert nicht mehr.');
    }
    return EventModel.fromMap(snap.id, data);
  }

  void _requireHost(EventModel event, String currentUserId) {
    if (event.hostId != currentUserId) {
      throw const EventFailure('Nur der Gastgeber kann das ändern.');
    }
  }

  void _requirePlanned(EventModel event) {
    if (event.status != EventStatus.planned) {
      throw const EventFailure('Nur geplante Termine können geändert werden.');
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(firestoreProvider)),
);

/// Der nächste Termin, live.
final nextEventProvider = StreamProvider<EventModel?>(
  (ref) => ref.watch(eventRepositoryProvider).watchNextEvent(),
);

/// Abgeschlossene Termine, live.
final pastEventsProvider = StreamProvider<List<EventModel>>(
  (ref) => ref.watch(eventRepositoryProvider).watchPastEvents(),
);

/// Wer laut Rotation den nächsten Termin ausrichtet (A-05).
final nextHostProvider = Provider<AsyncValue<UserModel?>>((ref) {
  final users = ref.watch(allUsersProvider);
  final past = ref.watch(pastEventsProvider);
  if (users.hasError) return AsyncError(users.error!, users.stackTrace!);
  if (past.hasError) return AsyncError(past.error!, past.stackTrace!);
  if (!users.hasValue || !past.hasValue) return const AsyncLoading();
  return AsyncData(calculateNextHost(users.value!, past.value!));
});
