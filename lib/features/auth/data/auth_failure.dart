import 'package:firebase_auth/firebase_auth.dart';

/// Fachlicher Fehler der Anmeldung mit deutschem Text für die UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  /// Übersetzt Firebase-Fehlercodes in verständliche deutsche Meldungen.
  factory AuthFailure.fromFirebase(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'Die E-Mail-Adresse ist ungültig.',
      'user-disabled' => 'Dieses Konto wurde deaktiviert.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' => 'E-Mail oder Passwort ist falsch.',
      'email-already-in-use' =>
        'Für diese E-Mail-Adresse gibt es bereits ein Konto.',
      'weak-password' => 'Das Passwort ist zu schwach (mindestens 6 Zeichen).',
      'too-many-requests' =>
        'Zu viele Versuche. Bitte später erneut versuchen.',
      'network-request-failed' =>
        'Keine Internetverbindung. Bitte Verbindung prüfen.',
      'operation-not-allowed' =>
        'Anmeldung per E-Mail ist im Firebase-Projekt nicht aktiviert.',
      _ => 'Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
    };
    return AuthFailure(message);
  }

  @override
  String toString() => message;
}
