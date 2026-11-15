import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Essens-Voting und Bestellung, wird in T-60/T-62 umgesetzt.
class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Essen',
    icon: Icons.restaurant_outlined,
    hint: 'Essensrichtung wählen und bestellen folgt in Sprint 3.',
  );
}
