import 'package:flutter/foundation.dart';
import 'package:sokomail/shared/models/attachment.dart';
import 'package:sokomail/shared/models/email_address.dart';

/// An unsent message.
///
/// Reserved for the drafts milestone: drafts will be saved through the Go API
/// (which stores them in the mailbox's Drafts folder) so they are available on
/// every device. Phase 1 does not save drafts.
@immutable
class EmailDraft {
  const EmailDraft({
    required this.mailboxId,
    required this.updatedAt,
    this.id,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject = '',
    this.bodyText = '',
    this.attachments = const [],
    this.inReplyToMessageId,
  });

  /// `null` until the server has stored the draft.
  final String? id;

  /// The mailbox the message will be sent from.
  final String mailboxId;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final List<EmailAddress> bcc;
  final String subject;
  final String bodyText;
  final List<Attachment> attachments;

  /// Set for replies and forwards.
  final String? inReplyToMessageId;
  final DateTime updatedAt;

  bool get hasRecipients => to.isNotEmpty || cc.isNotEmpty || bcc.isNotEmpty;
}
