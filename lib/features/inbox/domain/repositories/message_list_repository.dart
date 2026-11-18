import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';

/// Lists messages in a mailbox folder, newest first, and provides the badge
/// counts shown in navigation.
///
/// Pagination (cursor-based) arrives with the Go API contract.
/// Implementations throw `AppFailure`s.
abstract interface class MessageListRepository {
  Future<List<MessageSummary>> getMessages({
    required String mailboxId,
    required MailFolder folder,
  });

  /// Navigation badge per folder: unread messages for Inbox and Spam, total
  /// messages for Drafts. Folders without a badge are omitted.
  Future<Map<MailFolder, int>> getBadgeCounts({required String mailboxId});
}
