import 'package:board_gamer_app/core/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Während des Ladens → Splash', () {
    expect(
      authRedirect(isLoading: true, isLoggedIn: false, location: '/profile'),
      AppRoutes.splash,
    );
    expect(
      authRedirect(isLoading: true, isLoggedIn: false, location: '/splash'),
      isNull,
    );
  });

  test('Abgemeldet → Login', () {
    expect(
      authRedirect(isLoading: false, isLoggedIn: false, location: '/event'),
      AppRoutes.login,
    );
    expect(
      authRedirect(isLoading: false, isLoggedIn: false, location: '/login'),
      isNull,
    );
  });

  test('Angemeldet auf Login/Splash → Termin, sonst bleiben', () {
    expect(
      authRedirect(isLoading: false, isLoggedIn: true, location: '/login'),
      AppRoutes.event,
    );
    expect(
      authRedirect(isLoading: false, isLoggedIn: true, location: '/splash'),
      AppRoutes.event,
    );
    expect(
      authRedirect(isLoading: false, isLoggedIn: true, location: '/games'),
      isNull,
    );
  });
}
