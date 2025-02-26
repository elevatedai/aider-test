import 'package:file_browser/app/app.dart';
import 'package:file_browser/features/file_browser/presentation/screens/file_browser_screen.dart';
import 'package:file_browser/features/connections/presentation/screens/connections_screen.dart';
import 'package:file_browser/features/search/presentation/screens/search_screen.dart';
import 'package:file_browser/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_browser/app/compliance/compliance_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithBottomNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const FileBrowserScreen(),
          ),
        ),
        GoRoute(
          path: '/connections',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ConnectionsScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
                GoRoute(
          path: '/compliance',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ComplianceScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/file/:source/:path',
      builder: (context, state) {
        final source = state.pathParameters['source']!;
        final path = state.pathParameters['path']!;
        return FileDetailsScreen(source: source, path: path);
      },
    ),
  ],
);

class ScaffoldWithBottomNavBar extends StatefulWidget {
  final Widget child;
  
  const ScaffoldWithBottomNavBar({
    super.key,
    required this.child,
  });

  @override
  State<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends State<ScaffoldWithBottomNavBar> {
  int _selectedIndex = 0;

  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Files',
    ),
    NavigationDestination(
      icon: Icon(Icons.wifi_outlined),
      selectedIcon: Icon(Icons.wifi),
      label: 'Connections',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              GoRouter.of(context).go('/');
              break;
            case 1:
              GoRouter.of(context).go('/connections');
              break;
            case 2:
              GoRouter.of(context).go('/search');
              break;
            case 3:
              GoRouter.of(context).go('/settings');
              break;
          }
        },
        destinations: destinations,
      ),
    );
  }
}

class FileDetailsScreen extends StatelessWidget {
  final String source;
  final String path;
  
  const FileDetailsScreen({
    super.key,
    required this.source,
    required this.path,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Details')),
      body: Center(child: Text('File details for $path from $source')),
    );
  }
}
