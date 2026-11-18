import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/features/message/domain/entities/email_message.dart';
import 'package:sokomail/features/message/presentation/providers/message_detail_provider.dart';
import 'package:sokomail/features/message/presentation/widgets/attachment_card.dart';
import 'package:sokomail/features/message/presentation/widgets/message_body_text.dart';
import 'package:sokomail/shared/extensions/byte_size.dart';
import 'package:sokomail/shared/extensions/date_time_display.dart';
import 'package:sokomail/shared/extensions/mail_folder_presentation.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/widgets/app_error_view.dart';
import 'package:sokomail/shared/widgets/app_loading_indicator.dart';
import 'package:sokomail/shared/widgets/menu_item_label.dart';
import 'package:sokomail/shared/widgets/pill_label.dart';
import 'package:sokomail/shared/widgets/placeholder_notice.dart';
import 'package:sokomail/shared/widgets/sender_avatar.dart';

/// How the message is presented by the surrounding layout.
enum MessagePresentation {
  /// Fills the screen (phones): deep-green app bar over a rounded sheet.
  fullScreen,

  /// Beside the message list (wider layouts): light action toolbar.
  pane,
}

/// Replies the reading view can start. The app layer turns these into a
/// Compose route.
enum ReplyAction { reply, replyAll, forward }

/// Reading view for one message.
///
/// Star, read state, delete and spam actions change the local demo data in
/// development builds. Replies open Compose pre-filled; nothing is sent.
/// Archive, labels and downloads explain that they need the SokoMail API.
class MessageScreen extends ConsumerWidget {
  const MessageScreen({
    super.key,
    required this.mailboxId,
    required this.messageId,
    required this.presentation,
    required this.onClose,
    required this.onReply,
  });

  final String mailboxId;
  final String messageId;
  final MessagePresentation presentation;
  final VoidCallback onClose;
  final ValueChanged<ReplyAction> onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageRef = (mailboxId: mailboxId, messageId: messageId);
    final provider = messageDetailControllerProvider(messageRef);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final message = state.value;
    final isPane = presentation == MessagePresentation.pane;

