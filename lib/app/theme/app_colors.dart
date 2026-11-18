import 'package:material_ui/material_ui.dart';

/// SokoMail colour tokens (approved olive-green palette).
///
/// Screens must not use these constants directly; read colours from
/// `Theme.of(context).colorScheme`, [AppBrandColors] or [AppStatusColors]
/// so light and dark mode both work.
abstract final class AppColors {
  // ---------------------------------------------------------------- Light
  static const olive = Color(0xFF536537);
  static const deepGreen = Color(0xFF283423);
  static const softOlive = Color(0xFFE4E9D5);
  static const lightBackground = Color(0xFFF7F6F1);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF202820);
  static const lightTextSecondary = Color(0xFF667063);
  static const mutedGold = Color(0xFFB5A269);

  // Derived light neutrals (warm, matching the background).
  static const lightSurfaceLow = Color(0xFFFBFAF6);
  static const lightSurfaceContainer = Color(0xFFF1F0E9);
  static const lightSurfaceContainerHigh = Color(0xFFECEBE3);
  static const lightSurfaceContainerHighest = Color(0xFFE6E5DC);
  static const lightOutline = Color(0xFF858E7E);
  static const lightOutlineVariant = Color(0xFFE3E3D9);
  static const lightGoldText = Color(0xFF6E5F2F);

  // ----------------------------------------------------------------- Dark
  static const darkOlive = Color(0xFFA4BA78);
  static const darkDeepGreen = Color(0xFF1C281C);
  static const darkBackground = Color(0xFF151C16);
  static const darkSurface = Color(0xFF242D24);
  static const darkSurfaceSecondary = Color(0xFF2F392D);
  static const darkTextPrimary = Color(0xFFF0F3EB);
  static const darkTextSecondary = Color(0xFFB5C0AD);

  // Derived dark tones.
  static const darkSoftOlive = Color(0xFF3A4630);
  static const darkOnSoftOlive = Color(0xFFD6E2BE);
  static const darkSurfaceLow = Color(0xFF1D251D);
  static const darkSurfaceContainer = Color(0xFF2A332A);
  static const darkSurfaceContainerHighest = Color(0xFF384336);
  static const darkOutline = Color(0xFF7D8877);
  static const darkOutlineVariant = Color(0xFF384236);
  static const darkGold = Color(0xFFCDBB85);

  // ------------------------------------------------------------ Functional
  // Material 3 error tones: #DC2626 falls just below 4.5:1 on the warm
  // background, so a deeper red is used for text.
  static const error = Color(0xFFB3261E);
  static const darkError = Color(0xFFF2B8B5);
  static const success = Color(0xFF3C7A2E);
  static const warning = Color(0xFFD9A21B);
}

