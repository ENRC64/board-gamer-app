// TODO: Dokumentation ergänzen
import 'package:board_gamer_app/features/games/presentation/game_suggestion_controller_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/game_suggestion_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../event/data/event_failure.dart';
import '../domain/game_suggestion_rules.dart';

/// Öffnet das Formular zum Anlegen oder Bearbeiten. Es schließt sich nur nach
/// bestätigtem Speichern oder über „Abbrechen“.
Future<void> showGameSuggestionDialog(
  BuildContext context, {
  GameSuggestionModel? suggestion,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => GameSuggestionDialog(suggestion: suggestion),
  );
}

class GameSuggestionDialog extends ConsumerStatefulWidget {
  const GameSuggestionDialog({super.key, this.suggestion});

  final GameSuggestionModel? suggestion;

  @override
  ConsumerState<GameSuggestionDialog> createState() =>
      _GameSuggestionDialogState();
}

class _GameSuggestionDialogState extends ConsumerState<GameSuggestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _minPlayers = TextEditingController();
  final _maxPlayers = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final suggestion = widget.suggestion;
    if (suggestion != null) {
      _title.text = suggestion.title;
      _description.text = suggestion.description;
      _minPlayers.text = suggestion.minPlayers.toString();
      _maxPlayers.text = suggestion.maxPlayers.toString();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _minPlayers.dispose();
    _maxPlayers.dispose();
    super.dispose();
  }

  String? _validateMax(String? value) {
    final basic = validatePlayerCount(value);
    if (basic != null) return basic;
    final min = parsePlayerCount(_minPlayers.text);
    final max = parsePlayerCount(value);
    if (min != null && max != null) return validatePlayerRange(min, max);
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final min = parsePlayerCount(_minPlayers.text);
    final max = parsePlayerCount(_maxPlayers.text);
    if (min == null || max == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await ref
        .read(gameSuggestionControllerProvider.notifier)
        .submit(
          suggestionId: widget.suggestion?.id,
          title: _title.text,
          description: _description.text,
          minPlayers: min,
          maxPlayers: max,
        );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    // Fehler: Dialog bleibt offen, Eingaben bleiben erhalten.
    final error = ref.read(gameSuggestionControllerProvider).error;
    setState(() {
      _saving = false;
      _error = error is EventFailure
          ? error.message
          : 'Der Vorschlag konnte nicht gespeichert werden. '
                'Bitte versuche es erneut.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.suggestion == null ? 'Spiel vorschlagen' : 'Spiel bearbeiten',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('suggestionTitleField'),
                  controller: _title,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Titel des Spiels',
                    helperText: 'Maximal 140 Zeichen',
                  ),
                  validator: validateTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('suggestionDescriptionField'),
                  controller: _description,
                  enabled: !_saving,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('suggestionMinField'),
                        controller: _minPlayers,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min. Spieler',
                        ),
                        validator: validatePlayerCount,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        key: const Key('suggestionMaxField'),
                        controller: _maxPlayers,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max. Spieler',
                        ),
                        validator: _validateMax,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    key: const Key('suggestionError'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('suggestionSaveButton'),
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.suggestion == null
                        ? 'Speichern'
                        : 'Änderungen speichern',
                  ),
          ),
        ],
      ),
    );
  }
}