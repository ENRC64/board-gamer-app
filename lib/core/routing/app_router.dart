import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/event/presentation/event_screen.dart';
import '../../features/food/presentation/food_screen.dart';
import '../../features/games/presentation/games_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../widgets/loading_indicator.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const event = '/event';
  static const games = '/games';
  static const food = '/food';
  static const profile = '/profile';
}

/// Berechnet das Weiterleitungsziel aus dem Anmeldestatus.
///
/// Solange der Status lädt, zeigt die App den Splash-Screen. Abgemeldete
/// Nutzer landen immer auf dem Login, angemeldete nie.
String? authRedirect({
  required bool isLoading,
  required bool isLoggedIn,
  required String location,
}) {
  if (isLoading) return location == AppRoutes.splash ? null : AppRoutes.splash;
  final onAuthPage =
      location == AppRoutes.login || location == AppRoutes.splash;
  if (!isLoggedIn) return location == AppRoutes.login ? null : AppRoutes.login;
  return onAuthPage ? AppRoutes.event : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Benachrichtigt den Router bei jeder Änderung des Anmeldestatus.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return authRedirect(
        isLoading: auth.isLoading && !auth.hasValue,
        isLoggedIn: auth.value != null,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const Scaffold(body: LoadingIndicator()),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.event,
                builder: (_, _) => const EventScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.games,
                builder: (_, _) => const GamesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.food,
                builder: (_, _) => const FoodScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