    Future<void> moveTo(MailFolder folder, String confirmation) async {
      await controller.moveTo(folder);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(confirmation)));
      onClose();
    }

    void placeholder(String title, String text) =>
        unawaited(showPlaceholderNotice(context, title: title, message: text));

    void archive() => placeholder(
      'Archive',
      'Archiving moves mail to the server archive, which needs the '
          'SokoMail API.',
    );

    void labels() => placeholder(
      'Labels',
      'Labels are stored on the mail server and arrive with the '
          'SokoMail API.',
    );

    // In a narrow pane, Archive and Labels move into the More menu.
    List<Widget> actionsFor(EmailMessage message, {required bool compact}) => [
      if (message.folder == MailFolder.trash)
        IconButton(
          tooltip: 'Move to Inbox',
          icon: const Icon(Icons.restore_from_trash_outlined),
          onPressed: () => moveTo(MailFolder.inbox, 'Moved to Inbox'),
        )
      else
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => moveTo(MailFolder.trash, 'Moved to Trash'),
        ),
      if (!compact) ...[
        IconButton(
          tooltip: 'Archive',
          icon: const Icon(Icons.archive_outlined),
          onPressed: archive,
        ),
        IconButton(
          tooltip: 'Labels',
          icon: const Icon(Icons.label_outline_rounded),
          onPressed: labels,
        ),
      ],
      if (!isPane)
        IconButton(
          tooltip: message.isStarred ? 'Remove star' : 'Star',
          icon: Icon(
            message.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
          ),
          onPressed: controller.toggleStar,
        ),
      PopupMenuButton<_MoreAction>(
        tooltip: 'More actions',
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (action) async {
          switch (action) {
            case _MoreAction.archive:
              archive();
            case _MoreAction.labels:
              labels();
            case _MoreAction.markUnread:
              await controller.markUnread();
              onClose();
            case _MoreAction.reportSpam:
              await moveTo(MailFolder.spam, 'Moved to Spam');
            case _MoreAction.notSpam:
              await moveTo(MailFolder.inbox, 'Moved to Inbox');
          }
        },
        itemBuilder: (context) => [
          if (compact) ...const [
            PopupMenuItem(
              value: _MoreAction.archive,
              child: MenuItemLabel(Icons.archive_outlined, 'Archive'),
            ),
            PopupMenuItem(
              value: _MoreAction.labels,
              child: MenuItemLabel(Icons.label_outline_rounded, 'Labels'),
            ),
          ],
          const PopupMenuItem(
            value: _MoreAction.markUnread,
            child: MenuItemLabel(
              Icons.mark_email_unread_outlined,
              'Mark as unread',
            ),
          ),
          if (message.folder == MailFolder.spam)
            const PopupMenuItem(
              value: _MoreAction.notSpam,
              child: MenuItemLabel(Icons.inbox_outlined, 'Not spam'),
            )
          else
            const PopupMenuItem(
              value: _MoreAction.reportSpam,
              child: MenuItemLabel(Icons.report_outlined, 'Report spam'),
            ),
        ],
      ),
    ];

    final body = state.when(
      skipLoadingOnReload: true,
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => AppErrorView(
        title: 'Could not open this message',
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      data: (message) => _MessageBody(
        message: message,
        showStar: isPane,
        onToggleStar: controller.toggleStar,
        onReply: onReply,
        onDownload: () => placeholder(
          'Downloads',
          'Attachments will download through the SokoMail API. This demo '
              'build has no files behind the sample attachments.',
        ),
      ),
    );

    if (!isPane) {
      return Scaffold(
        backgroundColor: context.brandColors.header,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: onClose),
          actions: [
            if (message != null) ...actionsFor(message, compact: false),
            const SizedBox(width: 4),
          ],
        ),
        body: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 0),
            // The toolbar stays on one line at any pane width and text size,
            // dropping detail in steps: reply labels (measured, so large text
            // is accounted for), then Archive/Labels (into More), then the
            // reply group (the buttons under the message remain).
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final back = IconButton(
                  tooltip: 'Close message',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onClose,
                );
                if (message == null) {
                  return Align(alignment: Alignment.centerLeft, child: back);
                }

                final allTools = actionsFor(message, compact: false);
                final fewTools = actionsFor(message, compact: true);
                bool fits(double replies, List<Widget> tools) =>
                    _Toolbar.button +
                        replies +
                        _Toolbar.gap +
                        _Toolbar.group(tools.length) <=
                    width;

                final (replies, tools) = switch (true) {
                  _ when fits(_ReplyGroup.labelledWidth(context), allTools) => (
                    _ReplyGroup(showLabels: true, onReply: onReply),
                    allTools,
                  ),
                  _ when fits(_ReplyGroup.iconWidth, allTools) => (
                    _ReplyGroup(showLabels: false, onReply: onReply),
                    allTools,
                  ),
                  _ when fits(_ReplyGroup.iconWidth, fewTools) => (
                    _ReplyGroup(showLabels: false, onReply: onReply),
                    fewTools,
                  ),
                  _ => (null, fewTools),
                };

                return Row(
                  children: [
                    back,
                    const Spacer(),
                    if (replies != null) ...[
                      replies,
                      const SizedBox(width: _Toolbar.gap),
                    ],
                    _ToolGroup(children: tools),
                  ],
                );
              },
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

enum _MoreAction { archive, labels, markUnread, reportSpam, notSpam }

/// Toolbar measurements used to choose how much of it fits.
abstract final class _Toolbar {
  /// Icon buttons at their largest (48 px touch target).
  static const button = 48.0;

  /// Space between the reply group and the tool group.
  static const gap = 10.0;

  /// [_ToolGroup] padding on both sides.
  static const groupPadding = 4.0;

  /// Width of a [_ToolGroup] of [count] icon buttons.
  static double group(int count) => count * button + groupPadding;
}

/// Reply / Reply all / Forward grouped in one rounded container.
class _ReplyGroup extends StatelessWidget {
  const _ReplyGroup({required this.showLabels, required this.onReply});

  final bool showLabels;
  final ValueChanged<ReplyAction> onReply;

  static const _items = [
    (ReplyAction.reply, Icons.reply_rounded, 'Reply'),
    (ReplyAction.replyAll, Icons.reply_all_rounded, 'Reply all'),
    (ReplyAction.forward, Icons.forward_rounded, 'Forward'),
  ];
  static const _labelPadding = 14.0;
  static const _labelIconSize = 20.0;
  static const _labelIconGap = 8.0;
  static final _dividers = _items.length - 1.0;

  /// Width of the group without labels.
  static final iconWidth =
      _items.length * _Toolbar.button + _dividers + _Toolbar.groupPadding;

  static TextStyle? _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge;

  /// Width of the group with labels at the current font and text size.
  static double labelledWidth(BuildContext context) {
    var width = _dividers + _Toolbar.groupPadding;
    for (final (_, _, label) in _items) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: _labelStyle(context)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      width +=
          _labelPadding * 2 + _labelIconSize + _labelIconGap + painter.width;
      painter.dispose();
    }
    return width.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      textStyle: _labelStyle(context),
      minimumSize: const Size(44, 40),
      padding: const EdgeInsets.symmetric(horizontal: _labelPadding),
    );
    return _ToolGroup(
      children: [
        for (final (index, (action, icon, label)) in _items.indexed) ...[
          if (index > 0) const _GroupDivider(),
          if (showLabels)
            TextButton.icon(
              style: textStyle,
              onPressed: () => onReply(action),
              icon: Icon(icon, size: _labelIconSize),
              label: Text(label),
            )
          else
            IconButton(
              tooltip: label,
              onPressed: () => onReply(action),
              icon: Icon(icon),
            ),
        ],
      ],
    );
  }
}

