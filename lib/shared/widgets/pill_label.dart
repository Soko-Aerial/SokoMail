import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

/// Small rounded label, e.g. "4 unread" or a folder name.
class PillLabel extends StatelessWidget {
  const PillLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final icon = this.icon;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: brand.accentSoft,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: brand.onAccentSoft),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: brand.onAccentSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How a [CountBadge] is coloured.
enum CountBadgeTone {
  /// Olive pill with white digits (mobile Inbox, bottom bar).
  filled,

  /// Neutral pill on light surfaces (drawer).
  muted,

  /// Translucent pill on the deep-green sidebar.
  onHeader,

  /// Lime pill for the selected item on the deep-green sidebar.
  onHeaderSelected,
}

/// Numeric badge used in navigation (unread counts).
class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
    this.tone = CountBadgeTone.filled,
    this.large = false,
  });

  final int count;
  final CountBadgeTone tone;

  /// Bigger variant next to page titles.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brandColors;
    final (background, foreground) = switch (tone) {
      CountBadgeTone.filled => (scheme.primary, scheme.onPrimary),
      CountBadgeTone.muted => (scheme.surfaceContainerHigh, scheme.onSurface),
      CountBadgeTone.onHeader => (brand.headerField, brand.onHeader),
      CountBadgeTone.onHeaderSelected => (
        brand.headerAccent,
        brand.onHeaderAccent,
      ),
    };
    final style =
        (large ? theme.textTheme.titleMedium : theme.textTheme.labelMedium)
            ?.copyWith(color: foreground, fontWeight: FontWeight.w700);

    return Semantics(
      label: '$count',
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minWidth: large ? 40 : 24),
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 7,
            vertical: large ? 3 : 2,
          ),
          decoration: ShapeDecoration(
            color: background,
            shape: const StadiumBorder(),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ),
    );
  }
}
