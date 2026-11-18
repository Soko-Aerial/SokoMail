import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/adaptive_scaffold.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/layout/brand_app_bar.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/features/inbox/presentation/providers/folder_messages_provider.dart';
import 'package:sokomail/shared/extensions/mail_folder_presentation.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';
import 'package:sokomail/shared/widgets/app_button.dart';
import 'package:sokomail/shared/widgets/app_empty_state.dart';
import 'package:sokomail/shared/widgets/app_error_view.dart';
import 'package:sokomail/shared/widgets/app_loading_indicator.dart';
import 'package:sokomail/shared/widgets/app_search_field.dart';
import 'package:sokomail/shared/widgets/menu_item_label.dart';
import 'package:sokomail/shared/widgets/message_list_tile.dart';
import 'package:sokomail/shared/widgets/pill_label.dart';

/// Message list for one folder (Inbox, Starred, Sent, Drafts, Spam, Trash).
///
/// Phones: a rounded sheet over the deep-green header with a large title,
/// unread count, search field and tonal filter/sort buttons. Wider layouts:
/// a compact header with "N unread • M total" inside the list card.
///
/// Navigation is delegated to callbacks so this feature does not depend on
/// the router.
class MailFolderScreen extends ConsumerWidget {
  const MailFolderScreen({
    super.key,
    required this.mailboxId,
    required this.folder,
    required this.onMessageSelected,
    required this.onOpenSearch,
    this.onOpenSettings,
    this.selectedMessageId,
  });

  final String mailboxId;
  final MailFolder folder;
  final String? selectedMessageId;
  final ValueChanged<MessageSummary> onMessageSelected;
  final VoidCallback onOpenSearch;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderRef = (mailboxId: mailboxId, folder: folder);
    final messages = ref.watch(folderMessagesProvider(folderRef));
    final view = ref.watch(folderViewControllerProvider(folderRef));
    final viewModel = ref.read(
      folderViewControllerProvider(folderRef).notifier,
    );
    final compact = WindowSizeClass.of(context) == WindowSizeClass.compact;
    final theme = Theme.of(context);

    final all = messages.value ?? const <MessageSummary>[];
    final unread = all.where((m) => !m.isRead).length;

    Future<void> markAllRead() async {
      final changed = await viewModel.markAllRead(all);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            changed == 0
                ? 'Everything here is already read.'
                : 'Marked $changed as read.',
          ),
        ),
      );
    }

    Future<void> refresh() =>
        ref.refresh(folderMessagesProvider(folderRef).future);

    final menus = [
      _FilterMenu(
        selected: view.filter,
        tonal: compact,
        onSelected: viewModel.setFilter,
      ),
      _SortMenu(
        selected: view.sort,
        tonal: compact,
        onSelected: viewModel.setSort,
      ),
      if (!compact)
        _MoreMenu(
          onMarkAllRead: markAllRead,
          onRefresh: () => unawaited(refresh()),
        ),
    ];

    final header = compact
        ? Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 14, 8),
            child: Row(
              children: [
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      folder.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 10),
                  CountBadge(count: unread, large: true),
                ],
                const Spacer(),
                for (final menu in menus) ...[menu, const SizedBox(width: 6)],
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          folder.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '$unread unread • ${all.length} total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ...menus,
              ],
            ),
          );

    final list = messages.when(
      skipLoadingOnReload: true,
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => AppErrorView(
        title: 'Could not load ${folder.label}',
        error: error,
        onRetry: () => ref.invalidate(folderMessagesProvider(folderRef)),
      ),
      data: (all) {
        if (all.isEmpty) {
          return AppEmptyState(
            icon: folder.icon,
            title: '${folder.label} is empty',
            message: folder.emptyMessage,
          );
        }
        final visible = view.visible(all);
        if (visible.isEmpty) {
          return AppEmptyState(
            icon: Icons.filter_list_off_rounded,
            title: 'No messages match this filter',
            message: 'Filter: ${view.filter.label}',
            action: AppButton(
              label: 'Show all messages',
              variant: AppButtonVariant.secondary,
              onPressed: () => viewModel.setFilter(MessageFilter.all),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            padding: EdgeInsets.only(top: 4, bottom: compact ? 104 : 16),
            itemCount: visible.length,
            separatorBuilder: (_, _) =>
                Divider(indent: compact ? 94 : 82, endIndent: 16),
            itemBuilder: (context, index) {
              final message = visible[index];
              return MessageListTile(
                key: ValueKey(message.id),
                message: message,
                selected: message.id == selectedMessageId,
                comfortable: compact,
                showRecipients: folder.showsRecipients,
                onTap: () => onMessageSelected(message),
                onToggleStar: () => viewModel.toggleStar(message),
              );
            },
          ),
        );
      },
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppSearchField(readOnly: true, onTap: onOpenSearch),
          ),
        if (view.filter != MessageFilter.all)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text('Showing: ${view.filter.label}'),
                onDeleted: () => viewModel.setFilter(MessageFilter.all),
                deleteButtonTooltipMessage: 'Clear filter',
              ),
            ),
          ),
        Expanded(child: list),
      ],
    );

    if (!compact) {
      return Scaffold(backgroundColor: Colors.transparent, body: content);
    }

    final onOpenSettings = this.onOpenSettings;
    return Scaffold(
      backgroundColor: context.brandColors.header,
      appBar: BrandAppBar(
        leading: AdaptiveScaffold.drawerButtonOf(context),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: onOpenSearch,
          ),
          PopupMenuButton<_HeaderAction>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => switch (action) {
              _HeaderAction.markAllRead => unawaited(markAllRead()),
              _HeaderAction.settings => onOpenSettings?.call(),
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _HeaderAction.markAllRead,
                child: MenuItemLabel(
                  Icons.mark_email_read_outlined,
                  'Mark all as read',
                ),
              ),
              if (onOpenSettings != null)
                const PopupMenuItem(
                  value: _HeaderAction.settings,
                  child: MenuItemLabel(Icons.settings_outlined, 'Settings'),
                ),
            ],
          ),
        ],
      ),
      body: _Sheet(child: content),
    );
  }
}

