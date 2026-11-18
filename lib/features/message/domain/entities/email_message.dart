import 'package:flutter/foundation.dart';
import 'package:sokomail/shared/models/attachment.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// A complete message, as shown in the reading pane.
@immutable
class EmailMessage {
  const EmailMessage({
    required this.id,
    required this.mailboxId,
    required this.folder,
    required this.from,
    required this.to,
    required this.subject,
    required this.sentAt,
    required this.bodyText,
    required this.isRead,
    required this.isStarred,
    this.cc = const [],
    this.bcc = const [],
    this.attachments = const [],
  });

  final String id;
  final String mailboxId;

  /// The storage folder (never [MailFolder.starred]).
  final MailFolder folder;
  final EmailAddress from;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;

  /// Only populated for messages the user sent.
  final List<EmailAddress> bcc;
  final String subject;
  final DateTime sentAt;

  /// Plain-text body. HTML bodies will require server-side sanitisation and
  /// a sandboxed renderer before they can be displayed (security review
  /// item for the message milestone).
  final String bodyText;
  final bool isRead;
  final bool isStarred;
  final List<Attachment> attachments;

  EmailMessage copyWith({MailFolder? folder, bool? isRead, bool? isStarred}) {
    return EmailMessage(
      id: id,
      mailboxId: mailboxId,
      folder: folder ?? this.folder,
      from: from,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      sentAt: sentAt,
      bodyText: bodyText,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      attachments: attachments,
    );
  }
}
