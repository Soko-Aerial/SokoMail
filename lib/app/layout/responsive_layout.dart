import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/app_breakpoints.dart';
import 'package:sokomail/app/layout/pane_card.dart';

/// Chooses a widget for the current [WindowSizeClass].
///
/// [medium] falls back to [compact]; [expanded] falls back to [medium].
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    final builder = switch (WindowSizeClass.of(context)) {
      WindowSizeClass.compact => compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
    };
    return builder(context);
  }
}

/// Signature for building the detail pane of a [ListDetailLayout].
///
/// [isSinglePane] is true when the detail fills the whole area (so it should
/// offer a back affordance) and false when it sits beside the list.
typedef DetailPaneBuilder =
    Widget Function(BuildContext context, bool isSinglePane);

/// List/detail layout used by the mail workspace.
///
/// Uses the space actually available to it (not the window size), so it
/// behaves correctly next to a sidebar:
/// * Two panes when at least [twoPaneMinWidth] wide.
/// * Otherwise one pane. The list stays mounted (offstage) while the detail
///   is shown, so its scroll position survives; the detail slides in.
class ListDetailLayout extends StatelessWidget {
  const ListDetailLayout({
    super.key,
    required this.list,
    required this.detailBuilder,
    required this.showDetail,
    this.framed = false,
    this.twoPaneMinWidth = 640,
    this.minListWidth = 320,
    this.maxListWidth = 460,
    this.paneGap = 16,
  });

  final Widget list;
  final DetailPaneBuilder detailBuilder;
  final bool showDetail;

  /// Puts each pane in a [PaneCard] (tablet and desktop).
  final bool framed;
  final double twoPaneMinWidth;
  final double minListWidth;
  final double maxListWidth;
  final double paneGap;

  @override
  Widget build(BuildContext context) {
    Widget frame(Widget child) => framed ? PaneCard(child: child) : child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < twoPaneMinWidth) {
          final detail = showDetail ? detailBuilder(context, true) : null;
          return frame(
            Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: showDetail,
                  child: TickerMode(enabled: !showDetail, child: list),
                ),
                if (detail != null) _SlideIn(key: detail.key, child: detail),
              ],
            ),
          );
        }

        final listWidth = math.min(
          maxListWidth,
          math.max(minListWidth, width * 0.36),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: listWidth, child: frame(list)),
            if (framed)
              SizedBox(width: paneGap)
            else
              const VerticalDivider(width: 1),
            Expanded(child: frame(detailBuilder(context, false))),
          ],
        );
      },
    );
  }
}

/// iOS-style entrance from the right; skipped when the platform requests
/// reduced motion.
class _SlideIn extends StatelessWidget {
  const _SlideIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, offset, child) => FractionalTranslation(
        translation: Offset(offset * 0.3, 0),
        child: Opacity(opacity: 1 - offset * 0.5, child: child),
      ),
    );
  }
}
