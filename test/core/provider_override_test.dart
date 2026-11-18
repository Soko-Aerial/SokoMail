import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/drafts/data/repositories/draft_repository_provider.dart';
import 'package:sokomail/features/inbox/data/repositories/message_list_repository_provider.dart';
import 'package:sokomail/features/inbox/domain/repositories/message_list_repository.dart';
import 'package:sokomail/features/inbox/presentation/providers/folder_messages_provider.dart';
import 'package:sokomail/features/inbox/presentation/screens/mail_folder_screen.dart';
import 'package:sokomail/features/mailboxes/data/repositories/mailbox_repository_provider.dart';
import 'package:sokomail/features/message/data/repositories/message_repository_provider.dart';
import 'package:sokomail/features/search/data/repositories/mail_search_repository_provider.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';

class _FakeMessageListRepository implements MessageListRepository {
  _FakeMessageListRepository(this._result);

  final Future<List<MessageSummary>> Function() _result;
  int calls = 0;

  @override
  Future<List<MessageSummary>> getMessages({
    required String mailboxId,
    required MailFolder folder,
  }) {
    calls++;
    return _result();
  }

  @override
  Future<Map<MailFolder, int>> getBadgeCounts({
    required String mailboxId,
  }) async => const {};
}

MessageSummary _summary(String subject) => MessageSummary(
  id: 'fake-1',
  mailboxId: 'box',
  folder: MailFolder.inbox,
  from: const EmailAddress('fake@example.com', displayName: 'Fake Sender'),
  to: const [],
  subject: subject,
  preview: 'Preview',
  sentAt: DateTime.utc(2026),
  isRead: false,
  isStarred: false,
  hasAttachments: false,
);

Future<void> _pumpFolder(
  WidgetTester tester,
  MessageListRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [messageListRepositoryProvider.overrideWithValue(repo)],
      retry: (_, _) => null,
      child: MaterialApp(
        home: MailFolderScreen(
          mailboxId: 'box',
          folder: MailFolder.inbox,
          onMessageSelected: (_) {},
          onOpenSearch: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('repository overrides replace the data source in the UI', (
    tester,
  ) async {
    final repo = _FakeMessageListRepository(
      () async => [_summary('Subject from override')],
    );
    await _pumpFolder(tester, repo);

    expect(find.text('Subject from override'), findsOneWidget);
    expect(find.text('UAV integration update'), findsNothing);
  });

  testWidgets('failures show a user-safe message and retry', (tester) async {
    final repo = _FakeMessageListRepository(
      () async => throw const ForbiddenFailure(debugMessage: 'secret detail'),
    );
    await _pumpFolder(tester, repo);

    expect(find.text('Could not load Inbox'), findsOneWidget);
    expect(
      find.text('You do not have permission to access this.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret detail'), findsNothing);
    expect(repo.calls, 1);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });

  test('family providers read through the overridden repository', () async {
    final container = ProviderContainer.test(
      overrides: [
        messageListRepositoryProvider.overrideWithValue(
          _FakeMessageListRepository(() async => [_summary('From container')]),
        ),
      ],
    );

    final messages = await container.read(
      folderMessagesProvider((
        mailboxId: 'box',
        folder: MailFolder.inbox,
      )).future,
    );
    expect(messages.single.subject, 'From container');
  });

  test('without development fixtures, repositories refuse to invent data', () {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
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

    for (final provider in [
      mailboxRepositoryProvider,
      messageListRepositoryProvider,
      messageRepositoryProvider,
      draftRepositoryProvider,
      mailSearchRepositoryProvider,
    ]) {
      Object? error;
      try {
        container.read(provider);
      } on Object catch (e) {
        error = e;
      }
      expect(AppFailure.from(error!), isA<FeatureUnavailableFailure>());
    }
  });
}
