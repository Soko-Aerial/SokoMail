import 'package:sokomail/features/drafts/domain/entities/email_draft.dart';

/// Saves unsent messages.
///
/// The API-backed implementation will store drafts in the mailbox's Drafts
/// folder on the server so they sync across devices.
abstract interface class DraftRepository {
  /// Creates the draft, or updates it when [EmailDraft.id] is set.
  /// Returns the draft's id.
  Future<String> saveDraft(EmailDraft draft);
}
