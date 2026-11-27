import 'package:board_gamer_app/core/utils/name_utils.dart';
import 'package:board_gamer_app/features/games/data/game_suggestion_providers.dart';
import 'package:board_gamer_app/features/games/presentation/game_suggestion_controller_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/game_suggestion_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/data/auth_repository.dart';
import '../../event/data/event_failure.dart';
import '../../profile/data/user_repository.dart';
import '../domain/game_suggestion_rules.dart';
import 'game_suggestion_dialog.dart';

// Spielvorschläge-Bildschirm mit seinen Hilfs-Widgets (Liste, Kopfzeile,
// Leerhinweis, Eintrag, Avatar).

/// Gemeinsame, terminunabhängige Spielvorschläge (US-03).
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final busy = ref.watch(gameSuggestionControllerProvider).isLoading;
    final canSuggest =
        !auth.isLoading && !auth.hasError && auth.value != null && !busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Spiele')),
      body: auth.when(
        loading: () => const LoadingIndicator(message: 'Prüfe Anmeldung …'),
        error: (error, _) => ErrorView(
          message: 'Die Anmeldung konnte nicht geprüft werden.',
          onRetry: () => ref.invalidate(authStateProvider),
        ),
        data: (user) => user == null
            ? const Center(child: Text('Bitte melde dich erneut an.'))
            : const _SuggestionsView(),
      ),
      floatingActionButton: canSuggest
          ? FloatingActionButton.extended(
              key: const Key('addSuggestionButton'),
              onPressed: () => showGameSuggestionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Spiel vorschlagen'),
            )
          : null,
    );
  }
}

/// Zeigt die Vorschlagsliste in den Gruppen „Meine“ und „Weitere“ samt
/// Lade-, Fehler- und Leerzustand.
class _SuggestionsView extends ConsumerWidget {
  const _SuggestionsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(gameSuggestionsProvider);
    final users = ref.watch(allUsersProvider);
    final uid = ref.watch(authStateProvider).value?.uid;
    final busy = ref.watch(gameSuggestionControllerProvider).isLoading;

    if (suggestions.hasError || users.hasError) {
      return ErrorView(
        message: 'Die Spielvorschläge konnten nicht geladen werden.',
        onRetry: () {
          ref.invalidate(gameSuggestionsProvider);
          ref.invalidate(allUsersProvider);
        },
      );
    }
    if (!suggestions.hasValue || !users.hasValue) {
      return const LoadingIndicator(message: 'Lade Vorschläge …');
    }

    // Alle Profile kommen aus EINEM Stream (kein Einzelabruf pro Vorschlag).
    final names = {
      for (final user in users.requireValue) user.uid: user.displayName,
    };
    final all = suggestions.requireValue;
    final mine = all.where((s) => s.userId == uid).toList();
    final others = all.where((s) => s.userId != uid).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (busy) const LinearProgressIndicator(),
        const _SectionHeader('Von dir vorgeschlagen'),
        if (mine.isEmpty)
          const _EmptyHint('Du hast noch kein Spiel vorgeschlagen.')
        else
          for (final suggestion in mine)
            _SuggestionTile(
              suggestion: suggestion,
              isOwn: true,
              onEdit: busy
                  ? null
                  : () => showGameSuggestionDialog(
                      context,
                      suggestion: suggestion,
                    ),
              onDelete: busy
                  ? null
                  : () => _confirmDeleteSuggestion(context, ref, suggestion),
            ),
        const _SectionHeader('Von anderen vorgeschlagen'),
        if (others.isEmpty)
          const _EmptyHint('Andere haben noch kein Spiel vorgeschlagen.')
        else
          for (final suggestion in others)
            _SuggestionTile(
              suggestion: suggestion,
              isOwn: false,
              authorName: names[suggestion.userId],
            ),
      ],
    );
  }
}

Future<void> _confirmDeleteSuggestion(
  BuildContext context,
  WidgetRef ref,
  GameSuggestionModel suggestion,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Spielvorschlag löschen?'),
      content: Text('„${suggestion.title}“ wirklich löschen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('confirmDeleteSuggestionButton'),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Löschen'),
        ),
      ],
    ),
  );
  if (!context.mounted || confirmed != true) return;
  final saved = await ref
      .read(gameSuggestionControllerProvider.notifier)
      .remove(suggestion.id);
  if (!context.mounted) return;
  final error = ref.read(gameSuggestionControllerProvider).error;
  final message = saved
      ? 'Vorschlag gelöscht.'
      : error is EventFailure
      ? error.message
      : 'Der Vorschlag konnte nicht gelöscht werden. Bitte versuche es erneut.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Überschrift einer Gruppe in der Vorschlagsliste.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Hinweistext, wenn eine Gruppe keine Vorschläge enthält.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Listeneintrag eines Vorschlags mit Titel, Spielerzahl, Urheber-Avatar
/// und (für eigene Vorschläge) Bearbeiten/Löschen.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.isOwn,
    this.authorName,
    this.onEdit,
    this.onDelete,
  });

  final GameSuggestionModel suggestion;
  final bool isOwn;

  /// `null` = kein Profil zu dieser Nutzer-ID gefunden.
  final String? authorName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final players = playerCountLabel(
      suggestion.minPlayers,
      suggestion.maxPlayers,
    );
    final description = suggestion.description;
    return ListTile(
      leading: isOwn
          ? const Icon(Icons.extension_outlined)
          : _AuthorAvatar(name: authorName),
      title: Text(suggestion.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(players),
          if (description.isNotEmpty) Text(description),
        ],
      ),
      trailing: isOwn
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('editSuggestion-${suggestion.id}'),
                  tooltip: 'Vorschlag bearbeiten',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  key: Key('deleteSuggestion-${suggestion.id}'),
                  tooltip: 'Vorschlag löschen',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            )
          : null,
    );
  }
}

/// Avatar mit Pflicht-Initialen; Antippen (Tooltip) und Screenreader nennen
/// den vollen Anzeigenamen. Fehlendes Profil: „?“ / „Unbekannter Spieler“.
class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final fullName = name ?? 'Unbekannter Spieler';
    final initials = name == null ? '?' : initialsOf(name!);
    return Semantics(
      label: 'Vorgeschlagen von $fullName',
      excludeSemantics: true,
      child: Tooltip(
        message: fullName,
        triggerMode: TooltipTriggerMode.tap,
        child: CircleAvatar(child: Text(initials)),
      ),
    );
  }
}
