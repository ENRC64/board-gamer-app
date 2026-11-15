import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:board_gamer_app/main.dart';

void main() {
  testWidgets('App startet', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BoardGamerApp()));
    expect(find.text('Board-Gamer-App'), findsWidgets);
  });
}
