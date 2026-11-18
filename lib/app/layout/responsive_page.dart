import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/adaptive_scaffold.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/layout/pane_card.dart';

/// Page chrome for secondary pages (Settings, Search, Mailboxes, Admin).
///
/// * compact: deep-green app bar with a back button (or the drawer button).
/// * medium/expanded: a page title inside a rounded [PaneCard].
///
/// When [onBack] is set, the system back button (Android) calls it instead
/// of closing the app.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    final compact = WindowSizeClass.of(context) == WindowSizeClass.compact;

    final Widget page = compact
        ? Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: onBack != null
                  ? BackButton(onPressed: onBack)
                  : AdaptiveScaffold.drawerButtonOf(context),
              title: Text(title),
              actions: actions,
            ),
            body: body,
          )
        : Scaffold(
            backgroundColor: Colors.transparent,
            body: PaneCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(title: title, actions: actions),
                  Expanded(child: body),
                ],
              ),
            ),
          );

    if (onBack == null) return page;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: page,
    );
  }
}

/// Large page title with optional badge and actions (wide layouts).
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.badge,
    this.actions = const [],
    this.large = false,
  });

  final String title;
  final Widget? badge;
  final List<Widget> actions;

  /// iOS-style large title (compact inbox).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badge = this.badge;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, large ? 18 : 16, 8, large ? 10 : 8),
      child: Row(
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: large ? text.headlineMedium : text.headlineSmall,
              ),
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 10), badge],
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}
