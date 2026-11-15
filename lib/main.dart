import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BoardGamerApp()));
}

class BoardGamerApp extends StatelessWidget {
  const BoardGamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board-Gamer-App',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('Board-Gamer-App'))),
    );
  }
}
