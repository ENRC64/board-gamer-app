import 'package:board_gamer_app/features/games/presentation/game_suggestion_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod-Provider, der den GameSuggestionController für die UI bereitstellt.
final gameSuggestionControllerProvider =
    AsyncNotifierProvider<GameSuggestionController, void>(
      GameSuggestionController.new,
    );
