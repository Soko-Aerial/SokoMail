import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokomail/features/compose/data/datasources/attachment_picker.dart';
import 'package:sokomail/features/compose/presentation/providers/compose_controller.dart';
import 'package:sokomail/features/inbox/data/repositories/message_list_repository_provider.dart';
import 'package:sokomail/features/message/domain/entities/email_message.dart';
import 'package:sokomail/shared/models/attachment.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/providers/mail_data_version.dart';

class FakeAttachmentPicker implements AttachmentPicker {
  @override
  Future<List<Attachment>> pickFiles() async => const [
    Attachment(
      id: 'local-1',
      fileName: 'notes.txt',
      mimeType: 'text/plain',
      sizeBytes: 2048,
    ),
  ];
}

final _original = EmailMessage(
  id: 'm1',
  mailboxId: 'box',
  folder: MailFolder.inbox,
  from: const EmailAddress('lead@example.com', displayName: 'Team Lead'),
  to: const [
    EmailAddress('me@example.com', displayName: 'Me'),
    EmailAddress('colleague@example.com'),
  ],
  cc: const [EmailAddress('observer@example.com')],
  subject: 'Status',
  sentAt: DateTime(2026, 11, 17, 9, 30),
  bodyText: 'Line one\nLine two',
  isRead: true,
  isStarred: false,
  attachments: const [
    Attachment(
      id: 'a1',
      fileName: 'plan.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1000,
    ),
  ],
);

