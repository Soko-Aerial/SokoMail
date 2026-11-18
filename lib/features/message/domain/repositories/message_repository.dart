import 'package:sokomail/features/message/domain/entities/email_message.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// Reads and updates individual messages.
///
/// Implementations throw `AppFailure`s, for example `NotFoundFailure` when
/// the message does not exist or is not accessible.
abstract interface class MessageRepository {
  Future<EmailMessage> getMessage({
    required String mailboxId,
    required String messageId,
  });

  Future<void> setStarred({
    required String mailboxId,
    required String messageId,
    required bool starred,
  });

  Future<void> setRead({
    required String mailboxId,
    required String messageId,
    required bool read,
  });

  /// Moves a message to a storage folder. Deleting moves to Trash.
  /// [folder] must not be a virtual view such as Starred.
  Future<void> moveToFolder({
    required String mailboxId,
    required String messageId,
    required MailFolder folder,
  });
}
