import 'package:material_ui/material_ui.dart';

import 'empty_state.dart';

/// Platzhalter für Bereiche, die in späteren Sprints umgesetzt werden.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.hint,
  });

  final String title;
  final IconData icon;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, title: 'Bald verfügbar', message: hint),
    );
  }
}
