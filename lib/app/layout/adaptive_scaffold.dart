import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/theme/app_colors.dart';

/// Responsive application frame with named slots. It decides *where*
/// navigation goes; `AppShell` decides *what* it contains.
///
/// | Size class | Frame |
/// | --- | --- |
/// | compact | Pages own their app bars; modal [drawer]; [compactBottomBar]; [floatingActionButton] |
/// | medium, expanded | Deep-green L-shaped frame: collapsible sidebar ([sidebarBuilder]) and [topBar] around a background area with a rounded top-left corner |
///
/// Compact pages put [drawerButtonOf] in their app bar's `leading` slot.
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.drawer,
    required this.sidebarBuilder,
    required this.topBar,
    this.compactBottomBar,
    this.floatingActionButton,
    this.sidebarCollapsed = false,
  });

  final Widget body;

  /// Modal navigation for phones.
  final Widget drawer;

  /// Sidebar for tablets and desktop. Receives the width it is laid out at,
  /// which animates when the sidebar collapses.
  final Widget Function(BuildContext context, double width) sidebarBuilder;

  /// Top bar for tablets and desktop.
  final Widget topBar;
  final Widget? compactBottomBar;

  /// Phones only; wider layouts have Compose in the sidebar.
  final Widget? floatingActionButton;
  final bool sidebarCollapsed;

  static const double sidebarWidth = 272;
  static const double collapsedSidebarWidth = 84;

  /// Returns a menu button that opens the drawer on phones, or `null` when
  /// none is needed (wider layouts, or a page that can pop and should show
  /// a back button instead).
  static Widget? drawerButtonOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_AdaptiveScaffoldScope>();
    if (scope == null || scope.sizeClass != WindowSizeClass.compact) {
      return null;
    }
    if (Navigator.of(context).canPop()) return null;
    return DrawerButton(onPressed: scope.openDrawer);
  }

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);
    final body = _AdaptiveScaffoldScope(
      sizeClass: sizeClass,
      openDrawer: _openDrawer,
      child: widget.body,
    );

    if (sizeClass == WindowSizeClass.compact) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: widget.drawer,
        body: body,
        bottomNavigationBar: widget.compactBottomBar,
        floatingActionButton: widget.floatingActionButton,
      );
    }

    final brand = context.brandColors;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: brand.header,
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              key: const ValueKey('shell-sidebar'),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: widget.sidebarCollapsed
                  ? AdaptiveScaffold.collapsedSidebarWidth
                  : AdaptiveScaffold.sidebarWidth,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    widget.sidebarBuilder(context, constraints.maxWidth),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.topBar,
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                      ),
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: SafeArea(
                          top: false,
                          left: false,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: body,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveScaffoldScope extends InheritedWidget {
  const _AdaptiveScaffoldScope({
    required this.sizeClass,
    required this.openDrawer,
    required super.child,
  });

  final WindowSizeClass sizeClass;
  final VoidCallback openDrawer;

  @override
  bool updateShouldNotify(_AdaptiveScaffoldScope oldWidget) =>
      sizeClass != oldWidget.sizeClass;
}
