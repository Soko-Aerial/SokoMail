import 'package:sokomail/app/router/route_paths.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/domain/entities/auth_state.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// Who may open a route. Declared on routes through `GoRoute.metadata`:
///
/// ```dart
/// GoRoute(path: '/admin', metadata: RouteAccess.admin.metadata, ...)
/// ```
///
/// Routes without access metadata default to [authenticated] (secure by
/// default). Client-side checks only control navigation; the Go API remains
/// the authority for every permission.
enum RouteAccess {
  /// Reachable without signing in.
  public,

  /// Requires a signed-in user.
  authenticated,

  /// Requires a signed-in user with the admin role.
  admin;

  static const metadataKey = 'sokomail.access';

  Map<String, Object> get metadata => {metadataKey: this};

  static RouteAccess fromMetadata(Map<String, dynamic> metadata) {
    final value = metadata[metadataKey];
    return value is RouteAccess ? value : RouteAccess.authenticated;
  }
}

/// Pure redirect logic used by the router's top-level `redirect`.
///
/// Kept free of Flutter and go_router types so it can be unit-tested
/// exhaustively.
abstract final class RouteGuard {
  /// Returns the location to redirect to, or `null` to allow navigation.
  static String? redirect({
    required AuthState auth,
    required Uri location,
    required RouteAccess access,
  }) {
    final path = location.path;

    switch (auth) {
      case Unauthenticated():
        if (access == RouteAccess.public) return null;
        if (path == RoutePaths.root) return RoutePaths.login;
        return Uri(
          path: RoutePaths.login,
          queryParameters: {RouteQuery.from: location.toString()},
        ).toString();

      case Authenticated(:final user):
        if (path == RoutePaths.login) {
          return sanitizeReturnLocation(
                location.queryParameters[RouteQuery.from],
              ) ??
              homeLocation(user);
        }
        if (path == RoutePaths.root) return homeLocation(user);
        if (access == RouteAccess.admin && !user.isAdmin) {
          return homeLocation(user);
        }
        return null;
    }
  }

  /// Where a signed-in user lands by default.
  static String homeLocation(AppUser user) {
    final mailboxId = user.primaryMailboxId;
    return mailboxId == null
        ? RoutePaths.settings
        : RoutePaths.folderLocation(mailboxId, MailFolder.inbox);
  }

  /// Accepts only in-app absolute paths, preventing open redirects such as
  /// `/login?from=https://evil.example` or `//evil.example`.
  static String? sanitizeReturnLocation(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    if (!raw.startsWith('/') || raw.startsWith('//')) return null;
    final path = uri.path;
    if (path == RoutePaths.login || path == RoutePaths.root) return null;
    return raw;
  }
}