/// Brand surfaces that Material's [ColorScheme] has no slot for: the deep
/// green frame (sidebar, top bar, mobile header), soft olive highlights and
/// avatar colours.
///
/// Read with `context.brandColors`.
@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.headerSelected,
    required this.headerField,
    required this.headerAccent,
    required this.onHeaderAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.unreadIndicator,
    required this.avatarColors,
  });

  static const light = AppBrandColors(
    header: AppColors.deepGreen,
    onHeader: AppColors.darkTextPrimary,
    onHeaderMuted: AppColors.darkTextSecondary,
    headerSelected: Color(0xFF4A5A33),
    headerField: Color(0x1FFFFFFF),
    headerAccent: AppColors.darkOlive,
    onHeaderAccent: AppColors.darkDeepGreen,
    accentSoft: AppColors.softOlive,
    onAccentSoft: AppColors.olive,
    unreadIndicator: AppColors.olive,
    avatarColors: [
      (background: AppColors.olive, foreground: Colors.white),
      (background: Color(0xFF6B7A47), foreground: Colors.white),
      (background: AppColors.mutedGold, foreground: AppColors.lightTextPrimary),
      (background: Color(0xFF75673F), foreground: Colors.white),
      (background: Color(0xFF3F5130), foreground: Colors.white),
    ],
  );

  static const dark = AppBrandColors(
    header: AppColors.darkDeepGreen,
    onHeader: AppColors.darkTextPrimary,
    onHeaderMuted: AppColors.darkTextSecondary,
    headerSelected: AppColors.darkSoftOlive,
    headerField: Color(0x14FFFFFF),
    headerAccent: AppColors.darkOlive,
    onHeaderAccent: AppColors.darkDeepGreen,
    accentSoft: AppColors.darkSoftOlive,
    onAccentSoft: AppColors.darkOnSoftOlive,
    unreadIndicator: AppColors.darkOlive,
    avatarColors: [
      (background: AppColors.darkOlive, foreground: AppColors.darkDeepGreen),
      (background: Color(0xFF8FA06A), foreground: AppColors.darkDeepGreen),
      (background: AppColors.darkGold, foreground: AppColors.darkDeepGreen),
      (background: Color(0xFFB9C79A), foreground: AppColors.darkDeepGreen),
      (background: Color(0xFFC9D3AE), foreground: AppColors.darkDeepGreen),
    ],
  );

  /// Deep army green of the app frame: sidebar, top bar, mobile header.
  final Color header;
  final Color onHeader;
  final Color onHeaderMuted;

  /// Selected navigation item on [header].
  final Color headerSelected;

  /// Translucent fill for fields, badges and toggles on [header].
  final Color headerField;

  /// Lime accent for the Compose button and the user avatar on [header].
  final Color headerAccent;
  final Color onHeaderAccent;

  /// Soft olive for pills, selected rows and highlights.
  final Color accentSoft;
  final Color onAccentSoft;
  final Color unreadIndicator;

  /// Avatar colour pairs; senders are assigned one deterministically.
  final List<({Color background, Color foreground})> avatarColors;

  @override
  AppBrandColors copyWith({
    Color? header,
    Color? onHeader,
    Color? onHeaderMuted,
    Color? headerSelected,
    Color? headerField,
    Color? headerAccent,
    Color? onHeaderAccent,
    Color? accentSoft,
    Color? onAccentSoft,
    Color? unreadIndicator,
    List<({Color background, Color foreground})>? avatarColors,
  }) {
    return AppBrandColors(
      header: header ?? this.header,
      onHeader: onHeader ?? this.onHeader,
      onHeaderMuted: onHeaderMuted ?? this.onHeaderMuted,
      headerSelected: headerSelected ?? this.headerSelected,
      headerField: headerField ?? this.headerField,
      headerAccent: headerAccent ?? this.headerAccent,
      onHeaderAccent: onHeaderAccent ?? this.onHeaderAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccentSoft: onAccentSoft ?? this.onAccentSoft,
      unreadIndicator: unreadIndicator ?? this.unreadIndicator,
      avatarColors: avatarColors ?? this.avatarColors,
    );
  }

  @override
  AppBrandColors lerp(AppBrandColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppBrandColors(
      header: mix(header, other.header),
      onHeader: mix(onHeader, other.onHeader),
      onHeaderMuted: mix(onHeaderMuted, other.onHeaderMuted),
      headerSelected: mix(headerSelected, other.headerSelected),
      headerField: mix(headerField, other.headerField),
      headerAccent: mix(headerAccent, other.headerAccent),
      onHeaderAccent: mix(onHeaderAccent, other.onHeaderAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccentSoft: mix(onAccentSoft, other.onAccentSoft),
      unreadIndicator: mix(unreadIndicator, other.unreadIndicator),
      avatarColors: t < 0.5 ? avatarColors : other.avatarColors,
    );
  }
}

/// Semantic status colours that Material's [ColorScheme] does not provide.
///
/// Read with `Theme.of(context).extension<AppStatusColors>()!`.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  static const light = AppStatusColors(
    success: AppColors.success,
    onSuccess: Colors.white,
    // Amber is too light for text on white; use it as a fill with dark text.
    warning: AppColors.warning,
    onWarning: AppColors.lightTextPrimary,
  );

  static const dark = AppStatusColors(
    success: Color(0xFF8CC37A),
    onSuccess: AppColors.darkDeepGreen,
    warning: Color(0xFFE6C15A),
    onWarning: AppColors.darkDeepGreen,
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}

/// Convenience accessors for the theme extensions.
extension AppThemeColors on BuildContext {
  AppBrandColors get brandColors =>
      Theme.of(this).extension<AppBrandColors>() ?? AppBrandColors.light;

  AppStatusColors get statusColors =>
      Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.light;
}
