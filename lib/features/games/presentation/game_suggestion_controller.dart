import 'package:board_gamer_app/features/games/data/game_suggestion_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../event/data/event_failure.dart';

/// Schreibaktionen auf Spielvorschlägen (speichern, löschen) für den
/// angemeldeten Nutzer; der Zustand zeigt Laden/Fehler an und dient der UI
/// als Rückmeldung.
class GameSuggestionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> _run(Future<void> Function(String uid) operation) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) {
        throw const EventFailure('Bitte melde dich erneut an.');
      }
      await operation(uid);
    });
    if (!ref.mounted) return false;
    state = result;
    return !result.hasError;
  }

  /// Ohne ID anlegen, mit ID denselben Vorschlag bearbeiten.
  Future<bool> submit({
    String? suggestionId,
    required String title,
    required String description,
    required int minPlayers,
    required int maxPlayers,
  }) {
    return _run((uid) async {
      final repository = ref.read(gameSuggestionRepositoryProvider);
      if (suggestionId == null) {
        await repository.add(
          userId: uid,
          title: title,
          description: description,
          minPlayers: minPlayers,
          maxPlayers: maxPlayers,
        );
      } else {
        await repository.update(
          suggestionId: suggestionId,
          userId: uid,
          title: title,
          description: description,
          minPlayers: minPlayers,
          maxPlayers: maxPlayers,
        );
      }
    });
  }

  Future<bool> remove(String suggestionId) {
    return _run((uid) {
      return ref
          .read(gameSuggestionRepositoryProvider)
          .delete(suggestionId: suggestionId, userId: uid);
    });
  }
}
