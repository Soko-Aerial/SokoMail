import 'package:material_ui/material_ui.dart';

/// Message timestamps in the style of the design: "09:47", "Yesterday",
/// "Mon", "Nov 12".
///
/// Weekday names are English until localisation is added (Settings >
/// Language is a placeholder).
extension DateTimeDisplay on DateTime {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Compact form for message lists.
  String toListLabel(BuildContext context, {DateTime? now}) {
    final local = toLocal();
    final today = _dateOnly(now ?? DateTime.now());
    final day = _dateOnly(local);
    final daysAgo = today.difference(day).inDays;

    if (daysAgo <= 0) return _time(context, local);
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return _weekdays[local.weekday - 1];
    return MaterialLocalizations.of(context).formatShortMonthDay(local);
  }

  /// Longer form for the reading pane: "Today, 09:47".
  String toDetailLabel(BuildContext context, {DateTime? now}) {
    final local = toLocal();
    final today = _dateOnly(now ?? DateTime.now());
    final daysAgo = today.difference(_dateOnly(local)).inDays;
    final time = _time(context, local);

    if (daysAgo <= 0) return 'Today, $time';
    if (daysAgo == 1) return 'Yesterday, $time';
    return '${MaterialLocalizations.of(context).formatMediumDate(local)}, $time';
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _time(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(value),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
}
