import 'package:go_router/go_router.dart';

import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
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
