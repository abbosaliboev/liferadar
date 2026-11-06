import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/shell/app_shell.dart';

/// Router bir marta yaratiladi. Qiziqishlar hali tanlanmagan bo'lsa — onboarding'dan boshlanadi.
final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.read(interestsProvider).isNotEmpty;
  return GoRouter(
    initialLocation: onboarded ? '/home' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/interests', builder: (_, _) => const OnboardingScreen(editing: true)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/map', builder: (_, _) => const MapScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/plans', builder: (_, _) => const PlansScreen())]),
          StatefulShellBranch(
              routes: [GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen())]),
        ],
      ),
    ],
  );
});
