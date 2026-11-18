// =============================================================================
// DEVELOPMENT ONLY - LOCAL DEMO DATA.
//
// An in-memory stand-in for the SokoMail Go API so the UI can demonstrate
// starring, read state, moving messages and saving drafts. Changes live only
// in this app session: nothing is sent anywhere or persisted.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/shared/dev/dev_sample_data.dart';
import 'package:sokomail/shared/models/attachment.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';

class DevMailStore {
  DevMailStore({DateTime? now})
    : _messages = {
        for (final message in DevSampleData.messages(now ?? DateTime.now()))
          message.id: message,
      };

  final Map<String, DevSampleMessage> _messages;
  int _nextDraftNumber = 1;

  Iterable<DevSampleMessage> inMailbox(String mailboxId) =>
      _messages.values.where((m) => m.mailboxId == mailboxId);

  /// Messages shown in [folder], newest first. [MailFolder.starred] is the
  /// virtual view of starred messages outside Spam and Trash.
  List<DevSampleMessage> list(String mailboxId, MailFolder folder) {
    final matches = inMailbox(mailboxId).where(
      (m) => folder == MailFolder.starred
          ? m.isStarred &&
                m.folder != MailFolder.spam &&
                m.folder != MailFolder.trash
          : m.folder == folder,
    );
    return matches.toList()..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  DevSampleMessage? find(String mailboxId, String messageId) {
    final message = _messages[messageId];
    return message?.mailboxId == mailboxId ? message : null;
  }

  /// Applies [change] to a message. Returns false if it does not exist.
  bool update(
    String mailboxId,
    String messageId,
    DevSampleMessage Function(DevSampleMessage) change,
  ) {
    final message = find(mailboxId, messageId);
    if (message == null) return false;
    _messages[messageId] = change(message);
    return true;
  }

  /// Creates or replaces a draft and returns its id.
  String saveDraft({
    required String mailboxId,
    required String? draftId,
    required List<EmailAddress> to,
    required List<EmailAddress> cc,
    required List<EmailAddress> bcc,
    required String subject,
    required String body,
    required List<Attachment> attachments,
    required DateTime savedAt,
  }) {
    final mailbox = DevSampleData.mailboxes.firstWhere(
      (m) => m.id == mailboxId,
      orElse: () => DevSampleData.mailboxes.first,
    );
    final id = draftId ?? 'dev-draft-local-${_nextDraftNumber++}';
    _messages[id] = DevSampleMessage(
      id: id,
      mailboxId: mailbox.id,
      folder: MailFolder.drafts,
      from: mailbox.emailAddress,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      body: body,
      sentAt: savedAt,
      isRead: true,
      attachments: attachments,
    );
    return id;
  }
}

/// One store per app session, shared by all `DevMock*` repositories.
final devMailStoreProvider = Provider<DevMailStore>((ref) => DevMailStore());

extension DevSampleMessageSummary on DevSampleMessage {
  static const _previewLength = 140;

  MessageSummary toSummary() {
    final singleLine = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return MessageSummary(
      id: id,
      mailboxId: mailboxId,
      folder: folder,
      from: from,
      to: to,
      subject: subject,
      preview: singleLine.length <= _previewLength
          ? singleLine
          : '${singleLine.substring(0, _previewLength)}...',
      sentAt: sentAt,
      isRead: isRead,
      isStarred: isStarred,
      hasAttachments: attachments.isNotEmpty,
    );
  }
}
