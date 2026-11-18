import 'package:sokomail/shared/models/message_summary.dart';

/// Searches a mailbox by sender, subject and content.
///
/// The API-backed implementation will search on the server (IMAP SEARCH via
/// the Go API); the offline milestone may add a local index.
abstract interface class MailSearchRepository {
  Future<List<MessageSummary>> search({
    required String mailboxId,
    required String query,
  });
}
