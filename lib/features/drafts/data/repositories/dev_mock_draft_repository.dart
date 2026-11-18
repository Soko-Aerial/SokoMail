// DEVELOPMENT ONLY: saves drafts into the local demo store for this app
// session. Nothing is synced or persisted. See dev_mail_store.dart.

import 'package:sokomail/features/drafts/domain/entities/email_draft.dart';
import 'package:sokomail/features/drafts/domain/repositories/draft_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';

class DevMockDraftRepository implements DraftRepository {
  const DevMockDraftRepository(this._store);

  final DevMailStore _store;

  @override
  Future<String> saveDraft(EmailDraft draft) async {
    return _store.saveDraft(
      mailboxId: draft.mailboxId,
      draftId: draft.id,
      to: draft.to,
      cc: draft.cc,
      bcc: draft.bcc,
      subject: draft.subject,
      body: draft.bodyText,
      attachments: draft.attachments,
      savedAt: draft.updatedAt,
    );
  }
}
