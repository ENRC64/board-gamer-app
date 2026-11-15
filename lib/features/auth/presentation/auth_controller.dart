import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Steuert Anmelden, Registrieren und Abmelden. Der Zustand ist
/// `AsyncLoading` während einer Aktion und `AsyncError` mit einer
/// [AuthFailure] bei Fehlern.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> signUp(String email, String password, String displayName) =>
      _run(
        () => _repo.signUp(
          email: email,
          password: password,
          displayName: displayName,
        ),
      );

  Future<bool> signOut() => _run(_repo.signOut);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
