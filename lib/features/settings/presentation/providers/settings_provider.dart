import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(ThemeMode.system) ThemeMode themeMode,
    ColorScheme? colorScheme,
    @Default(ViewMode.grid) ViewMode viewMode,
    @Default(true) bool showHiddenFiles,
    @Default(SortBy.name) SortBy sortBy,
    @Default(true) bool sortAscending,
    @Default(true) bool useCompression,
    @Default(true) bool backgroundSync,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) => _$SettingsStateFromJson(json);
}

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

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setColorScheme(ColorScheme colorScheme) {
    state = state.copyWith(colorScheme: colorScheme);
  }

  void setViewMode(ViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }

  void setShowHiddenFiles(bool show) {
    state = state.copyWith(showHiddenFiles: show);
  }

  void setSortBy(SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleSortDirection() {
    state = state.copyWith(sortAscending: !state.sortAscending);
  }

  void setUseCompression(bool useCompression) {
    state = state.copyWith(useCompression: useCompression);
  }

  void setBackgroundSync(bool backgroundSync) {
    state = state.copyWith(backgroundSync: backgroundSync);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
