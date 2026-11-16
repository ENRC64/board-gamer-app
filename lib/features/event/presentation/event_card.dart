import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/event_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';

/// Karte mit allen Infos zum nächsten Termin (US-01): Datum, Uhrzeit,
/// Countdown, Gastgeber, Adresse und Link zur Karte.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.now,
    required this.isHost,
  });

  final EventModel event;
  final DateTime now;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(status: event.status),
            const SizedBox(height: AppSpacing.md),
            Text(AppDate.longDate(event.date), style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(AppDate.time(event.date), style: text.titleMedium),
            if (event.status == EventStatus.planned) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppDate.countdown(event.date, now),
                key: const Key('countdown'),
                style: text.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Gastgeber:in',
              value: isHost ? '${event.hostName} (du)' : event.hostName,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              icon: Icons.home_outlined,
              label: 'Adresse',
              value: event.address,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('mapsButton'),
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('In Karten öffnen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      mapsUri(event.address),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Karten-App konnte nicht geöffnet werden.'),
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

/// Farbiges Etikett für den Terminstatus.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg, icon) = switch (status) {
      EventStatus.planned => (
        'Geplant',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.schedule,
      ),
      EventStatus.active => (
        'Läuft gerade',
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.play_circle_outline,
      ),
      EventStatus.completed => (
        'Abgeschlossen',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.check_circle_outline,
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 18, color: fg),
      label: Text(label),
      labelStyle: TextStyle(color: fg),
      backgroundColor: bg,
      side: BorderSide.none,
    );
  }
}
