import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';

/// Hat der angemeldete Nutzer beim Termin [eventId] schon eine
/// Essensrichtung gewählt?
///
/// Schnittstelle zu T-60 (Essens-Voting, Roland): Eine Stimme liegt als
/// Dokument `events/{eventId}/foodVotes/{userId}` vor (Dokument-ID = UID,
/// siehe Datenmodell). Hier wird nur geprüft, ob das Dokument existiert.
final hasVotedForFoodProvider = StreamProvider.family<bool, String>((
  ref,
  eventId,
) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(false);
  return ref
      .watch(firestoreProvider)
      .collection('events')
      .doc(eventId)
      .collection('foodVotes')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists);
});
