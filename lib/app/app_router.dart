import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ai/ai_settings_screen.dart';
import '../features/captions/ui/project_detail_screen.dart';
import '../features/captions/ui/projects_screen.dart';
import '../features/captions/ui/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/projects',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _CaptionShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) => const ProjectsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ProjectDetailScreen(
                    projectId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'ai',
                  builder: (context, state) => const AiSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _CaptionShell extends StatelessWidget {
  const _CaptionShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.subtitles_outlined),
            selectedIcon: Icon(Icons.subtitles),
            label: 'Subtítulos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

