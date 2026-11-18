import 'package:material_ui/material_ui.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// Display labels and icons for [MailFolder]. Kept out of the model so the
/// domain stays free of UI concerns (and ready for localisation).
extension MailFolderPresentation on MailFolder {
  String get label => switch (this) {
    MailFolder.inbox => 'Inbox',
    MailFolder.starred => 'Starred',
    MailFolder.sent => 'Sent',
    MailFolder.drafts => 'Drafts',
    MailFolder.spam => 'Spam',
    MailFolder.trash => 'Trash',
  };

  IconData get icon => switch (this) {
    MailFolder.inbox => Icons.inbox_outlined,
    MailFolder.starred => Icons.star_outline_rounded,
    MailFolder.sent => Icons.send_outlined,
    MailFolder.drafts => Icons.description_outlined,
    MailFolder.spam => Icons.report_gmailerrorred_outlined,
    MailFolder.trash => Icons.delete_outline_rounded,
  };

  IconData get selectedIcon => switch (this) {
    MailFolder.inbox => Icons.inbox_rounded,
    MailFolder.starred => Icons.star_rounded,
    MailFolder.sent => Icons.send_rounded,
    MailFolder.drafts => Icons.description_rounded,
    MailFolder.spam => Icons.report_rounded,
    MailFolder.trash => Icons.delete_rounded,
  };

  String get emptyMessage => switch (this) {
    MailFolder.inbox => 'New messages will appear here.',
    MailFolder.starred => 'Star important messages to find them here.',
    MailFolder.sent => 'Messages you send will appear here.',
    MailFolder.drafts => 'Messages you start but do not send will appear here.',
    MailFolder.spam => 'Messages identified as spam will appear here.',
    MailFolder.trash => 'Deleted messages will appear here.',
  };

  /// Whether list rows should show recipients rather than the sender.
  bool get showsRecipients =>
      this == MailFolder.sent || this == MailFolder.drafts;
}
