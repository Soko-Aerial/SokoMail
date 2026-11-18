import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/layout/responsive_layout.dart';
import 'package:sokomail/app/router/route_names.dart';
import 'package:sokomail/app/router/route_paths.dart';
import 'package:sokomail/features/compose/presentation/providers/compose_controller.dart';
import 'package:sokomail/features/inbox/presentation/screens/mail_folder_screen.dart';
import 'package:sokomail/features/message/presentation/screens/message_screen.dart';
import 'package:sokomail/features/message/presentation/widgets/no_message_selected_view.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';

/// Composes the folder list (inbox feature) and the reading pane (message
/// feature) into a responsive list/detail layout, and wires their callbacks
/// to routes.
///
/// This is a composition root: features stay unaware of each other and of
/// the router.
class MailWorkspace extends StatelessWidget {
  const MailWorkspace({
    super.key,
    required this.mailboxId,
    required this.folder,
    this.selectedMessageId,
  });

  final String mailboxId;
  final MailFolder folder;
  final String? selectedMessageId;

  @override
  Widget build(BuildContext context) {
    final selectedMessageId = this.selectedMessageId;

    void openCompose(ComposeMode mode, String messageId) => context.pushNamed(
      RouteNames.compose,
      queryParameters: {
        RouteQuery.mailboxId: mailboxId,
        RouteQuery.mode: mode.name,
        RouteQuery.messageId: messageId,
      },
    );

    void openMessage(MessageSummary message) {
      // Drafts open in Compose to continue editing, as in iOS Mail.
      if (message.folder == MailFolder.drafts) {
        openCompose(ComposeMode.editDraft, message.id);
        return;
      }
      context.goNamed(
        RouteNames.message,
        pathParameters: {
          RouteParams.mailboxId: mailboxId,
          RouteParams.messageId: message.id,
        },
        queryParameters: {RouteQuery.folder: folder.pathSegment},
      );
    }

    void closeMessage() => context.goNamed(
      RouteNames.forFolder(folder),
      pathParameters: {RouteParams.mailboxId: mailboxId},
    );

    void openSearch() => context.goNamed(
      RouteNames.search,
      queryParameters: {RouteQuery.mailboxId: mailboxId},
    );

    final layout = ListDetailLayout(
      showDetail: selectedMessageId != null,
      framed: WindowSizeClass.of(context) != WindowSizeClass.compact,
      list: MailFolderScreen(
        // A new key per folder resets scroll position when switching folders,
        // while selecting a message within the folder keeps it.
        key: ValueKey('folder-$mailboxId-${folder.name}'),
        mailboxId: mailboxId,
        folder: folder,
        selectedMessageId: selectedMessageId,
        onMessageSelected: openMessage,
        onOpenSearch: openSearch,
        onOpenSettings: () => context.goNamed(
          RouteNames.settings,
          queryParameters: {RouteQuery.mailboxId: mailboxId},
        ),
      ),
      detailBuilder: (context, isSinglePane) => selectedMessageId == null
          ? const NoMessageSelectedView()
          : MessageScreen(
              key: ValueKey('message-$mailboxId-$selectedMessageId'),
              mailboxId: mailboxId,
              messageId: selectedMessageId,
              presentation: isSinglePane
                  ? MessagePresentation.fullScreen
                  : MessagePresentation.pane,
              onClose: closeMessage,
              onReply: (action) => openCompose(switch (action) {
                ReplyAction.reply => ComposeMode.reply,
                ReplyAction.replyAll => ComposeMode.replyAll,
                ReplyAction.forward => ComposeMode.forward,
              }, selectedMessageId),
            ),
    );

    if (selectedMessageId == null) return layout;

    // With a message open, the system back button (Android) and Escape
    // (keyboard) return to the folder instead of leaving the app. Messages
    // are opened with `go` so their URL is shareable; this restores the
    // expected "back" behaviour for that flat navigation stack.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) closeMessage();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): closeMessage,
        },
        child: Focus(autofocus: true, child: layout),
      ),
    );
  }
}
