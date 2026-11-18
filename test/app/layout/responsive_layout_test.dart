import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/layout/brand_app_bar.dart';
import 'package:sokomail/app/layout/responsive_layout.dart';
import 'package:sokomail/app/layout/shell/shell_navigation.dart';
import 'package:sokomail/core/storage/preferences_store.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/shared/widgets/pill_label.dart';

import '../../helpers/test_app.dart';

void main() {
  group('WindowSizeClass', () {
    test('uses the provisional breakpoints', () {
      expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(1023.9), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(1024), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(2560), WindowSizeClass.expanded);
    });
  });

  group('ResponsiveLayout', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      setViewport(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            compact: (_) => const Text('compact'),
            medium: (_) => const Text('medium'),
            expanded: (_) => const Text('expanded'),
          ),
        ),
      );
    }

    testWidgets('picks the builder for the window width', (tester) async {
      await pumpAt(tester, TestViewports.phone);
      expect(find.text('compact'), findsOneWidget);

      await pumpAt(tester, TestViewports.tablet);
      expect(find.text('medium'), findsOneWidget);

      await pumpAt(tester, TestViewports.desktop);
      expect(find.text('expanded'), findsOneWidget);
    });
  });

  group('ListDetailLayout', () {
    Future<void> pumpLayout(
      WidgetTester tester, {
      required double width,
      required bool showDetail,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 600,
              child: ListDetailLayout(
                showDetail: showDetail,
                list: const Text('list'),
                detailBuilder: (_, isSinglePane) =>
                    Text(isSinglePane ? 'detail-single' : 'detail-pane'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows both panes when wide enough', (tester) async {
      await pumpLayout(tester, width: 900, showDetail: true);
      expect(find.text('list'), findsOneWidget);
      expect(find.text('detail-pane'), findsOneWidget);
    });

    testWidgets('shows one pane when narrow, keeping the list mounted', (
      tester,
    ) async {
      await pumpLayout(tester, width: 500, showDetail: false);
      expect(find.text('list'), findsOneWidget);
      expect(find.textContaining('detail'), findsNothing);

      await pumpLayout(tester, width: 500, showDetail: true);
      await tester.pumpAndSettle();
      expect(find.text('list'), findsNothing);
      expect(find.text('list', skipOffstage: false), findsOneWidget);
      expect(find.text('detail-single'), findsOneWidget);
    });
  });

  group('Adaptive shell', () {
    testWidgets('compact: drawer, bottom folder bar and Compose button', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        size: TestViewports.phone,
        signedInAs: UserRole.employee,
      );

      expect(find.byType(BrandAppBar), findsOneWidget);
      expect(find.byType(ShellBottomBar), findsOneWidget);
      expect(find.byType(ShellSidebar), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.widgetWithText(CountBadge, '3'), findsOneWidget);

      await tester.tap(find.byType(DrawerButton));
      await tester.pumpAndSettle();
      expect(find.byType(ShellDrawer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ShellDrawer),
          matching: find.text('Mailboxes'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(ShellDrawer),
          matching: find.text('Trash'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShellDrawer), findsNothing);
      expect(container.location, '/mail/dev-personal/trash');
      expect(find.text(SampleSubjects.trash), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(ShellBottomBar),
          matching: find.text('Sent'),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/sent');
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact: reading a message hides the folder bar', (
      tester,
    ) async {
      await pumpSokoMailApp(
        tester,
        size: TestViewports.phone,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.text(SampleSubjects.fieldTest));
      await tester.pumpAndSettle();

      expect(find.byType(ShellBottomBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Reply'), findsOneWidget);
    });

    testWidgets('medium: collapsed sidebar that expands, and two panes', (
      tester,
    ) async {
      await pumpSokoMailApp(
        tester,
        size: TestViewports.tabletLandscape,
        signedInAs: UserRole.employee,
        location: '/mail/dev-personal/messages/dev-msg-001',
      );
      final sidebar = find.byKey(const ValueKey('shell-sidebar'));

      expect(find.byType(BrandAppBar), findsNothing);
      expect(find.byType(DrawerButton), findsNothing);
      expect(find.byType(ShellBottomBar), findsNothing);
      expect(tester.getSize(sidebar).width, 84);
      // List and reading pane side by side.
      expect(
        find.textContaining(SampleSubjects.fieldTestBodyOnly),
        findsOneWidget,
      );
      expect(find.text(SampleSubjects.engineeringSync), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 272);
      expect(find.text('Compose'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('medium: narrow tablets show one pane at a time', (
      tester,
    ) async {
      await pumpSokoMailApp(
        tester,
        size: const Size(620, 900),
        signedInAs: UserRole.employee,
        location: '/mail/dev-personal/messages/dev-msg-001',
      );

      expect(
        find.textContaining(SampleSubjects.fieldTestBodyOnly),
        findsOneWidget,
      );
      expect(find.text(SampleSubjects.engineeringSync), findsNothing);
    });

    testWidgets('expanded: sidebar, top bar, list and reading pane', (
      tester,
    ) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);

      expect(find.byType(ShellSidebar), findsOneWidget);
      expect(find.byKey(const ValueKey('top-search')), findsOneWidget);
      expect(find.bySemanticsLabel('Dark theme'), findsOneWidget);
      expect(find.text('No message selected'), findsOneWidget);
      expect(find.byType(ShellBottomBar), findsNothing);
    });

    testWidgets('expanded: the sidebar collapses to icons and remembers it', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );
      final sidebar = find.byKey(const ValueKey('shell-sidebar'));
      expect(tester.getSize(sidebar).width, 272);

      await tester.tap(find.byIcon(Icons.menu_open_rounded));
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 84);
      expect(find.text('Compose'), findsNothing);
      expect(
        container
            .read(preferencesStoreProvider)
            .readString(PreferenceKeys.sidebarCollapsed),
        'true',
      );

      // Icon-only navigation still works.
      await tester.tap(find.bySemanticsLabel('Sent'));
      await tester.pumpAndSettle();
      expect(container.location, '/mail/dev-personal/sent');

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 272);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the reading pane toolbar adapts to large text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final size in [TestViewports.desktop, const Size(834, 1112)]) {
        await pumpSokoMailApp(
          tester,
          size: size,
          signedInAs: UserRole.employee,
          location: '/mail/dev-personal/messages/dev-msg-001?folder=inbox',
        );
        expect(tester.takeException(), isNull, reason: '$size');
        expect(find.widgetWithText(FilledButton, 'Reply'), findsOneWidget);
      }
    });

    for (final entry in {
      'small phone': TestViewports.smallPhone,
      'phone': TestViewports.phone,
      'phone landscape': TestViewports.phoneLandscape,
      'tablet': TestViewports.tablet,
      'tablet landscape': TestViewports.tabletLandscape,
      'desktop': TestViewports.desktop,
    }.entries) {
      testWidgets('renders every main page without overflow: ${entry.key}', (
        tester,
      ) async {
        final container = await pumpSokoMailApp(tester, size: entry.value);
        expect(tester.takeException(), isNull, reason: 'sign-in screen');

        await tapVisible(tester, find.text('Continue as administrator'));
        expect(container.location, '/mail/dev-personal/inbox');

        for (final location in [
          '/mail/dev-personal/inbox',
          '/mail/dev-personal/messages/dev-msg-001',
          '/mail/dev-personal/starred',
          '/mail/dev-personal/drafts',
          '/mail/dev-shared/inbox',
          '/compose?mailboxId=dev-personal',
          '/compose?mode=forward&mailboxId=dev-personal&messageId=dev-msg-001',
          '/search?mailboxId=dev-personal&q=uav',
          '/mailboxes',
          '/settings',
          '/admin',
          '/unknown',
        ]) {
          container.router.go(location);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: location);
          expect(container.currentUri.path, isNot('/login'), reason: location);
        }
      });
    }
  });
}