void main() {
  group('EmailAddress.isValid', () {
    test('accepts ordinary addresses', () {
      expect(EmailAddress.isValid('a@example.com'), isTrue);
      expect(EmailAddress.isValid(' first.last@sub.example.co '), isTrue);
    });

    test('rejects malformed input', () {
      expect(EmailAddress.isValid(''), isFalse);
      expect(EmailAddress.isValid('no-at-sign'), isFalse);
      expect(EmailAddress.isValid('a@b'), isFalse);
      expect(EmailAddress.isValid('two@@example.com'), isFalse);
    });
  });

  group('ComposeState', () {
    test('collects recipients from To, Cc and Bcc', () {
      const state = ComposeState(
        to: 'a@example.com, b@example.com',
        cc: 'c@example.com;',
        bcc: ' d@example.com ',
      );
      expect(state.allRecipients, [
        'a@example.com',
        'b@example.com',
        'c@example.com',
        'd@example.com',
      ]);
      expect(state.hasValidRecipients, isTrue);
    });

    test('reports invalid recipients in any field', () {
      const state = ComposeState(to: 'a@example.com', bcc: 'nope');
      expect(state.invalidRecipients, ['nope']);
      expect(state.hasValidRecipients, isFalse);
    });

    test('is empty only when nothing has been entered', () {
      expect(const ComposeState().isEmpty, isTrue);
      expect(const ComposeState(subject: ' ').isEmpty, isTrue);
      expect(const ComposeState(body: 'Hi').isEmpty, isFalse);
    });
  });

  group('ComposeTemplates', () {
    const base = ComposeState(fromMailboxId: 'box');
    const own = {'me@example.com'};

    test('reply addresses the sender and quotes the message', () {
      final state = ComposeTemplates.prefill(
        base,
        mode: ComposeMode.reply,
        original: _original,
        ownAddresses: own,
      );
      expect(state.to, 'lead@example.com');
      expect(state.subject, 'Re: Status');
      expect(state.body, contains('> Line one\n> Line two'));
      expect(state.inReplyToMessageId, 'm1');
    });

    test('reply all includes everyone except the user', () {
      final state = ComposeTemplates.prefill(
        base,
        mode: ComposeMode.replyAll,
        original: _original,
        ownAddresses: own,
      );
      expect(state.to, 'lead@example.com, colleague@example.com');
      expect(state.cc, 'observer@example.com');
      expect(state.showCcBcc, isTrue);
    });

    test('forward keeps attachments and does not double prefixes', () {
      final state = ComposeTemplates.prefill(
        base,
        mode: ComposeMode.forward,
        original: _original,
        ownAddresses: own,
      );
      expect(state.to, isEmpty);
      expect(state.subject, 'Fwd: Status');
      expect(state.attachments.single.fileName, 'plan.pdf');
      expect(state.body, contains('Forwarded message'));

      final again = ComposeTemplates.prefill(
        base,
        mode: ComposeMode.reply,
        original: _original,
        ownAddresses: own,
      );
      expect(again.subject, 'Re: Status');
    });

    test('editing a draft restores its fields and id', () {
      final state = ComposeTemplates.prefill(
        base,
        mode: ComposeMode.editDraft,
        original: _original,
        ownAddresses: own,
      );
      expect(state.draftId, 'm1');
      expect(state.subject, 'Status');
      expect(state.body, 'Line one\nLine two');
    });
  });

  group('ComposeController', () {
    ComposeRequest request({
      ComposeMode mode = ComposeMode.newMessage,
      String? mailboxId = 'dev-personal',
      String? messageId,
    }) => (mode: mode, mailboxId: mailboxId, messageId: messageId);

    test('sends only from mailboxes with send permission', () async {
      final container = ProviderContainer.test();
      final state = await container.read(
        composeControllerProvider(request(mailboxId: 'dev-shared')).future,
      );
      expect(state.senderMailboxes.map((m) => m.id), ['dev-personal']);
      expect(state.fromMailboxId, 'dev-personal');
    });

    test('reply is pre-filled from the sample message', () async {
      final container = ProviderContainer.test();
      final state = await container.read(
        composeControllerProvider(
          request(mode: ComposeMode.reply, messageId: 'dev-msg-001'),
        ).future,
      );
      expect(state.to, 'david.njoroge@example.com');
      expect(state.subject, 'Re: Drone Field Test – Project Update');
    });

    test('reply all keeps team mailboxes the user can read', () async {
      final container = ProviderContainer.test();
      final state = await container.read(
        composeControllerProvider(
          request(mode: ComposeMode.replyAll, messageId: 'dev-msg-002'),
        ).future,
      );
      // dev-msg-002 is to Engineering and Cc the user: the user is dropped,
      // the shared Engineering mailbox stays.
      expect(state.to, 'regina.kibwana@example.com, engineering@example.com');
      expect(state.cc, isEmpty);
    });

    test('edits mark the form dirty; sending stays unavailable', () async {
      final container = ProviderContainer.test();
      final provider = composeControllerProvider(request());
      await container.read(provider.future);
      final controller = container.read(provider.notifier)
        ..setTo('a@example.com')
        ..setSubject('Hello')
        ..setBody('Body');

      final state = container.read(provider).value!;
      expect(state.hasUnsavedChanges, isTrue);
      expect(state.hasValidRecipients, isTrue);
      expect(controller.canSend, isFalse);
    });

    test('saving a draft stores it locally and notifies lists', () async {
      final container = ProviderContainer.test();
      final provider = composeControllerProvider(request());
      await container.read(provider.future);
      final versionBefore = container.read(mailDataVersionProvider);

      container.read(provider.notifier)
        ..setTo('ops@example.com')
        ..setSubject('Prototype notes');
      await container.read(provider.notifier).saveDraft();

      final state = container.read(provider).value!;
      expect(state.draftId, isNotNull);
      expect(state.hasUnsavedChanges, isFalse);
      expect(container.read(mailDataVersionProvider), versionBefore + 1);

      final drafts = await container
          .read(messageListRepositoryProvider)
          .getMessages(mailboxId: 'dev-personal', folder: MailFolder.drafts);
      expect(drafts.map((d) => d.subject), contains('Prototype notes'));
    });

    test('attachments come from the picker and can be removed', () async {
      final container = ProviderContainer.test(
        overrides: [
          attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker()),
        ],
      );
      final provider = composeControllerProvider(request());
      await container.read(provider.future);
      final controller = container.read(provider.notifier);

      expect(await controller.pickAttachments(), 1);
      final attached = container.read(provider).value!.attachments;
      expect(attached.single.fileName, 'notes.txt');

      controller.removeAttachment(attached.single);
      expect(container.read(provider).value!.attachments, isEmpty);
    });
  });
}