class _ToolGroup extends StatelessWidget {
  const _ToolGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: VerticalDivider(
        width: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.message,
    required this.showStar,
    required this.onToggleStar,
    required this.onReply,
    required this.onDownload,
  });

  final EmailMessage message;
  final bool showStar;
  final VoidCallback onToggleStar;
  final ValueChanged<ReplyAction> onReply;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final attachments = message.attachments;
    final totalBytes = attachments.fold<int>(0, (sum, a) => sum + a.sizeBytes);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;
        final horizontal = narrow ? 20.0 : 32.0;
        final available = constraints.maxWidth - horizontal * 2;
        final cardWidth = available >= 680
            ? (available - 12) / 2
            : available.clamp(0.0, 420.0);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 40),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Semantics(
                              header: true,
                              child: SelectableText(
                                message.subject.isEmpty
                                    ? '(No subject)'
                                    : message.subject,
                                style: text.headlineSmall,
                              ),
                            ),
                            PillLabel(message.folder.label),
                          ],
                        ),
                      ),
                      if (showStar)
                        IconButton(
                          tooltip: message.isStarred ? 'Remove star' : 'Star',
                          onPressed: onToggleStar,
                          icon: Icon(
                            message.isStarred
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: message.isStarred
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SenderBlock(message: message),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 18),
                  SelectionArea(child: MessageBodyText(message.bodyText)),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 14),
                    // "Download all" sits at the end, or on its own line when
                    // the pane is narrow.
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${attachments.length} '
                                          '${attachments.length == 1 ? 'attachment' : 'attachments'}',
                                      style: text.titleSmall,
                                    ),
                                    TextSpan(
                                      text:
                                          '  (${totalBytes.toFileSizeLabel()})',
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text('Download all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final attachment in attachments)
                          AttachmentCard(
                            attachment: attachment,
                            width: cardWidth,
                            onDownload: onDownload,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => onReply(ReplyAction.reply),
                        icon: const Icon(Icons.reply_rounded),
                        label: const Text('Reply'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onReply(ReplyAction.replyAll),
                        icon: const Icon(Icons.reply_all_rounded),
                        label: const Text('Reply all'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onReply(ReplyAction.forward),
                        icon: const Icon(Icons.forward_rounded),
                        label: const Text('Forward'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SenderBlock extends StatefulWidget {
  const _SenderBlock({required this.message});

  final EmailMessage message;

  @override
  State<_SenderBlock> createState() => _SenderBlockState();
}

class _SenderBlockState extends State<_SenderBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final secondary = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final recipients = [
      ...message.to,
      ...message.cc,
    ].map((a) => a.label).join(', ');
    final date = Text(message.sentAt.toDetailLabel(context), style: secondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phones and narrow panes put the date under the recipients so the
        // sender's name keeps its width.
        LayoutBuilder(
          builder: (context, constraints) {
            final dateBeside = constraints.maxWidth >= 440;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SenderAvatar(name: message.from.label, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: message.from.label,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (message.from.displayName != null)
                              TextSpan(
                                text: '  <${message.from.address}>',
                                style: secondary,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                recipients.isEmpty
                                    ? 'To: (none)'
                                    : 'To: $recipients',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: secondary,
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                              semanticLabel: _expanded
                                  ? 'Hide details'
                                  : 'Show details',
                            ),
                          ],
                        ),
                      ),
                      if (!dateBeside) ...[const SizedBox(height: 2), date],
                    ],
                  ),
                ),
                if (dateBeside) ...[const SizedBox(width: 8), date],
              ],
            );
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _expanded
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailLine('From', [message.from]),
                      _DetailLine('To', message.to),
                      if (message.cc.isNotEmpty) _DetailLine('Cc', message.cc),
                      if (message.bcc.isNotEmpty)
                        _DetailLine('Bcc', message.bcc),
                      _DetailText(
                        'Date',
                        message.sentAt.toDetailLabel(context),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.addresses);

  final String label;
  final List<EmailAddress> addresses;

  @override
  Widget build(BuildContext context) {
    return _DetailText(
      label,
      addresses.isEmpty
          ? '(none)'
          : addresses
                .map(
                  (a) => a.displayName == null
                      ? a.address
                      : '${a.label} <${a.address}>',
                )
                .join(', '),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: text.bodySmall)),
        ],
      ),
    );
  }
}
