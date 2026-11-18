import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supplies the access token attached to API requests.
///
/// Phase 1 has no backend session, so the default implementation returns
/// `null` and no `Authorization` header is sent.
///
/// Planned implementations (see docs/architecture/decisions.md):
/// * Android/iOS: short-lived access token held in memory, refresh token in
///   platform secure storage (Keychain / Keystore).
/// * Web: HttpOnly, Secure, SameSite cookies set by the Go API. The token is
///   never readable by Dart code, so this source returns `null` on the web.
abstract interface class AccessTokenSource {
  Future<String?> readAccessToken();
}

/// Used until real session handling exists.
final class NoAccessTokenSource implements AccessTokenSource {
  const NoAccessTokenSource();

  @override
  Future<String?> readAccessToken() async => null;
}

final accessTokenSourceProvider = Provider<AccessTokenSource>(
  (ref) => const NoAccessTokenSource(),
);
