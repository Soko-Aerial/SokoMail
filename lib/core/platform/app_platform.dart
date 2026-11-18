import 'package:flutter/foundation.dart';

/// The platform the app is running on.
///
/// Use this for platform *capabilities* (for example cookie-based sessions on
/// the web versus secure token storage on mobile). Do not use it to choose
/// layouts: layouts depend on available width (see `app/layout`).
enum AppPlatform {
  android,
  ios,
  web,
  other;

  static AppPlatform get current {
    if (kIsWeb) return AppPlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppPlatform.android,
      TargetPlatform.iOS => AppPlatform.ios,
      _ => AppPlatform.other,
    };
  }
}
