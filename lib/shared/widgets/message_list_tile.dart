import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/shared/extensions/date_time_display.dart';
import 'package:sokomail/shared/models/message_summary.dart';
import 'package:sokomail/shared/widgets/pill_label.dart';
import 'package:sokomail/shared/widgets/sender_avatar.dart';

/// One message row: unread dot, avatar, sender and time, subject, preview,
/// attachment indicator and star toggle. The selected row is tinted soft
/// olive with an olive accent bar.
class MessageListTile extends StatelessWidget {
  const MessageListTile({
    super.key,
    required this.message,
    required this.selected,
    required this.onTap,
    this.onToggleStar,
    this.comfortable = false,
    this.showRecipients = false,
    this.folderLabel,
  });

  final MessageSummary message;
  final bool selected;
  final VoidCallback onTap;

  /// `null` shows the star state without making it interactive.
  final VoidCallback? onToggleStar;

  /// Larger avatar and text for phones.
  final bool comfortable;

  /// Show "To: ..." instead of the sender (Sent and Drafts).
  final bool showRecipients;

  /// Optional folder name, used in search results.
  final String? folderLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final brand = context.brandColors;
    final unread = !message.isRead;
    final folderLabel = this.folderLabel;

    final recipients = message.to.map((a) => a.label).join(', ');
    final who = showRecipients
        ? (recipients.isEmpty ? 'No recipients' : 'To: $recipients')
        : message.from.label;
    final avatarName = showRecipients
        ? (message.to.firstOrNull?.label ?? '?')
        : message.from.label;
    final subject = message.subject.isEmpty ? '(No subject)' : message.subject;
    final avatarSize = comfortable ? 52.0 : 44.0;

    final nameStyle = (comfortable ? text.titleMedium : text.titleSmall)
        ?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w600);
    final subjectStyle = (comfortable ? text.bodyLarge : text.bodyMedium)
        ?.copyWith(
          color: scheme.onSurface,
          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
          height: 1.3,
        );
    final previewStyle = (comfortable ? text.bodyMedium : text.bodySmall)
        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Semantics(
        container: true,
        selected: selected,
        label: [
          if (unread) 'Unread',
          if (message.isStarred) 'Starred',
          if (message.hasAttachments) 'Has attachments',
        ].join(', '),
        child: Material(
          color: selected ? brand.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    comfortable ? 12 : 10,
                    4,
                    comfortable ? 8 : 6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 18,
                        height: avatarSize,
                        child: unread
                            ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: brand.unreadIndicator,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      SenderAvatar(name: avatarName, size: avatarSize),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    who,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: nameStyle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    message.sentAt.toListLabel(context),
                                    style: text.labelMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: unread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subjectStyle,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    message.preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: previewStyle,
                                  ),
                                ),
                                if (message.hasAttachments)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      Icons.attach_file_rounded,
                                      size: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                _StarButton(
                                  starred: message.isStarred,
                                  onPressed: onToggleStar,
                                ),
                              ],
                            ),
                            if (folderLabel != null) ...[
                              const SizedBox(height: 4),
                              PillLabel(folderLabel),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    left: 0,
                    top: 10,
                    bottom: 10,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({required this.starred, required this.onPressed});

  final bool starred;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      starred ? Icons.star_rounded : Icons.star_outline_rounded,
      size: 22,
      color: starred ? scheme.primary : scheme.onSurfaceVariant,
    );
    final onPressed = this.onPressed;
    if (onPressed == null) {
      return Padding(padding: const EdgeInsets.all(9), child: icon);
    }
    return IconButton(
      tooltip: starred ? 'Remove star' : 'Star',
      onPressed: onPressed,
      icon: icon,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
    );
  }
}
