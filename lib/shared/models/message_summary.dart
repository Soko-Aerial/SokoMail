import 'package:flutter/foundation.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// The lightweight representation of a message shown in lists (folders,
/// search results).
///
/// List endpoints return summaries; the full body and attachment metadata
/// are loaded separately when a message is opened (see the `message`
/// feature).
@immutable
class MessageSummary {
  const MessageSummary({
    required this.id,
    required this.mailboxId,
    required this.folder,
    required this.from,
    required this.to,
    required this.subject,
    required this.preview,
    required this.sentAt,
    required this.isRead,
    required this.isStarred,
    required this.hasAttachments,
  });

  final String id;
  final String mailboxId;

  /// The storage folder (never [MailFolder.starred]).
  final MailFolder folder;
  final EmailAddress from;
  final List<EmailAddress> to;
  final String subject;

  /// Short plain-text excerpt of the body.
  final String preview;
  final DateTime sentAt;
  final bool isRead;
  final bool isStarred;
  final bool hasAttachments;
}
