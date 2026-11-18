import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

/// Miniature light / dark / system previews drawn with the real tokens.
/// Tapping a preview selects that theme.
class ThemePreview extends StatelessWidget {
  const ThemePreview({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _MiniPhone(
              mode: mode,
              selected: mode == selected,
              onTap: () => onSelected(mode),
            ),
          ),
      ],
    );
  }
}

class _MiniPhone extends StatelessWidget {
  const _MiniPhone({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme preview',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 66,
            height: 112,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: mode == ThemeMode.system
                  ? const Row(
                      children: [
                        Expanded(child: _Screen(dark: false, clipRight: true)),
                        Expanded(child: _Screen(dark: true, clipLeft: true)),
                      ],
                    )
                  : _Screen(dark: mode == ThemeMode.dark),
            ),
          ),
        ),
      ),
    );
  }
}

class _Screen extends StatelessWidget {
  const _Screen({
    required this.dark,
    this.clipLeft = false,
    this.clipRight = false,
  });

  final bool dark;
  final bool clipLeft;
  final bool clipRight;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final header = dark ? AppColors.darkDeepGreen : AppColors.deepGreen;
    final line = dark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceContainerHighest;
    final dot = dark ? AppColors.darkOlive : AppColors.olive;

    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 18, color: header),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                clipLeft ? 0 : 5,
                7,
                clipRight ? 0 : 5,
                0,
              ),
              child: Row(
                children: [
                  if (!clipLeft) ...[
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
