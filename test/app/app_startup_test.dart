import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/domain/entities/auth_state.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';
import 'package:sokomail/features/auth/presentation/widgets/development_session_banner.dart';
import 'package:sokomail/shared/widgets/sokomail_logo.dart';

import '../helpers/test_app.dart';

void main() {
  group('Application startup', () {
    testWidgets('starts signed out on the branded sign-in screen', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(tester);

      expect(container.location, '/login');
      expect(find.byType(SokoMailLogo), findsOneWidget);
      expect(find.text('Sign in to SokoMail'), findsOneWidget);
      expect(find.text('Continue as employee'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('development session opens the primary inbox', (tester) async {
      final container = await pumpSokoMailApp(tester);

      await tester.tap(find.text('Continue as employee'));
      await tester.pumpAndSettle();

      expect(container.location, '/mail/dev-personal/inbox');
      expect(find.text(SampleSubjects.fieldTest), findsOneWidget);
      // The unauthenticated development state is always visibly labelled.
      expect(find.byType(DevelopmentSessionBanner), findsOneWidget);
    });

    testWidgets('hides the development session when fixtures are disabled', (
      tester,
    ) async {
      await pumpSokoMailApp(
        tester,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.production,
              apiBaseUrl: null,
              useDevelopmentFixtures: false,
            ),
          ),
        ],
      );

      expect(find.text('Sign in to SokoMail'), findsOneWidget);
      expect(find.text('Continue as employee'), findsNothing);
    });
  });

  group('AuthController', () {
    test('refuses a development session when it is not allowed', () {
      final container = ProviderContainer.test(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.production,
              apiBaseUrl: null,
              useDevelopmentFixtures: false,
            ),
          ),
        ],
      );

      expect(
        () => container
            .read(authControllerProvider.notifier)
            .startDevelopmentSession(UserRole.employee),
        throwsStateError,
      );
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    });

    test('marks development sessions and signs out', () {
      final container = ProviderContainer.test();
      final controller = container.read(authControllerProvider.notifier);

      controller.startDevelopmentSession(UserRole.admin);
      final state = container.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).isDevelopmentSession, isTrue);
      expect(state.user.isAdmin, isTrue);

      controller.signOut();
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    });
  });
}
