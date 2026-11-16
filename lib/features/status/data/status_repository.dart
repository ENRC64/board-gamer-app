import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/event_model.dart';
import '../../../core/models/status_message_model.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../event/data/event_failure.dart';

/// Senden und Lesen der Quick-Status-Meldungen eines Termins (US-06).
class StatusRepository {
  StatusRepository(this._firestore, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _now;

  CollectionReference<Map<String, dynamic>> _messages(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('statusMessages');

  /// Die neuesten 50 Meldungen, neueste zuerst, live.
  Stream<List<StatusMessageModel>> watchMessages(String eventId) {
    return _messages(eventId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (q) => q.docs
              .map((d) => StatusMessageModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Sendet eine Meldung. Erlaubt bei geplantem oder laufendem Termin (A-11).
  ///
  /// Als Zeitpunkt dient die Uhr des Geräts statt der Serverzeit: Ein
  /// Server-Zeitstempel ist direkt nach dem Senden lokal noch leer, die
  /// Meldung würde in der sortierten Liste kurz fehlen oder springen.
  Future<void> send({
    required EventModel event,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const EventFailure('Bitte einen Text eingeben.');
    }
    if (trimmed.length > StatusMessageModel.maxLength) {
      throw const EventFailure(
        'Höchstens ${StatusMessageModel.maxLength} Zeichen.',
      );
    }
    if (event.status == EventStatus.completed) {
      throw const EventFailure('Der Abend ist schon vorbei.');
    }
    final doc = _messages(event.id).doc();
    await doc.set(
      StatusMessageModel(
        id: doc.id,
        userId: userId,
        userName: userName,
        text: trimmed,
        createdAt: _now(),
      ).toMap(),
    );
  }
}

final statusRepositoryProvider = Provider<StatusRepository>(
  (ref) => StatusRepository(ref.watch(firestoreProvider)),
);

/// Meldungen eines Termins, live. `family` = ein Provider je Termin-ID.
final statusMessagesProvider =
    StreamProvider.family<List<StatusMessageModel>, String>(
      (ref, eventId) =>
          ref.watch(statusRepositoryProvider).watchMessages(eventId),
    );
