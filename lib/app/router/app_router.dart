import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/app_shell.dart';
import 'package:sokomail/app/layout/mail_workspace.dart';
import 'package:sokomail/app/router/not_found_screen.dart';
import 'package:sokomail/app/router/route_guard.dart';
import 'package:sokomail/app/router/route_names.dart';
import 'package:sokomail/app/router/route_paths.dart';
import 'package:sokomail/features/admin/presentation/screens/admin_screen.dart';
import 'package:sokomail/features/auth/domain/entities/auth_state.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';
import 'package:sokomail/features/auth/presentation/screens/login_screen.dart';
import 'package:sokomail/features/compose/presentation/providers/compose_controller.dart';
import 'package:sokomail/features/compose/presentation/screens/compose_screen.dart';
import 'package:sokomail/features/mailboxes/presentation/screens/mailboxes_screen.dart';
import 'package:sokomail/features/search/presentation/screens/search_screen.dart';
import 'package:sokomail/features/settings/presentation/screens/settings_screen.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// The application's single [GoRouter].
///
/// The router is created once. Authentication changes do not rebuild it;
/// they notify [GoRouter.refreshListenable], which re-runs the redirect
/// guard so navigation state is preserved.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref
    ..listen<AuthState>(
      authControllerProvider,
      (_, next) => authState.value = next,
    )
    ..onDispose(authState.dispose);

  String? primaryMailboxId() => authState.value.user?.primaryMailboxId;

  final router = GoRouter(
    initialLocation: RoutePaths.root,
    refreshListenable: authState,
    redirect: (context, state) => RouteGuard.redirect(
      auth: authState.value,
      location: state.uri,
      access: RouteAccess.fromMetadata(state.metadata),
    ),
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.path),
    routes: _buildRoutes(primaryMailboxId),
  );
  ref.onDispose(router.dispose);
  return router;
});

// Shared by every mail page so moving between a folder and a message updates
// the existing page instead of replacing it (keeps list scroll position).
const _mailWorkspacePageKey = ValueKey<String>('mail-workspace');

/// Mailbox context carried by secondary pages, falling back to the user's
/// primary mailbox.
String? _mailboxFrom(GoRouterState state, String? Function() fallback) =>
    state.uri.queryParameters[RouteQuery.mailboxId] ?? fallback();

/// Returns from a secondary page to the inbox of the mailbox in context.
void _goToInbox(BuildContext context, GoRouterState state) {
  final mailboxId = state.uri.queryParameters[RouteQuery.mailboxId];
  if (mailboxId == null) {
    context.go(RoutePaths.root); // The guard resolves the user's inbox.
  } else {
    context.goNamed(
      RouteNames.mailInbox,
      pathParameters: {RouteParams.mailboxId: mailboxId},
    );
  }
}

List<RouteBase> _buildRoutes(String? Function() primaryMailboxId) => [
  // `/` is resolved by the guard (login or the user's inbox). This route only
  // makes `/` a known location.
  GoRoute(path: RoutePaths.root, redirect: (_, _) => RoutePaths.login),
  GoRoute(
    name: RouteNames.login,
    path: RoutePaths.login,
    metadata: RouteAccess.public.metadata,
    builder: (context, state) => const LoginScreen(),
  ),
  // `/mail/:mailboxId` on its own opens the inbox.
  GoRoute(
    path: RoutePaths.mailbox,
    redirect: (context, state) => RoutePaths.folderLocation(
      state.pathParameters[RouteParams.mailboxId]!,
      MailFolder.inbox,
    ),
  ),
  // Compose is a transient task pushed above the shell; `/compose` also
  // works as a direct link.
  GoRoute(
    name: RouteNames.compose,
    path: RoutePaths.compose,
    builder: (context, state) {
      final query = state.uri.queryParameters;
      return ComposeScreen(
        request: (
          mode: ComposeMode.parse(query[RouteQuery.mode]),
          mailboxId: _mailboxFrom(state, primaryMailboxId),
          messageId: query[RouteQuery.messageId],
        ),
        onClose: () =>
            context.canPop() ? context.pop() : context.go(RoutePaths.root),
      );
    },
  ),
  ShellRoute(
    builder: (context, state, child) => AppShell(state: state, child: child),
    routes: [
      for (final folder in MailFolder.values)
        GoRoute(
          name: RouteNames.forFolder(folder),
          path: RoutePaths.folderTemplate(folder),
          pageBuilder: (context, state) => NoTransitionPage(
            key: _mailWorkspacePageKey,
            child: MailWorkspace(
              mailboxId: state.pathParameters[RouteParams.mailboxId]!,
              folder: folder,
            ),
          ),
        ),
      GoRoute(
        name: RouteNames.message,
        path: RoutePaths.message,
        pageBuilder: (context, state) => NoTransitionPage(
          key: _mailWorkspacePageKey,
          child: MailWorkspace(
            mailboxId: state.pathParameters[RouteParams.mailboxId]!,
            folder:
                MailFolder.fromPathSegment(
                  state.uri.queryParameters[RouteQuery.folder],
                ) ??
                MailFolder.inbox,
            selectedMessageId: state.pathParameters[RouteParams.messageId],
          ),
        ),
      ),
      GoRoute(
        name: RouteNames.search,
        path: RoutePaths.search,
        pageBuilder: (context, state) {
          final mailboxId = _mailboxFrom(state, primaryMailboxId) ?? '';
          return NoTransitionPage(
            key: state.pageKey,
            child: SearchScreen(
              mailboxId: mailboxId,
              initialQuery: state.uri.queryParameters[RouteQuery.query] ?? '',
              onBack: () => _goToInbox(context, state),
              onOpenMessage: (message) => context.goNamed(
                RouteNames.message,
                pathParameters: {
                  RouteParams.mailboxId: message.mailboxId,
                  RouteParams.messageId: message.id,
                },
                queryParameters: {
                  RouteQuery.folder: message.folder.pathSegment,
                },
              ),
            ),
          );
        },
      ),
      GoRoute(
        name: RouteNames.mailboxes,
        path: RoutePaths.mailboxes,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: MailboxesScreen(
            selectedMailboxId: _mailboxFrom(state, primaryMailboxId),
            onBack: () => _goToInbox(context, state),
            onMailboxSelected: (id) => context.goNamed(
              RouteNames.mailInbox,
              pathParameters: {RouteParams.mailboxId: id},
            ),
          ),
        ),
      ),
      GoRoute(
        name: RouteNames.settings,
        path: RoutePaths.settings,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: SettingsScreen(onBack: () => _goToInbox(context, state)),
        ),
      ),
      GoRoute(
        name: RouteNames.admin,
        path: RoutePaths.admin,
        // Protected: the guard redirects users without the admin role.
        metadata: RouteAccess.admin.metadata,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: AdminScreen(onBack: () => _goToInbox(context, state)),
        ),
      ),
    ],
  ),
];
