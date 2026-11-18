import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/app/theme/app_typography.dart';

/// SokoMail's single design system for Android, iOS and the web.
///
/// One iOS-inspired look on every platform: flat surfaces, rounded corners,
/// pill buttons, deep-green headers, Cupertino page transitions and
/// bouncing scroll physics (see [AppScrollBehavior]).
abstract final class AppTheme {
  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 20;

  static final ThemeData light = _build(
    _lightScheme,
    AppColors.lightBackground,
    AppBrandColors.light,
    AppStatusColors.light,
  );

  static final ThemeData dark = _build(
    _darkScheme,
    AppColors.darkBackground,
    AppBrandColors.dark,
    AppStatusColors.dark,
  );

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.olive,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.olive,
        onPrimary: Colors.white,
        primaryContainer: AppColors.softOlive,
        onPrimaryContainer: AppColors.deepGreen,
        secondary: AppColors.lightGoldText,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.softOlive,
        onSecondaryContainer: AppColors.deepGreen,
        tertiary: AppColors.mutedGold,
        onTertiary: AppColors.lightTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: const Color(0xFFF9DEDC),
        onErrorContainer: const Color(0xFF410E0B),
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        surfaceContainerLowest: AppColors.lightSurface,
        surfaceContainerLow: AppColors.lightSurfaceLow,
        surfaceContainer: AppColors.lightSurfaceContainer,
        surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
        surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
        outline: AppColors.lightOutline,
        outlineVariant: AppColors.lightOutlineVariant,
        inverseSurface: const Color(0xFF2F382C),
        onInverseSurface: AppColors.darkTextPrimary,
        inversePrimary: AppColors.darkOlive,
        surfaceTint: Colors.transparent,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.olive,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.darkOlive,
        onPrimary: AppColors.darkDeepGreen,
        primaryContainer: AppColors.darkSoftOlive,
        onPrimaryContainer: AppColors.darkOnSoftOlive,
        secondary: AppColors.darkGold,
        onSecondary: AppColors.darkDeepGreen,
        secondaryContainer: AppColors.darkSoftOlive,
        onSecondaryContainer: AppColors.darkOnSoftOlive,
        tertiary: AppColors.darkGold,
        onTertiary: AppColors.darkDeepGreen,
        error: AppColors.darkError,
        onError: const Color(0xFF601410),
        errorContainer: const Color(0xFF8C1D18),
        onErrorContainer: const Color(0xFFF9DEDC),
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        surfaceContainerLowest: AppColors.darkBackground,
        surfaceContainerLow: AppColors.darkSurfaceLow,
        surfaceContainer: AppColors.darkSurfaceContainer,
        surfaceContainerHigh: AppColors.darkSurfaceSecondary,
        surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
        inverseSurface: AppColors.softOlive,
        onInverseSurface: AppColors.lightTextPrimary,
        inversePrimary: AppColors.olive,
        surfaceTint: Colors.transparent,
      );

  static ThemeData _build(
    ColorScheme scheme,
    Color background,
    AppBrandColors brand,
    AppStatusColors status,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme(scheme);

    const pill = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 14);
    const buttonMinimumSize = Size(64, 46);
    final fieldFill = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceContainer;

    OutlineInputBorder inputBorder([Color? color, double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: color == null
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      // iOS-like press feedback: highlights instead of ink ripples.
      splashFactory: NoSplash.splashFactory,
      highlightColor: scheme.onSurface.withValues(alpha: 0.06),
      hoverColor: scheme.onSurface.withValues(alpha: 0.04),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [brand, status],
      appBarTheme: AppBarThemeData(
        backgroundColor: brand.header,
        foregroundColor: brand.onHeader,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: brand.onHeader),
        iconTheme: IconThemeData(color: brand.onHeader),
        actionsIconTheme: IconThemeData(color: brand.onHeader),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge - 4),
          side: isDark
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinimumSize,
          padding: buttonPadding,
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinimumSize,
          padding: buttonPadding,
          shape: pill,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant, width: 1.2),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinimumSize,
          padding: buttonPadding,
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: const StadiumBorder(),
        extendedTextStyle: textTheme.labelLarge,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fieldFill,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: inputBorder(),
        enabledBorder: inputBorder(),
        disabledBorder: inputBorder(),
        focusedBorder: inputBorder(scheme.primary, 1.6),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brand.accentSoft,
        labelStyle: textTheme.labelMedium?.copyWith(color: brand.onAccentSoft),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: brand.accentSoft,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: brand.accentSoft,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: background,
        indicatorColor: brand.accentSoft,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(radiusLarge),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: brand.accentSoft,
          selectedForegroundColor: brand.onAccentSoft,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: brand.accentSoft,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        selectedTileColor: brand.accentSoft,
        selectedColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brand.header,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: brand.onHeader),
        actionTextColor: isDark ? AppColors.darkOlive : AppColors.softOlive,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(radiusSmall - 2),
        ),
      ),
    );
  }
}

/// iOS-style scrolling on every platform: bouncing overscroll and no
/// Material glow/stretch indicator.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
