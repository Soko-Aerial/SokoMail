/// The mail views every SokoMail mailbox exposes.
///
/// [pathSegment] is part of the public URL (`/mail/:mailboxId/<segment>`),
/// so values must stay stable once released. The Go API will map these to
/// the server's IMAP folders; the client never uses IMAP names.
enum MailFolder {
  inbox('inbox'),

  /// Virtual view: starred (flagged) messages from every folder except Spam
  /// and Trash. A message is never stored "in" Starred.
  starred('starred'),
  sent('sent'),
  drafts('drafts'),
  spam('spam'),
  trash('trash');

  const MailFolder(this.pathSegment);

  final String pathSegment;

  /// Whether this is a filtered view rather than a storage folder.
  bool get isVirtual => this == MailFolder.starred;

  static MailFolder? fromPathSegment(String? segment) {
    for (final folder in values) {
      if (folder.pathSegment == segment) return folder;
    }
    return null;
  }
}
