import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/router/not_found_screen.dart';
import 'package:sokomail/app/theme/app_theme.dart';
import 'package:sokomail/features/admin/presentation/screens/admin_screen.dart';
import 'package:sokomail/features/auth/presentation/screens/login_screen.dart';
import 'package:sokomail/features/compose/presentation/providers/compose_controller.dart';
import 'package:sokomail/features/compose/presentation/screens/compose_screen.dart';
import 'package:sokomail/features/inbox/presentation/screens/mail_folder_screen.dart';
import 'package:sokomail/features/mailboxes/presentation/screens/mailboxes_screen.dart';
import 'package:sokomail/features/message/presentation/screens/message_screen.dart';
import 'package:sokomail/features/message/presentation/widgets/no_message_selected_view.dart';
import 'package:sokomail/features/search/presentation/screens/search_screen.dart';
import 'package:sokomail/features/settings/presentation/screens/settings_screen.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// Renders a screen in isolation with the given theme.
Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      child: MaterialApp(theme: theme ?? AppTheme.light, home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final screens = <String, (Widget, String)>{
    'Login': (const LoginScreen(), 'Sign in to SokoMail'),
    'Search': (
      SearchScreen(mailboxId: 'dev-personal', onOpenMessage: (_) {}),
      'Search your mail',
    ),
    'Settings': (const SettingsScreen(), 'Appearance'),
    'Admin': (const AdminScreen(), 'Administration is not available yet'),
    'Mailboxes': (
      MailboxesScreen(
        selectedMailboxId: 'dev-personal',
        onMailboxSelected: (_) {},
      ),
      'Development Employee',
    ),
    'Compose': (
      ComposeScreen(
        request: (
          mode: ComposeMode.newMessage,
          mailboxId: 'dev-personal',
          messageId: null,
        ),
        onClose: () {},
      ),
      'New Message',
    ),
    'Not found': (const NotFoundScreen(path: '/x'), 'Page not found'),
    'No message selected': (
      const NoMessageSelectedView(),
      'No message selected',
    ),
    'Mail folder': (
      MailFolderScreen(
        mailboxId: 'dev-personal',
        folder: MailFolder.inbox,
        onMessageSelected: (_) {},
        onOpenSearch: () {},
      ),
      'Drone Field Test – Project Update',
    ),
    'Message': (
      MessageScreen(
        mailboxId: 'dev-personal',
        messageId: 'dev-msg-001',
        presentation: MessagePresentation.fullScreen,
        onClose: () {},
        onReply: (_) {},
      ),
      'Drone Field Test – Project Update',
    ),
  };

  for (final MapEntry(key: name, value: (screen, expectedText))
      in screens.entries) {
    testWidgets('$name screen renders in light and dark themes', (
      tester,
    ) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await _pumpScreen(tester, screen, theme: theme);
        expect(find.text(expectedText), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('server sign-in is disabled, not faked', (tester) async {
    await _pumpScreen(tester, const LoginScreen());
    final signIn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Sign in'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(signIn.onPressed, isNull);
  });

  testWidgets('placeholder settings explain what is missing', (tester) async {
    await _pumpScreen(tester, const SettingsScreen());

    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();

    expect(find.text('Not available in this build'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Not available in this build'), findsNothing);
  });
}
