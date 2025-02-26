import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode {
  list,
  grid,
  details
}

enum SortBy {
  name,
  date,
  size,
  type
}

class Settings {
  final ThemeMode themeMode;
  final ColorScheme? colorScheme;
  final ViewMode viewMode;
  final bool showHiddenFiles;
  final SortBy sortBy;
  final bool sortAscending;
  final bool useCompression;
  final bool backgroundSync;

  const Settings({
    this.themeMode = ThemeMode.system,
    this.colorScheme,
    this.viewMode = ViewMode.grid,
    this.showHiddenFiles = true,
    this.sortBy = SortBy.name,
    this.sortAscending = true,
    this.useCompression = true,
    this.backgroundSync = true,
  });

  Settings copyWith({
    ThemeMode? themeMode,
    ColorScheme? colorScheme,
    ViewMode? viewMode,
    bool? showHiddenFiles,
    SortBy? sortBy,
    bool? sortAscending,
    bool? useCompression,
    bool? backgroundSync,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      viewMode: viewMode ?? this.viewMode,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      useCompression: useCompression ?? this.useCompression,
      backgroundSync: backgroundSync ?? this.backgroundSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'colorScheme': colorScheme?.toString(),
      'viewMode': viewMode.index,
      'showHiddenFiles': showHiddenFiles,
      'sortBy': sortBy.index,
      'sortAscending': sortAscending,
      'useCompression': useCompression,
      'backgroundSync': backgroundSync,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      colorScheme: null, // ColorScheme needs to be handled separately
      viewMode: ViewMode.values[json['viewMode'] as int? ?? 0],
      showHiddenFiles: json['showHiddenFiles'] as bool? ?? true,
      sortBy: SortBy.values[json['sortBy'] as int? ?? 0],
      sortAscending: json['sortAscending'] as bool? ?? true,
      useCompression: json['useCompression'] as bool? ?? true,
      backgroundSync: json['backgroundSync'] as bool? ?? true,
    );
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  final SharedPreferences _prefs;
  static const _settingsKey = 'app_settings';

  SettingsNotifier(this._prefs) : super(const Settings()) {
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> decoded = Map<String, dynamic>.from(
          const JsonDecoder().convert(settingsJson)
        );
        state = Settings.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Keep default settings if loading fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settingsJson = const JsonEncoder().convert(state.toJson());
      await _prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  Future<void> setColorScheme(ColorScheme? colorScheme) async {
    state = state.copyWith(colorScheme: colorScheme);
    await _saveSettings();
  }

  Future<void> setViewMode(ViewMode viewMode) async {
    state = state.copyWith(viewMode: viewMode);
    await _saveSettings();
  }

  Future<void> setShowHiddenFiles(bool show) async {
    state = state.copyWith(showHiddenFiles: show);
    await _saveSettings();
  }

  Future<void> setSortBy(SortBy sortBy) async {
    state = state.copyWith(sortBy: sortBy);
    await _saveSettings();
  }

  Future<void> toggleSortDirection() async {
    state = state.copyWith(sortAscending: !state.sortAscending);
    await _saveSettings();
  }

  Future<void> setUseCompression(bool useCompression) async {
    state = state.copyWith(useCompression: useCompression);
    await _saveSettings();
  }

  Future<void> setBackgroundSync(bool backgroundSync) async {
    state = state.copyWith(backgroundSync: backgroundSync);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const Settings();
    await _saveSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in your app');
});
