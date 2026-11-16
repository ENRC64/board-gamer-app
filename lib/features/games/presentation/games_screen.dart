import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Spiele-Vorschläge und Voting, wird in T-50/T-51 umgesetzt.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Spiele',
    icon: Icons.extension_outlined,
    hint: 'Spiele vorschlagen und abstimmen folgt in Sprint 2.',
  );
}
