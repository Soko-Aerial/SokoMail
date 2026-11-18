import 'package:flutter_riverpod/misc.dart' show ProviderException;

/// Typed, user-safe failures used across the app.
///
/// Repositories and the network layer convert low-level exceptions into an
/// [AppFailure] so that the presentation layer never handles Dio, platform
/// or storage exceptions directly.
///
/// [userMessage] is safe to show on screen. [debugMessage] is for developers
/// only, is never displayed, and must not contain credentials, tokens or
/// message content.
sealed class AppFailure implements Exception {
  const AppFailure({this.debugMessage});

  final String? debugMessage;

  String get userMessage;

  /// Normalises any thrown object into an [AppFailure].
  ///
  /// Riverpod wraps errors that a provider rethrows from another provider in
  /// a [ProviderException]; those are unwrapped first.
  static AppFailure from(Object error) {
    var current = error;
    while (current is ProviderException) {
      current = current.exception;
    }
    if (current is AppFailure) return current;
    return const UnexpectedFailure();
  }

  // Deliberately omits [debugMessage] so failures never leak details into
  // logs or UI through string interpolation.
  @override
  String toString() => runtimeType.toString();
}

/// The device could not reach the server.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.debugMessage});

  @override
  String get userMessage =>
      'Unable to reach SokoMail. Check your connection and try again.';
}

/// The request took too long.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.debugMessage});

  @override
  String get userMessage => 'The request timed out. Please try again.';
}

/// The session is missing or expired (HTTP 401).
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.debugMessage});

  @override
  String get userMessage => 'Your session has ended. Please sign in again.';
}

/// The user is signed in but not allowed to perform the action (HTTP 403).
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.debugMessage});

  @override
  String get userMessage => 'You do not have permission to access this.';
}

/// The requested resource does not exist (HTTP 404).
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.debugMessage});

  @override
  String get userMessage => 'This item could not be found.';
}

/// The server rejected the request as invalid (other HTTP 4xx).
final class InvalidRequestFailure extends AppFailure {
  const InvalidRequestFailure({this.statusCode, super.debugMessage});

  final int? statusCode;

  @override
  String get userMessage => 'The request could not be completed.';
}

/// The server failed to process the request (HTTP 5xx).
final class ServerFailure extends AppFailure {
  const ServerFailure({this.statusCode, super.debugMessage});

  final int? statusCode;

  @override
  String get userMessage =>
      'SokoMail is having trouble right now. Please try again later.';
}

/// The request was cancelled by the app (for example, the screen closed).
final class CancelledFailure extends AppFailure {
  const CancelledFailure({super.debugMessage});

  @override
  String get userMessage => 'The request was cancelled.';
}

/// The server responded with data the app could not understand.
final class ResponseFormatFailure extends AppFailure {
  const ResponseFormatFailure({super.debugMessage});

  @override
  String get userMessage => 'SokoMail received an unexpected response.';
}

/// The app is missing required configuration (for example `API_BASE_URL`).
final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure({super.debugMessage});

  @override
  String get userMessage => 'SokoMail is not configured correctly.';
}

/// The feature depends on backend integration that is not implemented yet.
final class FeatureUnavailableFailure extends AppFailure {
  const FeatureUnavailableFailure({super.debugMessage});

  @override
  String get userMessage => 'This feature is not available yet.';
}

/// Any error that is not otherwise classified.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({super.debugMessage});

  @override
  String get userMessage => 'Something went wrong. Please try again.';
}
