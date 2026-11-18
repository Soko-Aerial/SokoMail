import 'package:sokomail/features/auth/domain/entities/app_user.dart';

/// Authentication state consumed by the router guard and the UI.
///
/// The authentication milestone will add a "restoring session" state for
/// app start-up while the Go API validates an existing session.
sealed class AuthState {
  const AuthState();

  AppUser? get user => switch (this) {
    Authenticated(:final user) => user,
    Unauthenticated() => null,
  };
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  const Authenticated({required this.user, required this.isDevelopmentSession});

  @override
  final AppUser user;

  /// True for the local development session, which is NOT verified by any
  /// server. Never true in release builds.
  final bool isDevelopmentSession;
}
