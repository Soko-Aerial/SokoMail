import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/shell/shell_top_bar.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/compose/data/datasources/attachment_picker.dart';
import 'package:sokomail/features/inbox/presentation/providers/folder_messages_provider.dart';
import 'package:sokomail/features/message/presentation/screens/message_screen.dart';
import 'package:sokomail/features/search/presentation/screens/search_screen.dart';
import 'package:sokomail/shared/widgets/message_list_tile.dart';

import '../helpers/test_app.dart';
import 'compose/compose_controller_test.dart' show FakeAttachmentPicker;

/// A filter menu entry (the item, not its label, receives the tap).
Finder _filterOption(String label) =>
    find.widgetWithText(CheckedPopupMenuItem<MessageFilter>, label);

Finder _tile(String subject) => find.ancestor(
  of: find.text(subject),
  matching: find.byType(MessageListTile),
);

/// A control inside the open message (not the folder list beside it).
Finder _inMessage(Finder finder) =>
    find.descendant(of: find.byType(MessageScreen), matching: finder);

String _fieldText(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

void main() {
  group('Inbox interactions', () {
    testWidgets('starring a message adds it to Starred', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.tap(
        find.descendant(
          of: _tile(SampleSubjects.engineeringSync),
          matching: find.byIcon(Icons.star_outline_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _tile(SampleSubjects.engineeringSync),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsOneWidget,
      );

      container.router.go('/mail/dev-personal/starred');
      await tester.pumpAndSettle();
      expect(find.text(SampleSubjects.engineeringSync), findsOneWidget);
      expect(find.text(SampleSubjects.supplierUpdate), findsOneWidget);
    });

    testWidgets('opening an unread message marks it read', (tester) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);
      expect(find.text('3 unread • 10 total'), findsOneWidget);

      await tester.tap(find.text(SampleSubjects.fieldTest));
      await tester.pumpAndSettle();

      expect(find.text('2 unread • 10 total'), findsOneWidget);
    });

    testWidgets('mark as unread returns to the list', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );
      await tester.tap(find.text(SampleSubjects.supplierUpdate));
      await tester.pumpAndSettle();

      await tester.tap(_inMessage(find.byIcon(Icons.more_vert_rounded)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as unread'));
      await tester.pumpAndSettle();

      expect(container.location, '/mail/dev-personal/inbox');
      expect(find.text('4 unread • 10 total'), findsOneWidget);
    });

    testWidgets('delete moves the message to Trash', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );
      await tester.tap(find.text(SampleSubjects.policyReminder));
      await tester.pumpAndSettle();

      await tester.tap(
        _inMessage(
          find.widgetWithIcon(IconButton, Icons.delete_outline_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Moved to Trash'), findsOneWidget);
      expect(container.location, '/mail/dev-personal/inbox');
      expect(find.text(SampleSubjects.policyReminder), findsNothing);

      container.router.go('/mail/dev-personal/trash');
      await tester.pumpAndSettle();
      expect(find.text(SampleSubjects.policyReminder), findsOneWidget);
    });

    testWidgets('report spam moves the message to Spam', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );
      await tester.tap(find.text(SampleSubjects.policyReminder));
      await tester.pumpAndSettle();

      await tester.tap(_inMessage(find.byIcon(Icons.more_vert_rounded)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report spam'));
      await tester.pumpAndSettle();

      container.router.go('/mail/dev-personal/spam');
      await tester.pumpAndSettle();
      expect(find.text(SampleSubjects.policyReminder), findsOneWidget);
    });

    testWidgets('archive in a narrow pane is in the More menu', (tester) async {
      // Tablet portrait: the reading pane is too narrow for every tool.
      await pumpSokoMailApp(
        tester,
        size: const Size(834, 1112),
        signedInAs: UserRole.employee,
        location: '/mail/dev-personal/messages/dev-msg-001?folder=inbox',
      );
      expect(
        _inMessage(find.widgetWithIcon(IconButton, Icons.archive_outlined)),
        findsNothing,
      );

      await tester.tap(_inMessage(find.byIcon(Icons.more_vert_rounded)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Archive'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the filter menu narrows the list', (tester) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(_filterOption('Unread'));
      await tester.pumpAndSettle();

      expect(find.text('Showing: Unread'), findsOneWidget);
      expect(find.text(SampleSubjects.fieldTest), findsOneWidget);
      expect(find.text(SampleSubjects.supplierUpdate), findsNothing);

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(_filterOption('All messages'));
      await tester.pumpAndSettle();
      expect(find.text(SampleSubjects.supplierUpdate), findsOneWidget);
    });

    testWidgets('mark all as read clears the unread count', (tester) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      expect(find.text('Marked 3 as read.'), findsOneWidget);
      expect(find.text('0 unread • 10 total'), findsOneWidget);
    });
  });

  group('Search and mailboxes', () {
    testWidgets('search filters sample messages as you type', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/search?mailboxId=dev-personal',
      );

      await tester.enterText(
        find.descendant(
          of: find.byType(SearchScreen),
          matching: find.byType(TextField),
        ),
        'Kibwana',
      );
      await tester.pumpAndSettle();

      expect(find.text('1 result'), findsOneWidget);
      await tester.tap(find.text(SampleSubjects.engineeringSync));
      await tester.pumpAndSettle();
      expect(
        container.location,
        '/mail/dev-personal/messages/dev-msg-002?folder=inbox',
      );
    });

    testWidgets('the desktop top bar submits a search', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.enterText(
        find.byKey(const ValueKey('top-search')),
        'battery',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(container.location, '/search?mailboxId=dev-personal&q=battery');
      expect(find.text(SampleSubjects.batteryQuote), findsOneWidget);
    });

    testWidgets('the sidebar mailbox list switches mailboxes', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.text('Operations'));
      await tester.pumpAndSettle();

      expect(container.location, '/mail/dev-shared/inbox');
      expect(find.text(SampleSubjects.shared), findsOneWidget);
    });

    testWidgets('the Mailboxes screen selects a mailbox', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        size: TestViewports.phone,
        signedInAs: UserRole.employee,
        location: '/mailboxes',
      );

      await tester.tap(find.text('Operations'));
      await tester.pumpAndSettle();

      expect(container.location, '/mail/dev-shared/inbox');
    });

    testWidgets('the account menu signs out', (tester) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
      );

      await tester.tap(find.byType(AccountMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(container.currentUri.path, '/login');
    });

    testWidgets('notifications explain they are not available', (tester) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Not available in this build'), findsOneWidget);
    });
  });

  group('Replies and compose', () {
    /// Opens the field-test message and taps one of the buttons under it.
    Future<void> openFieldTestAndTap(WidgetTester tester, Finder button) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);
      await tester.tap(find.text(SampleSubjects.fieldTest));
      await tester.pumpAndSettle();
      await tapVisible(tester, button);
    }

    testWidgets('Reply pre-fills the recipient and subject', (tester) async {
      await openFieldTestAndTap(
        tester,
        find.widgetWithText(FilledButton, 'Reply'),
      );

      expect(find.text('Reply'), findsOneWidget);
      expect(_fieldText(tester, 'compose-to'), 'david.njoroge@example.com');
      expect(
        _fieldText(tester, 'compose-subject'),
        'Re: ${SampleSubjects.fieldTest}',
      );
    });

    testWidgets('Reply all keeps team mailboxes and excludes the user', (
      tester,
    ) async {
      await openFieldTestAndTap(
        tester,
        find.widgetWithText(OutlinedButton, 'Reply all'),
      );

      final to = _fieldText(tester, 'compose-to');
      expect(to, contains('david.njoroge@example.com'));
      expect(to, contains('operations@example.com'));
      expect(to, isNot(contains('dev.employee@example.com')));
    });

    testWidgets('Forward carries the attachments', (tester) async {
      await openFieldTestAndTap(
        tester,
        find.widgetWithText(OutlinedButton, 'Forward'),
      );

      expect(
        _fieldText(tester, 'compose-subject'),
        'Fwd: ${SampleSubjects.fieldTest}',
      );
      // Attachments follow the (long) quoted body.
      const attachment = 'Field_Test_Report.pdf (2.8 MB)';
      await tester.ensureVisible(find.text(attachment));
      await tester.pumpAndSettle();
      expect(find.text(attachment), findsOneWidget);
    });

    testWidgets('Cc/Bcc fields can be revealed', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/compose',
      );
      expect(find.byKey(const ValueKey('compose-cc')), findsNothing);

      await tester.tap(find.text('Cc/Bcc'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('compose-cc')), findsOneWidget);
      expect(find.byKey(const ValueKey('compose-bcc')), findsOneWidget);
    });

    testWidgets('Send explains that sending is not available', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/compose',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();
      expect(find.text('Add at least one recipient.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('compose-to')),
        'ops@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();
      expect(find.text('Sending is not available yet'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Sending is not available yet'), findsNothing);
    });

    testWidgets('a saved draft appears in Drafts and reopens for editing', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/compose?mailboxId=dev-personal',
      );

      await tester.enterText(
        find.byKey(const ValueKey('compose-to')),
        'ops@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('compose-subject')),
        'Prototype notes',
      );
      await tester.tap(find.text('Save draft'));
      await tester.pumpAndSettle();
      expect(
        find.text('Draft saved to local demo data (not synced).'),
        findsOneWidget,
      );

      // Saved, so closing does not ask to discard.
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      container.router.go('/mail/dev-personal/drafts');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prototype notes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Draft'), findsOneWidget);
      expect(_fieldText(tester, 'compose-subject'), 'Prototype notes');
    });

    testWidgets('closing with unsaved changes asks first', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/compose',
      );
      await tester.enterText(
        find.byKey(const ValueKey('compose-subject')),
        'Unsaved',
      );

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard this message?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('New Message'), findsNothing);
    });

    testWidgets('chosen files are listed as attachments', (tester) async {
      await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/compose',
        overrides: [
          attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker()),
        ],
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.attach_file_rounded).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('notes.txt (2 KB)'), findsOneWidget);
      expect(
        find.text('Attachments are not uploaded in this build.'),
        findsOneWidget,
      );
    });
  });
}
