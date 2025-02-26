import 'package:file_browser/app/routes/app_router.dart';
import 'package:file_browser/app/theme/app_theme.dart';
import 'package:file_browser/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileBrowserApp extends ConsumerWidget {
  const FileBrowserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final colorScheme = ref.watch(settingsProvider.select((s) => s.colorScheme));
    
    return MaterialApp.router(
      title: 'File Browser',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme(colorScheme),
      darkTheme: AppTheme.darkTheme(colorScheme),
      routerConfig: appRouter,
    );
  }
}
