import 'package:flutter_test/flutter_test.dart';
import 'package:sokomail/app/router/route_guard.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/domain/entities/auth_state.dart';

void main() {
  const employee = AppUser(
    id: 'u1',
    email: 'employee@example.com',
    displayName: 'Employee',
    role: UserRole.employee,
    primaryMailboxId: 'box1',
  );
  const admin = AppUser(
    id: 'u2',
    email: 'admin@example.com',
    displayName: 'Admin',
    role: UserRole.admin,
    primaryMailboxId: 'box1',
  );
  const signedOut = Unauthenticated();
  const signedIn = Authenticated(user: employee, isDevelopmentSession: false);
  const signedInAdmin = Authenticated(user: admin, isDevelopmentSession: false);

  String? redirect(
    AuthState auth,
    String location, {
    RouteAccess access = RouteAccess.authenticated,
  }) => RouteGuard.redirect(
    auth: auth,
    location: Uri.parse(location),
    access: access,
  );

  group('signed out', () {
    test('protected pages redirect to sign-in and remember the target', () {
      expect(
        redirect(signedOut, '/mail/box1/messages/42?folder=inbox'),
        '/login?from=%2Fmail%2Fbox1%2Fmessages%2F42%3Ffolder%3Dinbox',
      );
    });

    test('root redirects to sign-in without a return location', () {
      expect(redirect(signedOut, '/'), '/login');
    });

    test('public pages are allowed', () {
      expect(redirect(signedOut, '/login', access: RouteAccess.public), isNull);
    });
  });

  group('signed in', () {
    test('sign-in page forwards to the inbox', () {
      expect(
        redirect(signedIn, '/login', access: RouteAccess.public),
        '/mail/box1/inbox',
      );
    });

    test('sign-in page honours a safe return location', () {
      expect(
        redirect(
          signedIn,
          '/login?from=%2Fsettings',
          access: RouteAccess.public,
        ),
        '/settings',
      );
    });

    test('root forwards to the inbox', () {
      expect(redirect(signedIn, '/'), '/mail/box1/inbox');
    });

    test('ordinary pages are allowed', () {
      expect(redirect(signedIn, '/mail/box1/sent'), isNull);
    });

    test('users without a mailbox land on settings', () {
      const noMailbox = Authenticated(
        user: AppUser(
          id: 'u3',
          email: 'new@example.com',
          displayName: 'New',
          role: UserRole.employee,
        ),
        isDevelopmentSession: false,
      );
      expect(redirect(noMailbox, '/'), '/settings');
    });
  });

  group('role-based access', () {
    test('admin routes redirect employees home', () {
      expect(
        redirect(signedIn, '/admin', access: RouteAccess.admin),
        '/mail/box1/inbox',
      );
    });

    test('admin routes allow administrators', () {
      expect(
        redirect(signedInAdmin, '/admin', access: RouteAccess.admin),
        isNull,
      );
    });

    test('routes default to authenticated access', () {
      expect(RouteAccess.fromMetadata(const {}), RouteAccess.authenticated);
      expect(
        RouteAccess.fromMetadata(RouteAccess.admin.metadata),
        RouteAccess.admin,
      );
    });
  });

  group('return-location sanitising', () {
    test('rejects external and protocol-relative URLs', () {
      expect(RouteGuard.sanitizeReturnLocation('https://evil.example'), isNull);
      expect(RouteGuard.sanitizeReturnLocation('//evil.example/x'), isNull);
      expect(RouteGuard.sanitizeReturnLocation('javascript:alert(1)'), isNull);
      expect(RouteGuard.sanitizeReturnLocation('settings'), isNull);
    });

    test('rejects loops back to sign-in', () {
      expect(RouteGuard.sanitizeReturnLocation('/login'), isNull);
      expect(RouteGuard.sanitizeReturnLocation('/'), isNull);
    });

    test('accepts in-app paths with queries', () {
      expect(
        RouteGuard.sanitizeReturnLocation('/mail/a/messages/1?folder=sent'),
        '/mail/a/messages/1?folder=sent',
      );
    });

    test('external return location falls back to the inbox', () {
      expect(
        redirect(
          signedIn,
          '/login?from=https%3A%2F%2Fevil.example',
          access: RouteAccess.public,
        ),
        '/mail/box1/inbox',
      );
    });
  });
}
