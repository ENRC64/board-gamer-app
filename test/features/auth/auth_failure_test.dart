import 'package:board_gamer_app/features/auth/data/auth_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String msg(String code) =>
      AuthFailure.fromFirebase(FirebaseAuthException(code: code)).message;

  test('Bekannte Codes ergeben deutsche Meldungen', () {
    expect(msg('invalid-credential'), 'E-Mail oder Passwort ist falsch.');
    expect(msg('wrong-password'), 'E-Mail oder Passwort ist falsch.');
    expect(msg('email-already-in-use'), contains('bereits ein Konto'));
    expect(msg('weak-password'), contains('mindestens 6 Zeichen'));
    expect(msg('network-request-failed'), contains('Internetverbindung'));
  });

  test('Unbekannter Code ergibt allgemeine Meldung', () {
    expect(
      msg('irgendwas'),
      'Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
    );
  });
}