enum _HeaderAction { markAllRead, settings }

enum _MoreAction { markAllRead, refresh }

/// Rounded-top content sheet that overlaps the green header on phones.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}

ButtonStyle _menuButtonStyle(BuildContext context, {required bool tonal}) =>
    IconButton.styleFrom(
      backgroundColor: tonal ? context.brandColors.accentSoft : null,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.selected,
    required this.tonal,
    required this.onSelected,
  });

  final MessageFilter selected;
  final bool tonal;
  final ValueChanged<MessageFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final active = selected != MessageFilter.all;
    // The checked item marks the active filter (no `initialValue`: its
    // highlight would hide the checked tile's ink).
    return PopupMenuButton<MessageFilter>(
      tooltip: 'Filter messages',
      onSelected: onSelected,
      style: _menuButtonStyle(context, tonal: tonal),
      icon: Icon(
        Icons.filter_alt_outlined,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      itemBuilder: (context) => [
        for (final option in MessageFilter.values)
          CheckedPopupMenuItem<MessageFilter>(
            value: option,
            checked: option == selected,
            child: Text(option.label),
          ),
      ],
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.selected,
    required this.tonal,
    required this.onSelected,
  });

  final MessageSort selected;
  final bool tonal;
  final ValueChanged<MessageSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MessageSort>(
      tooltip: 'Sort messages',
      onSelected: onSelected,
      style: _menuButtonStyle(context, tonal: tonal),
      icon: const Icon(Icons.sort_rounded),
      itemBuilder: (context) => [
        for (final option in MessageSort.values)
          CheckedPopupMenuItem<MessageSort>(
            value: option,
            checked: option == selected,
            child: Text(option.label),
          ),
      ],
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onMarkAllRead, required this.onRefresh});

  final VoidCallback onMarkAllRead;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MoreAction>(
      tooltip: 'More options',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) => switch (action) {
        _MoreAction.markAllRead => onMarkAllRead(),
        _MoreAction.refresh => onRefresh(),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _MoreAction.markAllRead,
          child: MenuItemLabel(
            Icons.mark_email_read_outlined,
            'Mark all as read',
          ),
        ),
        PopupMenuItem(
          value: _MoreAction.refresh,
          child: MenuItemLabel(Icons.refresh_rounded, 'Refresh'),
        ),
      ],
    );
  }
}
