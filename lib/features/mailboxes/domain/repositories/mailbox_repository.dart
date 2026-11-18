import 'package:sokomail/features/mailboxes/domain/entities/mailbox.dart';

/// Source of the mailboxes the signed-in employee may access.
///
/// Implementations throw `AppFailure`s, never transport exceptions.
abstract interface class MailboxRepository {
  Future<List<Mailbox>> getAccessibleMailboxes();
}
