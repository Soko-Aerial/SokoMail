import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/router/route_names.dart';
import 'package:sokomail/app/router/route_paths.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Named route navigation', () {
    testWidgets('reaches every folder, mailboxes, search and settings', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );
      final router = container.router;
      const box = {RouteParams.mailboxId: 'dev-personal'};

      final folders = {
        RouteNames.mailStarred: SampleSubjects.supplierUpdate,
        RouteNames.mailSent: SampleSubjects.sentReply,
        RouteNames.mailDrafts: SampleSubjects.draft,
        RouteNames.mailSpam: SampleSubjects.spam,
        RouteNames.mailTrash: SampleSubjects.trash,
      };
      for (final MapEntry(key: name, value: subject) in folders.entries) {
        router.goNamed(name, pathParameters: box);
        await tester.pumpAndSettle();
        expect(find.text(subject), findsOneWidget, reason: name);
      }
      expect(container.location, '/mail/dev-personal/trash');

      router.goNamed(RouteNames.mailboxes);
      await tester.pumpAndSettle();
      expect(
        find.text('Mailbox access is managed by your administrator.'),
        findsOneWidget,
      );

      router.goNamed(RouteNames.search);
      await tester.pumpAndSettle();
      expect(container.location, '/search');
      expect(find.text('Search your mail'), findsOneWidget);

      router.goNamed(RouteNames.settings);
      await tester.pumpAndSettle();
      expect(container.location, '/settings');
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('sidebar destinations navigate and keep the mailbox', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/sent');

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(container.location, '/settings?mailboxId=dev-personal');
    });

    testWidgets('a bare mailbox path opens its inbox', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/mail/dev-shared',
      );

      expect(container.location, '/mail/dev-shared/inbox');
      expect(find.text(SampleSubjects.shared), findsOneWidget);
    });
  });

  group('Messages', () {
    testWidgets('expanded: opens beside the list with a shareable URL', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.text(SampleSubjects.fieldTest));
      await tester.pumpAndSettle();

      expect(
        container.location,
        '/mail/dev-personal/messages/dev-msg-001?folder=inbox',
      );
      // Two panes: the list stays visible next to the reading pane.
      expect(
        find.textContaining(SampleSubjects.fieldTestBodyOnly),
        findsOneWidget,
      );
      expect(find.text(SampleSubjects.engineeringSync), findsOneWidget);
      expect(find.text('Field_Test_Report.pdf'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/inbox');
      expect(find.text('No message selected'), findsOneWidget);
    });

    testWidgets('compact: replaces the list; back returns to the folder', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        size: TestViewports.phone,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.text(SampleSubjects.fieldTest));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(SampleSubjects.fieldTestBodyOnly),
        findsOneWidget,
      );
      expect(find.text(SampleSubjects.engineeringSync), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/inbox');
      expect(find.text(SampleSubjects.engineeringSync), findsOneWidget);
    });

    testWidgets(
      'system back from a deep-linked message returns to its folder',
      (tester) async {
        final container = await pumpSokoMailApp(
          tester,
          size: TestViewports.phone,
          signedInAs: UserRole.employee,
          location: '/mail/dev-personal/messages/dev-msg-101?folder=sent',
        );
        expect(
          find.text('Thanks David, I will review the report before Friday.'),
          findsOneWidget,
        );

        await pressSystemBack(tester);

        expect(container.location, '/mail/dev-personal/sent');
      },
    );

    testWidgets('system back from a secondary page returns to the inbox', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        size: TestViewports.phone,
        signedInAs: UserRole.employee,
        location: '/settings?mailboxId=dev-shared',
      );

      await pressSystemBack(tester);

      expect(container.location, '/mail/dev-shared/inbox');
    });

    testWidgets('a missing message shows a safe error', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/mail/dev-personal/messages/does-not-exist',
      );

      expect(find.text('Could not open this message'), findsOneWidget);
      expect(find.text('This item could not be found.'), findsOneWidget);
    });

    testWidgets('deep link while signed out returns there after sign-in', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        location: '/mail/dev-personal/messages/dev-msg-001?folder=inbox',
      );
      expect(container.currentUri.path, '/login');

      await tester.tap(find.text('Continue as employee'));
      await tester.pumpAndSettle();

      expect(
        container.location,
        '/mail/dev-personal/messages/dev-msg-001?folder=inbox',
      );
      expect(find.text('Flight_Data_Summary.xlsx'), findsOneWidget);
    });
  });

  group('Compose', () {
    testWidgets('opens above the shell and closes back', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.text('Compose'));
      await tester.pumpAndSettle();
      expect(find.text('New Message'), findsOneWidget);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('New Message'), findsNothing);
      expect(container.location, '/mail/dev-personal/inbox');
    });

    testWidgets('direct /compose URL closes to the inbox', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: RoutePaths.compose,
      );
      expect(find.text('New Message'), findsOneWidget);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/inbox');
    });
  });

  group('Unknown routes', () {
    testWidgets('show the not-found screen', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/does-not-exist',
      );
      expect(find.text('Page not found'), findsWidgets);
      expect(
        find.text('There is no SokoMail page at "/does-not-exist".'),
        findsOneWidget,
      );
    });

    testWidgets('include unknown folders', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/mail/dev-personal/archive',
      );
      expect(find.text('Page not found'), findsWidgets);
    });

    testWidgets('can navigate home', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/nowhere',
      );

      await tester.tap(find.text('Go to SokoMail'));
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/inbox');
    });

    testWidgets('redirect to sign-in when signed out', (tester) async {
      final container = await pumpSokoMailApp(tester, location: '/nowhere');
      expect(container.currentUri.path, '/login');
    });
  });

  group('Protected admin route', () {
    testWidgets('employees are redirected and see no admin destination', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: RoutePaths.admin,
      );

      expect(container.location, '/mail/dev-personal/inbox');
      expect(find.text('Admin Console'), findsNothing);
    });

    testWidgets('administrators can open it', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.admin,
      );

      await tester.tap(find.text('Admin Console'));
      await tester.pumpAndSettle();

      expect(container.currentUri.path, '/admin');
      expect(find.text('Administration is not available yet'), findsOneWidget);
    });
  });

  testWidgets('signing out returns to the sign-in screen', (tester) async {
    final container = await pumpSokoMailApp(
      tester,
      signedInAs: UserRole.employee,
      location: RoutePaths.settings,
    );

    await tapVisible(tester, find.text('Sign out'));

    expect(container.currentUri.path, '/login');
    expect(find.text('Sign in to SokoMail'), findsOneWidget);
  });
}
