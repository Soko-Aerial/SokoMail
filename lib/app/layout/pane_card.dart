import 'package:material_ui/material_ui.dart';

/// Rounded surface for content panes on tablet and desktop (message list,
/// reading pane, settings), floating on the background with a restrained
/// shadow.
class PaneCard extends StatelessWidget {
  const PaneCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(20));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: isDark
            ? null
            : Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D1C281C),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(color: theme.colorScheme.surface, child: child),
      ),
    );
  }
}
