import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Dashboard mit nächstem Termin, wird in T-42 umgesetzt.
class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Termin',
    icon: Icons.event_outlined,
    hint:
        'Nächster Spieltermin, Gastgeber und Quick-Status folgen in Sprint 2.',
  );
}
