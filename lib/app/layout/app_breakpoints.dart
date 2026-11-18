import 'package:material_ui/material_ui.dart';

/// Provisional width breakpoints (logical pixels).
///
/// * compact: width < 600 (phones)
/// * medium: 600-1023 (tablets, narrow browser windows)
/// * expanded: width >= 1024 (desktop browsers, large tablets in landscape)
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 1024;
}

/// Window size class derived from the available width, never from the
/// operating system.
enum WindowSizeClass {
  compact,
  medium,
  expanded;

  static WindowSizeClass fromWidth(double width) {
    if (width >= AppBreakpoints.expanded) return WindowSizeClass.expanded;
    if (width >= AppBreakpoints.medium) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  /// The size class of the whole window. Rebuilds only when the size changes.
  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}
