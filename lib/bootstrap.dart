import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sokomail/app/app.dart';
import 'package:sokomail/core/errors/provider_retry_policy.dart';
import 'package:sokomail/core/storage/preferences_store.dart';
import 'package:sokomail/core/storage/shared_preferences_store.dart';
import 'package:sokomail/core/utils/app_logger.dart';

/// Initialises platform services and starts the app.
///
/// Asynchronous start-up work (persistent preferences now; restoring the
/// session and crash reporting later) happens here, before [runApp], with
/// results injected through `ProviderScope.overrides`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: clean URLs such as /mail/abc/inbox instead of /#/mail/abc/inbox.
  // Requires the web server to serve index.html for unknown paths.
  // No-op on Android and iOS.
  usePathUrlStrategy();

  const logger = AppLogger('app');
  // Framework errors keep Flutter's default console output in debug builds.
  // Uncaught asynchronous errors are logged here; this is the hook for a
  // future crash-reporting service.
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error('Uncaught error', error: error, stackTrace: stackTrace);
    return true;
  };

  runApp(
    ProviderScope(
      retry: providerRetryPolicy,
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          await _loadPreferences(logger),
        ),
      ],
      child: const SokoMailApp(),
    ),
  );
}

/// Persistent preferences, or an in-memory fallback if platform storage is
/// unavailable (the app must still start; settings then last one session).
Future<PreferencesStore> _loadPreferences(AppLogger logger) async {
  try {
    return await SharedPreferencesStore.load();
  } on Object catch (error, stackTrace) {
    logger.warning('Persistent preferences unavailable; using memory.');
    logger.error('Preferences error', error: error, stackTrace: stackTrace);
    return InMemoryPreferencesStore();
  }
}
