import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/achievements_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/learning/learning_screen.dart';
import '../../features/rise_rating/rise_rating_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/today/today_screen.dart';
import '../../providers/providers.dart';

/// FR-1.2: the auth gate lives here — same router, same redirect logic, on
/// all three targets, so "signed in" means the same thing everywhere.
///
/// This provider watches authStateProvider directly, so the whole router is
/// rebuilt on sign-in/sign-out (auth changes are rare — this is simpler and
/// safer than bridging the auth stream into a separate Listenable).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final signedIn = authState.valueOrNull?.session != null;
      final onAuthScreen = state.matchedLocation == '/sign-in';
      if (!signedIn && !onAuthScreen) return '/sign-in';
      if (signedIn && onAuthScreen) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rise-rating',
                builder: (context, state) => const RiseRatingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning',
                builder: (context, state) => const LearningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
