import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal application logger.
///
/// * Output is suppressed entirely in release builds until an approved
///   crash-reporting service is chosen.
/// * Never pass passwords, tokens, cookies, email addresses of correspondents,
///   message subjects or message bodies to the logger.
class AppLogger {
  const AppLogger(this.name);

  final String name;

  void debug(String message) => _log(message, level: 500);

  void info(String message) => _log(message, level: 800);

  void warning(String message) => _log(message, level: 900);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(message, level: 1000, error: error, stackTrace: stackTrace);

  void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;
    developer.log(
      message,
      name: 'sokomail.$name',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
