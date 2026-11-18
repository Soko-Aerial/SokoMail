import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

enum SokoMailLogoSize { small, medium, large }

/// Typographic SokoMail wordmark.
///
/// PLACEHOLDER: SokoAerial Robotics' official logo is not in the project.
/// When it is supplied, add the files to `assets/images/` (declare the
/// folder in `pubspec.yaml`) and render them here; every screen uses this
/// widget, so no other code changes are needed.
class SokoMailLogo extends StatelessWidget {
  const SokoMailLogo({
    super.key,
    this.onDark = false,
    this.size = SokoMailLogoSize.medium,
    this.showTagline = true,
  });

  /// Use on deep-green headers and the sidebar.
  final bool onDark;
  final SokoMailLogoSize size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brandColors;
    final isDarkTheme = theme.brightness == Brightness.dark;

    final sokoColor = onDark
        ? brand.onHeader
        : (isDarkTheme ? theme.colorScheme.onSurface : brand.header);
    final mailColor = onDark ? AppColors.darkOlive : theme.colorScheme.primary;
    final taglineColor = onDark
        ? brand.onHeaderMuted
        : theme.colorScheme.onSurfaceVariant;

    final (wordSize, taglineSize) = switch (size) {
      SokoMailLogoSize.small => (20.0, 8.5),
      SokoMailLogoSize.medium => (26.0, 9.5),
      SokoMailLogoSize.large => (38.0, 12.0),
    };

    return Semantics(
      label: 'SokoMail, SokoAerial Robotics',
      container: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Soko',
                    style: TextStyle(color: sokoColor),
                  ),
                  TextSpan(
                    text: 'Mail',
                    style: TextStyle(color: mailColor),
                  ),
                ],
              ),
              maxLines: 1,
              style: TextStyle(
                fontSize: wordSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                height: 1.05,
              ),
            ),
            if (showTagline)
              Padding(
                padding: const EdgeInsets.only(left: 1, top: 1),
                child: Text(
                  'SOKOAERIAL ROBOTICS',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: taglineSize,
                    color: taglineColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
