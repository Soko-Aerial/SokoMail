// DEVELOPMENT ONLY: serves invented sample mailboxes. See dev_sample_data.dart.

import 'package:sokomail/features/mailboxes/domain/entities/mailbox.dart';
import 'package:sokomail/features/mailboxes/domain/repositories/mailbox_repository.dart';
import 'package:sokomail/shared/dev/dev_sample_data.dart';

class DevMockMailboxRepository implements MailboxRepository {
  const DevMockMailboxRepository();

  @override
  Future<List<Mailbox>> getAccessibleMailboxes() async {
    return [
      for (final sample in DevSampleData.mailboxes)
        Mailbox(
          id: sample.id,
          emailAddress: sample.address,
          displayName: sample.displayName,
          kind: sample.isShared ? MailboxKind.shared : MailboxKind.personal,
          permissions: sample.isShared
              ? const {MailboxPermission.read}
              : const {MailboxPermission.read, MailboxPermission.send},
        ),
    ];
  }
}
