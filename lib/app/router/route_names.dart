import 'package:sokomail/shared/models/mail_folder.dart';

/// Route names for `context.goNamed(...)`. Prefer names over raw paths so
/// that paths can change without touching call sites.
abstract final class RouteNames {
  static const login = 'login';
  static const mailInbox = 'mailInbox';
  static const mailStarred = 'mailStarred';
  static const mailSent = 'mailSent';
  static const mailDrafts = 'mailDrafts';
  static const mailSpam = 'mailSpam';
  static const mailTrash = 'mailTrash';
  static const message = 'message';
  static const compose = 'compose';
  static const search = 'search';
  static const mailboxes = 'mailboxes';
  static const settings = 'settings';
  static const admin = 'admin';

  static String forFolder(MailFolder folder) => switch (folder) {
    MailFolder.inbox => mailInbox,
    MailFolder.starred => mailStarred,
    MailFolder.sent => mailSent,
    MailFolder.drafts => mailDrafts,
    MailFolder.spam => mailSpam,
    MailFolder.trash => mailTrash,
  };

  /// The folder shown by the route called [routeName], if it is a folder route.
  static MailFolder? folderOf(String? routeName) {
    for (final folder in MailFolder.values) {
      if (forFolder(folder) == routeName) return folder;
    }
    return null;
  }
}
