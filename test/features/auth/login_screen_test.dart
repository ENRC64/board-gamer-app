import 'package:board_gamer_app/features/auth/presentation/login_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Validierung', () {
    test('E-Mail', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('kein-at'), isNotNull);
      expect(validateEmail('a@b.de'), isNull);
    });

    test('Passwort', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });

  testWidgets('Abgemeldet zeigt Login, leere Eingaben zeigen Fehler', (
    tester,
  ) async {
    await pumpApp(tester, auth: MockFirebaseAuth());

    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pump();

    expect(find.text('Bitte eine E-Mail-Adresse eingeben.'), findsOneWidget);
    expect(find.text('Bitte ein Passwort eingeben.'), findsOneWidget);
  });

  testWidgets('Umschalter blendet Namensfeld ein', (tester) async {
    await pumpApp(tester, auth: MockFirebaseAuth());

    expect(find.byKey(const Key('nameField')), findsNothing);
    await tester.tap(find.text('Registrieren'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nameField')), findsOneWidget);
    expect(find.text('Konto anlegen'), findsOneWidget);
  });

  testWidgets('Registrieren legt Profil an und öffnet die App', (tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();
    await pumpApp(tester, auth: auth, firestore: firestore);

    await tester.tap(find.text('Registrieren'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nameField')), 'Enrico');
    await tester.enterText(find.byKey(const Key('emailField')), 'e@x.de');
    await tester.enterText(find.byKey(const Key('passwordField')), 'geheim1');
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    final users = await firestore.collection('users').get();
    expect(users.docs, hasLength(1));
    expect(users.docs.single.data()['displayName'], 'Enrico');
  });
}
