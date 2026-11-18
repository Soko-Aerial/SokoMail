import 'package:shared_preferences/shared_preferences.dart';
import 'package:sokomail/core/storage/preferences_store.dart';

/// [PreferencesStore] persisted with `shared_preferences`:
/// SharedPreferences on Android, NSUserDefaults on iOS and `localStorage` on
/// the web. Suitable for non-sensitive preferences only.
final class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferencesWithCache _preferences;

  /// Loads the allow-listed preferences into memory.
  static Future<SharedPreferencesStore> load() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: PreferenceKeys.all,
      ),
    );
    return SharedPreferencesStore(preferences);
  }

  @override
  String? readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
