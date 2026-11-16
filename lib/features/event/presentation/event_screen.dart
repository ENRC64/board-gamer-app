import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/event_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/date_time_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/data/auth_repository.dart';
import '../../status/presentation/status_section.dart';
import '../data/event_repository.dart';
import 'event_card.dart';
import 'event_controller.dart';

/// Startseite „Termin“ (T-42): zeigt den nächsten Spieltermin (US-01) oder,
/// wenn es keinen gibt, wer als Nächstes einlädt (US-02).
class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fehler aus Aktionen (anlegen, starten …) als Snackbar anzeigen.
    ref.listen(eventControllerProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error.toString())));
      }
    });

    final nextEvent = ref.watch(nextEventProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nächster Termin')),
      body: nextEvent.when(
        loading: () => const LoadingIndicator(message: 'Termin wird geladen'),
        error: (_, _) => ErrorView(
          message: 'Termin konnte nicht geladen werden.',
          onRetry: () => ref.invalidate(nextEventProvider),
        ),
        data: (event) =>
            event == null ? const _NoEventView() : _EventView(event: event),
      ),
    );
  }
}

/// Es gibt einen Termin: Karte, Aktionen für den Gastgeber, Quick-Status.
class _EventView extends ConsumerWidget {
  const _EventView({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final isHost = uid == event.hostId;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        EventCard(event: event, now: now, isHost: isHost),
        if (isHost) ...[
          const SizedBox(height: AppSpacing.md),
          _HostActions(event: event),
        ],
        const SizedBox(height: AppSpacing.lg),
        StatusSection(event: event),
      ],
    );
  }
}

/// Knöpfe nur für den Gastgeber (A-06): starten, beenden, verschieben, absagen.
class _HostActions extends ConsumerWidget {
  const _HostActions({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(eventControllerProvider.notifier);
    final busy = ref.watch(eventControllerProvider).isLoading;
    final scheme = Theme.of(context).colorScheme;

    if (event.status == EventStatus.active) {
      return FilledButton.icon(
        key: const Key('finishButton'),
        onPressed: busy
            ? null
            : () async {
                final ok = await confirm(
                  context,
                  title: 'Abend beenden?',
                  message:
                      'Danach können alle den Abend bewerten. '
                      'Das lässt sich nicht rückgängig machen.',
                  confirmLabel: 'Beenden',
                );
                if (ok) await controller.finish(event.id);
              },
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('Abend beenden'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('startButton'),
          onPressed: busy
              ? null
              : () async {
                  final ok = await confirm(
                    context,
                    title: 'Abend starten?',
                    message:
                        'Die Spieleabstimmung endet damit. '
                        'Das lässt sich nicht rückgängig machen.',
                    confirmLabel: 'Starten',
                  );
                  if (ok) await controller.start(event.id);
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Abend starten'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('rescheduleButton'),
          onPressed: busy
              ? null
              : () async {
                  final date = await pickDateTime(context, initial: event.date);
                  if (date != null) await controller.reschedule(event.id, date);
                },
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Datum ändern'),
        ),
        TextButton.icon(
          key: const Key('cancelButton'),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: busy
              ? null
              : () async {
                  final ok = await confirm(
                    context,
                    title: 'Termin absagen?',
                    message: 'Der Termin wird für alle gelöscht.',
                    confirmLabel: 'Absagen',
                    destructive: true,
                  );
                  if (ok) await controller.cancel(event.id);
                },
          icon: const Icon(Icons.event_busy_outlined),
          label: const Text('Termin absagen'),
        ),
      ],
    );
  }
}

/// Kein Termin: Wer ist dran? Ist das der Nutzer selbst, kann er ansetzen.
class _NoEventView extends ConsumerWidget {
  const _NoEventView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final nextHost = ref.watch(nextHostProvider);

    return nextHost.when(
      loading: () => const LoadingIndicator(),
      error: (_, _) => ErrorView(
        message: 'Gastgeber konnte nicht bestimmt werden.',
        onRetry: () => ref.invalidate(nextEventProvider),
      ),
      data: (host) => _buildFor(context, ref, host, uid),
    );
  }

  Widget _buildFor(
    BuildContext context,
    WidgetRef ref,
    UserModel? host,
    String? uid,
  ) {
    if (host == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'Noch keine Mitglieder',
      );
    }
    if (host.uid != uid) {
      return EmptyState(
        icon: Icons.event_outlined,
        title: 'Noch kein Termin',
        message:
            'Als Nächstes lädt ${host.displayName} ein '
            'und legt den Termin fest.',
      );
    }
    if (!host.hasAddress) {
      return EmptyState(
        icon: Icons.home_outlined,
        title: 'Du bist als Nächstes Gastgeber:in',
        message:
            'Trag zuerst deine Adresse im Profil ein, '
            'damit alle wissen, wohin sie kommen.',
        actionLabel: 'Zum Profil',
        onAction: () => context.go(AppRoutes.profile),
      );
    }
    final busy = ref.watch(eventControllerProvider).isLoading;
    return EmptyState(
      icon: Icons.celebration_outlined,
      title: 'Du bist als Nächstes Gastgeber:in',
      message: 'Leg Datum und Uhrzeit für den nächsten Spieleabend fest.',
      actionLabel: busy ? 'Wird angelegt …' : 'Termin ansetzen',
      onAction: busy
          ? null
          : () async {
              final date = await pickDateTime(context);
              if (date != null) {
                await ref.read(eventControllerProvider.notifier).create(date);
              }
            },
    );
  }
}
