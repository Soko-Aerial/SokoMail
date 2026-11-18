import 'package:sokomail/shared/models/mail_folder.dart';

/// Path parameter names.
abstract final class RouteParams {
  static const mailboxId = 'mailboxId';
  static const messageId = 'id';
}

/// Query parameter names.
abstract final class RouteQuery {
  /// Location to return to after signing in.
  static const from = 'from';

  /// Folder whose list is shown beside an open message.
  static const folder = 'folder';

  /// Mailbox context for pages outside `/mail/...` (search, compose, ...).
  static const mailboxId = 'mailboxId';

  /// Search text.
  static const query = 'q';

  /// Compose mode (`reply`, `replyAll`, `forward`, `editDraft`).
  static const mode = 'mode';

  /// Message a compose mode refers to.
  static const messageId = 'messageId';
}

/// URL path templates and location builders.
///
/// These paths are public URLs (browser address bar, deep links, push
/// notification targets). Treat changes as breaking.
abstract final class RoutePaths {
  static const root = '/';
  static const login = '/login';
  static const mailbox = '/mail/:${RouteParams.mailboxId}';
  static const message =
      '/mail/:${RouteParams.mailboxId}/messages/:${RouteParams.messageId}';
  static const compose = '/compose';
  static const search = '/search';
  static const mailboxes = '/mailboxes';
  static const settings = '/settings';
  static const admin = '/admin';

  /// `/mail/:mailboxId/inbox`, `/mail/:mailboxId/starred`, ...
  static String folderTemplate(MailFolder folder) =>
      '/mail/:${RouteParams.mailboxId}/${folder.pathSegment}';

  /// Concrete location of a folder, e.g. `/mail/abc/inbox`.
  static String folderLocation(String mailboxId, MailFolder folder) =>
      '/mail/${Uri.encodeComponent(mailboxId)}/${folder.pathSegment}';
}
