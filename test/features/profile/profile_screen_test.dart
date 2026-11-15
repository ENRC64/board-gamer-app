import 'package:board_gamer_app/features/auth/presentation/login_screen.dart';
import 'package:board_gamer_app/features/profile/presentation/profile_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  final mockUser = MockUser(uid: 'u1', email: 'e@x.de', displayName: 'Enrico');

  Future<FakeFirebaseFirestore> openProfile(
    WidgetTester tester, {
    bool withDoc = true,
  }) async {
    final firestore = FakeFirebaseFirestore();
    if (withDoc) {
      await firestore.collection('users').doc('u1').set({
        'displayName': 'Enrico',
        'email': 'e@x.de',
        'address': '',
      });
    }
    await pumpApp(
      tester,
      auth: MockFirebaseAuth(signedIn: true, mockUser: mockUser),
      firestore: firestore,
    );
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    return firestore;
  }

  testWidgets('Zeigt Profil und Hinweis bei fehlender Adresse', (tester) async {
    await openProfile(tester);

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('e@x.de'), findsOneWidget);
    expect(
      find.text('Ohne Adresse kannst du keinen Spieltermin ausrichten.'),
      findsOneWidget,
    );
  });

  testWidgets('Speichern schreibt die Adresse nach Firestore', (tester) async {
    final firestore = await openProfile(tester);

    await tester.enterText(
      find.byKey(const Key('profileAddressField')),
      'Hauptstr. 1, 10115 Berlin',
    );
    await tester.tap(find.byKey(const Key('profileSaveButton')));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('users').doc('u1').get();
    expect(doc.data()!['address'], 'Hauptstr. 1, 10115 Berlin');
    expect(find.text('Profil gespeichert.'), findsOneWidget);
  });

  testWidgets('Fehlendes Profil zeigt Empty State', (tester) async {
    await openProfile(tester, withDoc: false);
    expect(find.text('Noch kein Profil vorhanden'), findsOneWidget);
  });

  testWidgets('Abmelden führt zurück zum Login', (tester) async {
    await openProfile(tester);

    await tester.tap(find.byTooltip('Abmelden'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
