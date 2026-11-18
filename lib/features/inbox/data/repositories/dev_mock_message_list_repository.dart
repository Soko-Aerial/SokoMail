// DEVELOPMENT ONLY: reads the local demo store. See dev_mail_store.dart.

import 'package:sokomail/features/inbox/domain/repositories/message_list_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';

class DevMockMessageListRepository implements MessageListRepository {
  const DevMockMessageListRepository(this._store);

  final DevMailStore _store;

  @override
  Future<List<MessageSummary>> getMessages({
    required String mailboxId,
    required MailFolder folder,
  }) async {
    return [for (final m in _store.list(mailboxId, folder)) m.toSummary()];
  }

  @override
  Future<Map<MailFolder, int>> getBadgeCounts({
    required String mailboxId,
  }) async {
    int unread(MailFolder folder) =>
        _store.list(mailboxId, folder).where((m) => !m.isRead).length;

    return {
      MailFolder.inbox: unread(MailFolder.inbox),
      MailFolder.drafts: _store.list(mailboxId, MailFolder.drafts).length,
      MailFolder.spam: unread(MailFolder.spam),
    }..removeWhere((_, count) => count == 0);
  }
}
