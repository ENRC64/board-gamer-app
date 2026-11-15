import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
