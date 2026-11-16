import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/event_model.dart';
import '../../../core/models/status_message_model.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../data/status_repository.dart';

/// Quick-Status auf der Startseite (T-43): Chips zum Senden und Verlauf.
class StatusSection extends ConsumerWidget {
  const StatusSection({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canSend = event.status != EventStatus.completed;
    // Profil vorladen, damit beim Senden der Anzeigename aus dem Profil
    // bereitsteht (nicht der aus dem Login-Konto).
    ref.watch(currentUserProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick-Status', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Kurz Bescheid geben, z. B. bei Verspätung. Alle anderen werden '
          'benachrichtigt.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (canSend) QuickStatusBar(event: event),
        const SizedBox(height: AppSpacing.md),
        StatusFeedList(eventId: event.id),
      ],
    );
  }
}

/// Chips mit vordefinierten Meldungen und „Freitext“.
class QuickStatusBar extends ConsumerStatefulWidget {
  const QuickStatusBar({super.key, required this.event});

  final EventModel event;

  @override
  ConsumerState<QuickStatusBar> createState() => _QuickStatusBarState();
}

class _QuickStatusBarState extends ConsumerState<QuickStatusBar> {
  bool _sending = false;

  Future<void> _send(String text) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final name =
        ref.read(currentUserProfileProvider).value?.displayName ??
        user.displayName ??
        'Unbekannt';
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(statusRepositoryProvider)
          .send(
            event: widget.event,
            userId: user.uid,
            userName: name,
            text: text,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('Gesendet: „${text.trim()}“')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _freeText() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _FreeTextDialog(),
    );
    if (text != null && text.trim().isNotEmpty) await _send(text);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final preset in StatusMessageModel.presets)
          ActionChip(
            label: Text(preset),
            onPressed: _sending ? null : () => _send(preset),
          ),
        ActionChip(
          key: const Key('freeTextChip'),
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Freitext'),
          onPressed: _sending ? null : _freeText,
        ),
      ],
    );
  }
}

class _FreeTextDialog extends StatefulWidget {
  const _FreeTextDialog();

  @override
  State<_FreeTextDialog> createState() => _FreeTextDialogState();
}

class _FreeTextDialogState extends State<_FreeTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eigene Nachricht'),
      content: TextField(
        key: const Key('freeTextField'),
        controller: _controller,
        autofocus: true,
        maxLength: StatusMessageModel.maxLength,
        decoration: const InputDecoration(hintText: 'z. B. Bringe Chips mit'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Senden'),
        ),
      ],
    );
  }
}

/// Verlauf der Statusmeldungen, neueste oben, in Echtzeit.
class StatusFeedList extends ConsumerWidget {
  const StatusFeedList({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messages = ref.watch(statusMessagesProvider(eventId));
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final myUid = ref.watch(authStateProvider).value?.uid;

    return messages.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Statusmeldungen konnten nicht geladen werden.',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Noch keine Statusmeldungen',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final m in list)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    child: Text(
                      m.userName.isEmpty ? '?' : m.userName[0].toUpperCase(),
                    ),
                  ),
                  title: Text(m.text),
                  subtitle: Text(
                    '${m.userId == myUid ? 'Du' : m.userName} · '
                    '${AppDate.ago(m.createdAt, now)}',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
