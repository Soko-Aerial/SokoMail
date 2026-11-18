import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deployment environment selected with `--dart-define=APP_ENV=...`.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String raw) {
    for (final environment in values) {
      if (environment.name == raw.trim().toLowerCase()) return environment;
    }
    throw FormatException('Unknown APP_ENV value: "$raw"');
  }
}

/// Non-secret, compile-time application configuration.
///
/// Values come from `--dart-define` flags. Dart defines are embedded in the
/// compiled app and can be extracted from it, so they must never contain
/// passwords, API keys, private keys or access tokens.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.useDevelopmentFixtures,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableNetworkLogging = false,
  });

  /// Reads configuration from `--dart-define` values.
  ///
  /// * `APP_ENV`: `development` (default), `staging` or `production`.
  /// * `API_BASE_URL`: base URL of the SokoMail Go API. Optional in Phase 1.
  /// * `USE_DEV_FIXTURES`: `true` (default) enables the development session
  ///   and sample data. Ignored in release builds.
  factory AppConfig.fromEnvironment() {
    const rawEnvironment = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const rawBaseUrl = String.fromEnvironment('API_BASE_URL');
    const devFixturesRequested = bool.fromEnvironment(
      'USE_DEV_FIXTURES',
      defaultValue: true,
    );

    return AppConfig(
      environment: AppEnvironment.parse(rawEnvironment),
      apiBaseUrl: parseApiBaseUrl(rawBaseUrl, requireHttps: kReleaseMode),
      useDevelopmentFixtures:
          developmentToolsCompiledIn && devFixturesRequested,
      enableNetworkLogging: kDebugMode,
    );
  }

  /// Version shown in Settings > About. Set with `--dart-define=APP_VERSION`
  /// in CI; keep the default in step with `pubspec.yaml`.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// `false` in release builds. Because this is a compile-time constant,
  /// code guarded by it (development session, sample data) is removed from
  /// release builds by the compiler.
  static const bool developmentToolsCompiledIn = !kReleaseMode;

  final AppEnvironment environment;

  /// `null` until the Go API exists and `API_BASE_URL` is provided.
  final Uri? apiBaseUrl;

  /// Whether development-only sample data and the development session are
  /// enabled. Always `false` in release builds.
  final bool useDevelopmentFixtures;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Logs request method, path, status and timing only (never headers,
  /// query strings or bodies). Enabled in debug builds.
  final bool enableNetworkLogging;

  /// Whether the clearly-labelled development session may be started.
  bool get allowDevelopmentSession =>
      developmentToolsCompiledIn && useDevelopmentFixtures;

  /// Parses and validates `API_BASE_URL`. Returns `null` when [raw] is empty.
  ///
  /// Throws a [FormatException] for relative URLs, unsupported schemes, or a
  /// non-HTTPS URL when [requireHttps] is set (release builds).
  static Uri? parseApiBaseUrl(String raw, {required bool requireHttps}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('API_BASE_URL must be an absolute URL: "$raw"');
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw FormatException('API_BASE_URL must use http or https: "$raw"');
    }
    if (requireHttps && uri.scheme != 'https') {
      throw const FormatException('API_BASE_URL must use https in release.');
    }
    return uri;
  }
}

/// Application configuration. Override in tests with
/// `appConfigProvider.overrideWithValue(...)`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
