import 'package:board_gamer_app/app.dart';
import 'package:board_gamer_app/core/providers/firebase_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Startet die komplette App mit gemocktem Firebase.
Future<void> pumpApp(
  WidgetTester tester, {
  required MockFirebaseAuth auth,
  FakeFirebaseFirestore? firestore,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(
          firestore ?? FakeFirebaseFirestore(),
        ),
      ],
      child: const BoardGamerApp(),
    ),
  );
  await tester.pumpAndSettle();
}
