import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/event_model.dart';
import '../../auth/data/auth_repository.dart';
import '../data/event_failure.dart';
import '../data/event_repository.dart';

/// Führt die Aktionen rund um den Termin aus (anlegen, verschieben,
/// starten, beenden, absagen). Zustand: lädt / Fehler / fertig.
class EventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  EventRepository get _repo => ref.read(eventRepositoryProvider);

  String get _uid {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw const EventFailure('Bitte erneut anmelden.');
    return user.uid;
  }

  Future<bool> create(DateTime date) =>
      _run(() => _repo.createNextEvent(currentUserId: _uid, date: date));

  Future<bool> reschedule(String eventId, DateTime date) => _run(
    () => _repo.updateDate(eventId: eventId, date: date, currentUserId: _uid),
  );

  Future<bool> start(String eventId) => _status(eventId, EventStatus.active);

  Future<bool> finish(String eventId) =>
      _status(eventId, EventStatus.completed);

  Future<bool> cancel(String eventId) =>
      _run(() => _repo.deleteEvent(eventId: eventId, currentUserId: _uid));

  Future<bool> _status(String eventId, EventStatus next) => _run(
    () => _repo.updateStatus(eventId: eventId, next: next, currentUserId: _uid),
  );

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final eventControllerProvider = AsyncNotifierProvider<EventController, void>(
  EventController.new,
);
