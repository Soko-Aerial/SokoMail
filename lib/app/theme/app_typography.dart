import 'package:material_ui/material_ui.dart';

/// SokoMail type scale: Material 3 sizes with iOS-style weight and tracking
/// (bold large titles, slightly tighter headings, generous body line height).
///
/// The platform default font is used (San Francisco on iOS, Roboto on
/// Android and the web) until a brand typeface is chosen. Add the font files
/// to `assets/fonts/` and set `fontFamily` here when it is.
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final typography = Typography.material2021(colorScheme: colorScheme);
    // englishLike carries sizes/weights; black/white carry colours and fonts.
    final base = typography.englishLike.merge(
      colorScheme.brightness == Brightness.dark
          ? typography.white
          : typography.black,
    );

    return base
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );
  }
}
