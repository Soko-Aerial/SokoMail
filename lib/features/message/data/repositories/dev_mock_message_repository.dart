// DEVELOPMENT ONLY: reads and updates the local demo store. Changes last for
// this app session only. See dev_mail_store.dart.

import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/message/domain/entities/email_message.dart';
import 'package:sokomail/features/message/domain/repositories/message_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';
import 'package:sokomail/shared/dev/dev_sample_data.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

class DevMockMessageRepository implements MessageRepository {
  const DevMockMessageRepository(this._store);

  final DevMailStore _store;

  @override
  Future<EmailMessage> getMessage({
    required String mailboxId,
    required String messageId,
  }) async {
    final sample = _store.find(mailboxId, messageId);
    if (sample == null) throw const NotFoundFailure();

    return EmailMessage(
      id: sample.id,
      mailboxId: sample.mailboxId,
      folder: sample.folder,
      from: sample.from,
      to: sample.to,
      cc: sample.cc,
      bcc: sample.bcc,
      subject: sample.subject,
      sentAt: sample.sentAt,
      bodyText: sample.body,
      isRead: sample.isRead,
      isStarred: sample.isStarred,
      attachments: sample.attachments,
    );
  }

  @override
  Future<void> setStarred({
    required String mailboxId,
    required String messageId,
    required bool starred,
  }) async =>
      _update(mailboxId, messageId, (m) => m.copyWith(isStarred: starred));

  @override
  Future<void> setRead({
    required String mailboxId,
    required String messageId,
    required bool read,
  }) async => _update(mailboxId, messageId, (m) => m.copyWith(isRead: read));

  @override
  Future<void> moveToFolder({
    required String mailboxId,
    required String messageId,
    required MailFolder folder,
  }) async {
    if (folder.isVirtual) {
      throw const InvalidRequestFailure(
        debugMessage: 'Cannot move a message into a virtual folder.',
      );
    }
    _update(mailboxId, messageId, (m) => m.copyWith(folder: folder));
  }

  void _update(
    String mailboxId,
    String messageId,
    DevSampleMessage Function(DevSampleMessage) change,
  ) {
    if (!_store.update(mailboxId, messageId, change)) {
      throw const NotFoundFailure();
    }
  }
}
