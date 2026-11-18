import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:sokomail/core/errors/app_failure.dart';

/// Retry policy for all Riverpod providers (passed to `ProviderScope.retry`).
///
/// Riverpod retries failing providers by default. SokoMail only retries
/// failures that are plausibly transient (connectivity, timeouts, 5xx), and
/// never retries authentication, permission, validation or programming
/// errors, which would only repeat the same outcome.
Duration? providerRetryPolicy(int retryCount, Object error) {
  const maxRetries = 3;
  if (retryCount >= maxRetries) return null;

  // The originating provider already applies this policy to its own error.
  if (error is ProviderException) return null;

  final isTransient =
      error is NetworkFailure ||
      error is TimeoutFailure ||
      error is ServerFailure;
  if (!isTransient) return null;

  // 400ms, 800ms, 1600ms.
  return Duration(milliseconds: 400 * (1 << retryCount));
}
