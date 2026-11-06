import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../data/session.dart';
import '../features/auth/login_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/app_shell.dart';
import 'theme.dart';

/// Yuqori darajadagi sahifalar uchun yumshoq fade + kichik yuqoriga siljish.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.slow,
      reverseTransitionDuration: Motion.normal,
      transitionsBuilder: (context, animation, _, child) {
        final a = CurvedAnimation(parent: animation, curve: Motion.curve);
        return FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
            child: child,
          ),
        );
      },
    );

/// Kirish nuqtasi: sessiya yo'q → login, qiziqishlar yo'q → onboarding, aks holda → home.
final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ref.read(sessionProvider) != null;
  final onboarded = ref.read(interestsProvider).isNotEmpty;
  return GoRouter(
    initialLocation: !signedIn ? '/login' : (onboarded ? '/home' : '/onboarding'),
    routes: [
      GoRoute(path: '/login', pageBuilder: (_, s) => _fadePage(s, const LoginScreen())),
      GoRoute(path: '/onboarding', pageBuilder: (_, s) => _fadePage(s, const OnboardingScreen())),
      GoRoute(path: '/interests', builder: (_, _) => const OnboardingScreen(editing: true)),
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) => AppShell(
          shell: shell,
          body: FadeBranchContainer(currentIndex: shell.currentIndex, children: children),
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/map', builder: (_, _) => const MapScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/plans', builder: (_, _) => const PlansScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
    errorBuilder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
  );
});
