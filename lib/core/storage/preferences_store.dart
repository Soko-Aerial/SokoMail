import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage boundary for small, **non-sensitive** user preferences such as the
/// selected theme.
///
/// Never store credentials, tokens, mailbox data or message content here.
/// Those belong to secure storage (tokens) or the planned encrypted offline
/// mail cache (see docs/architecture/overview.md, "Offline storage").
///
/// Reads are synchronous so preferences are available on the first frame.
/// The persistent implementation (`SharedPreferencesStore`) loads its values
/// once in `bootstrap()` and overrides [preferencesStoreProvider].
abstract interface class PreferencesStore {
  String? readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);
}

/// Process-lifetime implementation: the default in tests, and the fallback
/// when platform storage is unavailable (for example a browser with storage
/// disabled). Values are lost when the app restarts.
final class InMemoryPreferencesStore implements PreferencesStore {
  InMemoryPreferencesStore([Map<String, String>? initialValues])
    : _values = {...?initialValues};

  final Map<String, String> _values;

  @override
  String? readString(String key) => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

/// Keys used with [PreferencesStore]. Keep them stable once released, and
/// add every new key to [all] (persistent storage only accepts listed keys).
abstract final class PreferenceKeys {
  static const themeMode = 'settings.theme_mode';
  static const sidebarCollapsed = 'layout.sidebar_collapsed';

  static const all = {themeMode, sidebarCollapsed};
}

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => InMemoryPreferencesStore(),
);
