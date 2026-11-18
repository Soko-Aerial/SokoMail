import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/core/storage/preferences_store.dart';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Holds the user's light/dark/system appearance preference.
///
/// Persisted through [PreferencesStore]; in Phase 1 the store is in-memory,
/// so the choice lasts until the app restarts.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(preferencesStoreProvider)
        .readString(PreferenceKeys.themeMode);
    return ThemeMode.values.where((m) => m.name == stored).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref
        .read(preferencesStoreProvider)
        .writeString(PreferenceKeys.themeMode, mode.name);
  }
}
