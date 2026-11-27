import 'package:board_gamer_app/core/models/game_suggestion_model.dart';
import 'package:board_gamer_app/core/providers/firebase_providers.dart';
import 'package:board_gamer_app/features/auth/data/auth_repository.dart';
import 'package:board_gamer_app/features/event/data/event_failure.dart';
import 'package:board_gamer_app/features/games/data/game_suggestion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod-Provider für den Zugriff auf Spielvorschläge: das Repository
/// und der Live-Stream aller Vorschläge.
final gameSuggestionRepositoryProvider = Provider<GameSuggestionRepository>(
  (ref) => GameSuggestionRepository(ref.watch(firestoreProvider)),
);

/// Gemeinsame Live-Vorschläge, ohne Terminparameter.
final gameSuggestionsProvider = StreamProvider<List<GameSuggestionModel>>((
  ref,
) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    return Stream<List<GameSuggestionModel>>.error(
      const EventFailure('Erneut anmelden.'),
    );
  }
  return ref.watch(gameSuggestionRepositoryProvider).watch();
});
