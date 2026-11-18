import 'package:flutter/foundation.dart';

/// What the signed-in employee may do with a mailbox.
///
/// Permissions are granted and enforced by the Go API. The client uses them
/// only to enable or hide UI.
enum MailboxPermission {
  /// Read messages in the mailbox.
  read,

  /// Send messages from the mailbox address.
  send,

  /// Manage folders, rules and other members' access.
  manage,
}

enum MailboxKind {
  /// The employee's own mailbox.
  personal,

  /// A team mailbox shared by several employees (for example support@).
  shared,
}

/// A company mailbox the signed-in employee can access.
///
/// Mailbox credentials (IMAP/SMTP) never reach the client: the Go API holds
/// them and talks to the mail server on the employee's behalf.
@immutable
class Mailbox {
  const Mailbox({
    required this.id,
    required this.emailAddress,
    required this.displayName,
    required this.kind,
    required this.permissions,
  });

  final String id;
  final String emailAddress;
  final String displayName;
  final MailboxKind kind;
  final Set<MailboxPermission> permissions;

  bool get canSend => permissions.contains(MailboxPermission.send);
}
