import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/adaptive_scaffold.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/layout/shell/shell_navigation.dart';
import 'package:sokomail/app/layout/shell/shell_top_bar.dart';
import 'package:sokomail/app/layout/shell/sidebar_controller.dart';
import 'package:sokomail/app/router/route_names.dart';
import 'package:sokomail/app/router/route_paths.dart';
import 'package:sokomail/features/auth/domain/entities/auth_state.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';
import 'package:sokomail/features/auth/presentation/widgets/development_session_banner.dart';
import 'package:sokomail/features/inbox/presentation/providers/folder_messages_provider.dart';
import 'package:sokomail/features/mailboxes/domain/entities/mailbox.dart';
import 'package:sokomail/features/mailboxes/presentation/providers/mailbox_providers.dart';
import 'package:sokomail/shared/extensions/mail_folder_presentation.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/widgets/placeholder_notice.dart';

/// The signed-in application shell: responsive navigation around every page
/// except sign-in and compose.
///
/// Composition root: connects [AdaptiveScaffold] (layout slots) with
/// SokoMail's destinations, badge counts, mailboxes, account menu and the
/// router.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  /// Drawer entry that opens a placeholder instead of a route.
  static const _helpEntry = '_help';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final routeName = state.topRoute?.name;
    final sizeClass = WindowSizeClass.of(context);

    final collapsed = sizeClass == WindowSizeClass.expanded
        ? ref.watch(sidebarCollapsedProvider)
        : !ref.watch(tabletSidebarExpandedProvider);

    // The mailbox in the URL wins; other pages carry it as a query parameter
    // or fall back to the user's primary mailbox.
    final mailboxId =
        state.pathParameters[RouteParams.mailboxId] ??
        state.uri.queryParameters[RouteQuery.mailboxId] ??
        user?.primaryMailboxId;
    Map<MailFolder, int> countsFor(String id) =>
        ref.watch(folderBadgeCountsProvider(id)).value ??
        const <MailFolder, int>{};
    final counts = mailboxId == null
        ? const <MailFolder, int>{}
        : countsFor(mailboxId);

    final mailboxes = ref.watch(accessibleMailboxesProvider).value ?? const [];
    final mailboxEntries = [
      for (final mailbox in mailboxes)
        ShellMailboxEntry(
          id: mailbox.id,
          label: mailbox.kind == MailboxKind.personal
              ? 'My mailbox'
              : mailbox.displayName,
          unread: countsFor(mailbox.id)[MailFolder.inbox] ?? 0,
          isShared: mailbox.kind == MailboxKind.shared,
          isCurrent: mailbox.id == mailboxId,
        ),
    ];

    final folders = [
      if (mailboxId != null)
        for (final folder in MailFolder.values)
          ShellDestination(
            routeName: RouteNames.forFolder(folder),
            icon: folder.icon,
            selectedIcon: folder.selectedIcon,
            label: folder.label,
            badge: counts[folder] ?? 0,
          ),
    ];
    const settings = ShellDestination(
      routeName: RouteNames.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    );
    const admin = ShellDestination(
      routeName: RouteNames.admin,
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield_rounded,
      label: 'Admin Console',
    );
    final isAdmin = user?.isAdmin ?? false;

    // A message page highlights the folder it was opened from.
    final selectedRouteName = routeName == RouteNames.message
        ? RouteNames.forFolder(
            MailFolder.fromPathSegment(
                  state.uri.queryParameters[RouteQuery.folder],
                ) ??
                MailFolder.inbox,
          )
        : routeName;
    final onFolderPage = RouteNames.folderOf(routeName) != null;
    final mailboxQuery = {RouteQuery.mailboxId: ?mailboxId};

    void showHelp() => unawaited(
      showPlaceholderNotice(
        context,
        title: 'Help & Support',
        message:
            'Help articles and support contacts will be added in a later '
            'release. For now, contact your IT administrator.',
      ),
    );

    void go(ShellDestination destination) {
      if (destination.routeName == _helpEntry) {
        showHelp();
        return;
      }
      final isFolder = RouteNames.folderOf(destination.routeName) != null;
      if (isFolder && mailboxId != null) {
        context.goNamed(
          destination.routeName,
          pathParameters: {RouteParams.mailboxId: mailboxId},
        );
      } else {
        context.goNamed(destination.routeName, queryParameters: mailboxQuery);
      }
    }

    void openMailbox(String id) => context.goNamed(
      RouteNames.mailInbox,
      pathParameters: {RouteParams.mailboxId: id},
    );

    void compose() =>
        context.pushNamed(RouteNames.compose, queryParameters: mailboxQuery);

    void search(String query) => context.goNamed(
      RouteNames.search,
      queryParameters: {
        ...mailboxQuery,
        RouteQuery.query: ?(query.isEmpty ? null : query),
      },
    );

    void notifications() => unawaited(
      showPlaceholderNotice(
        context,
        title: 'Notifications',
        message:
            'Push and in-app notifications arrive in a later release. New '
            'mail will then be announced here.',
      ),
    );

    void account(AccountMenuAction action) {
      switch (action) {
        case AccountMenuAction.mailboxes:
          context.goNamed(RouteNames.mailboxes, queryParameters: mailboxQuery);
        case AccountMenuAction.settings:
          context.goNamed(RouteNames.settings, queryParameters: mailboxQuery);
        case AccountMenuAction.signOut:
          ref.read(authControllerProvider.notifier).signOut();
      }
    }

    void toggleSidebar() {
      if (sizeClass == WindowSizeClass.expanded) {
        unawaited(ref.read(sidebarCollapsedProvider.notifier).toggle());
      } else {
        ref.read(tabletSidebarExpandedProvider.notifier).toggle();
      }
    }

    final isDevelopmentSession = switch (auth) {
      Authenticated(:final isDevelopmentSession) => isDevelopmentSession,
      Unauthenticated() => false,
    };

    Widget accountMenu({bool showName = false, bool detailed = false}) =>
        user == null
        ? const SizedBox.shrink()
        : AccountMenuButton(
            user: user,
            isDevelopmentSession: isDevelopmentSession,
            onSelected: account,
            showName: showName,
            detailed: detailed,
          );

    final scaffold = AdaptiveScaffold(
      sidebarCollapsed: collapsed,
      drawer: ShellDrawer(
        sections: [
          folders,
          const [
            ShellDestination(
              routeName: RouteNames.mailboxes,
              icon: Icons.layers_outlined,
              selectedIcon: Icons.layers_rounded,
              label: 'Mailboxes',
            ),
            ShellDestination(
              routeName: RouteNames.search,
              icon: Icons.search_rounded,
              selectedIcon: Icons.search_rounded,
              label: 'Search',
            ),
          ],
          [
            settings,
            if (isAdmin) admin,
            const ShellDestination(
              routeName: _helpEntry,
              icon: Icons.help_outline_rounded,
              selectedIcon: Icons.help_rounded,
              label: 'Help & Support',
            ),
          ],
        ],
        selectedRouteName: selectedRouteName,
        onSelected: go,
        accountHeader: accountMenu(detailed: true),
      ),
      sidebarBuilder: (context, width) => ShellSidebar(
        width: width,
        folders: folders,
        tools: [settings, if (isAdmin) admin],
        mailboxes: mailboxEntries,
        selectedRouteName: selectedRouteName,
        manageMailboxesSelected: routeName == RouteNames.mailboxes,
        onSelected: go,
        onMailboxSelected: openMailbox,
        onManageMailboxes: () => context.goNamed(
          RouteNames.mailboxes,
          queryParameters: mailboxQuery,
        ),
        onCompose: compose,
      ),
      topBar: ShellTopBar(
        sidebarCollapsed: collapsed,
        onToggleSidebar: toggleSidebar,
        onSearch: search,
        onNotifications: notifications,
        onHelp: showHelp,
        accountMenuBuilder: (showName) => accountMenu(showName: showName),
      ),
      compactBottomBar: onFolderPage
          ? ShellBottomBar(
              destinations: [
                for (final destination in folders)
                  if (destination.routeName != RouteNames.mailStarred)
                    destination,
              ],
              selectedRouteName: selectedRouteName,
              onSelected: go,
            )
          : null,
      floatingActionButton: onFolderPage
          ? FloatingActionButton(
              heroTag: null,
              tooltip: 'Compose',
              onPressed: compose,
              child: const Icon(Icons.edit_square, size: 26),
            )
          : null,
      body: child,
    );

    if (!isDevelopmentSession) return scaffold;

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: scaffold,
          ),
        ),
        const DevelopmentSessionBanner(),
      ],
    );
  }
}
