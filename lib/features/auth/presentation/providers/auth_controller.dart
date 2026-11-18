import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/features/auth/data/datasources/development_session_source.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/domain/entities/auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// View model for the authentication state.
///
/// Phase 1 contains no real authentication. Server sign-in (via the Go API,
/// with cookies on the web and secure token storage on mobile) arrives in
/// the authentication milestone and will be added here as `signIn`.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const Unauthenticated();

  /// Starts the clearly-labelled DEVELOPMENT session.
  ///
  /// Throws a [StateError] when development sessions are disabled, which is
  /// always the case in release builds.
  void startDevelopmentSession(UserRole role) {
    // `developmentToolsCompiledIn` is a compile-time constant, so in release
    // builds this method body reduces to the throw below.
    if (!AppConfig.developmentToolsCompiledIn ||
        !ref.read(appConfigProvider).allowDevelopmentSession) {
      throw StateError('Development sessions are disabled in this build.');
    }
    state = Authenticated(
      user: const DevelopmentSessionSource().createUser(role),
      isDevelopmentSession: true,
    );
  }

  void signOut() => state = const Unauthenticated();
}
