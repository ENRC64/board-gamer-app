import 'package:board_gamer_app/features/auth/data/auth_failure.dart';
import 'package:board_gamer_app/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ThrowingAuth extends Mock implements FirebaseAuth {}

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late AuthRepository repo;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    repo = AuthRepository(auth, firestore);
  });

  test('signUp meldet an und legt /users/{uid} an', () async {
    await repo.signUp(
      email: ' enrico@example.com ',
      password: 'geheim1',
      displayName: ' Enrico ',
    );

    final user = auth.currentUser;
    expect(user, isNotNull);
    final doc = await firestore.collection('users').doc(user!.uid).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['displayName'], 'Enrico');
    expect(doc.data()!['email'], 'enrico@example.com');
    expect(doc.data()!['address'], '');
    expect(doc.data()!['createdAt'], isA<Timestamp>());
  });

  test('signIn und signOut ändern den Anmeldestatus', () async {
    await repo.signIn(email: 'a@b.de', password: 'geheim1');
    expect(repo.currentUser, isNotNull);
    await repo.signOut();
    expect(repo.currentUser, isNull);
  });

  test('authStateChanges liefert null nach signOut', () async {
    await repo.signIn(email: 'a@b.de', password: 'geheim1');
    final next = repo.authStateChanges().first;
    await repo.signOut();
    expect(await next, isNull);
  });

  test('Firebase-Fehler werden in AuthFailure übersetzt', () async {
    final throwing = _ThrowingAuth();
    when(
      () => throwing.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    final failing = AuthRepository(throwing, firestore);

    expect(
      () => failing.signIn(email: 'a@b.de', password: 'falsch1'),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.message,
          'message',
          'E-Mail oder Passwort ist falsch.',
        ),
      ),
    );
  });
}
