import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/app/theme/app_theme.dart';
import 'package:sokomail/core/storage/preferences_store.dart';
import 'package:sokomail/core/storage/shared_preferences_store.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/settings/presentation/providers/theme_mode_controller.dart';

import '../../helpers/test_app.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('Olive design tokens', () {
    test('light theme uses the approved palette', () {
      final theme = AppTheme.light;
      final scheme = theme.colorScheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(scheme.primary, const Color(0xFF536537));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F6F1));
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.onSurface, const Color(0xFF202820));
      expect(scheme.onSurfaceVariant, const Color(0xFF667063));
      expect(scheme.tertiary, const Color(0xFFB5A269));
      final brand = theme.extension<AppBrandColors>()!;
      expect(brand.header, const Color(0xFF283423));
      expect(brand.accentSoft, const Color(0xFFE4E9D5));
    });

    test('dark theme uses the approved palette', () {
      final theme = AppTheme.dark;
      final scheme = theme.colorScheme;
      expect(theme.brightness, Brightness.dark);
      expect(scheme.primary, const Color(0xFFA4BA78));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF151C16));
      expect(scheme.surface, const Color(0xFF242D24));
      expect(scheme.surfaceContainerHigh, const Color(0xFF2F392D));
      expect(scheme.onSurface, const Color(0xFFF0F3EB));
      expect(scheme.onSurfaceVariant, const Color(0xFFB5C0AD));
      expect(
        theme.extension<AppBrandColors>()!.header,
        const Color(0xFF1C281C),
      );
    });

    test('text and controls meet WCAG AA contrast (4.5:1)', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final scheme = theme.colorScheme;
        final brand = theme.extension<AppBrandColors>()!;
        final pairs = {
          'text on background': (
            scheme.onSurface,
            theme.scaffoldBackgroundColor,
          ),
          'secondary text on surface': (
            scheme.onSurfaceVariant,
            scheme.surface,
          ),
          'secondary text on background': (
            scheme.onSurfaceVariant,
            theme.scaffoldBackgroundColor,
          ),
          'primary on background': (
            scheme.primary,
            theme.scaffoldBackgroundColor,
          ),
          'label on primary': (scheme.onPrimary, scheme.primary),
          'header text': (brand.onHeader, brand.header),
          'muted header text': (brand.onHeaderMuted, brand.header),
          'compose on header': (brand.onHeaderAccent, brand.headerAccent),
          'header badge': (
            brand.onHeader,
            Color.alphaBlend(brand.headerField, brand.header),
          ),
          'selected sidebar item': (brand.onHeader, brand.headerSelected),
          'pill text': (brand.onAccentSoft, brand.accentSoft),
          'error text': (scheme.error, theme.scaffoldBackgroundColor),
        };
        for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.brightness.name}: $name',
          );
        }
      }
    });

    test('component themes follow the iOS-inspired design', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final brand = theme.extension<AppBrandColors>()!;
        expect(theme.appBarTheme.backgroundColor, brand.header);
        expect(theme.appBarTheme.centerTitle, isTrue);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.floatingActionButtonTheme.shape, isA<StadiumBorder>());
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
        for (final platform in TargetPlatform.values) {
          expect(
            theme.pageTransitionsTheme.builders[platform],
            isA<CupertinoPageTransitionsBuilder>(),
            reason: platform.name,
          );
        }
      }
    });
  });

  group('Theme mode', () {
    test('defaults to the system preference', () {
      final container = ProviderContainer.test();
      expect(container.read(themeModeControllerProvider), ThemeMode.system);
    });

    test('restores and persists the preference through the store', () async {
      final store = InMemoryPreferencesStore({
        PreferenceKeys.themeMode: 'dark',
      });
      final container = ProviderContainer.test(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);

      await container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeControllerProvider), ThemeMode.light);
      expect(store.readString(PreferenceKeys.themeMode), 'light');
    });

    test(
      'the choice survives reopening the app (shared_preferences)',
      () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();

        // First "launch": choose dark mode.
        final firstLaunch = ProviderContainer.test(
          overrides: [
            preferencesStoreProvider.overrideWithValue(
              await SharedPreferencesStore.load(),
            ),
          ],
        );
        await firstLaunch
            .read(themeModeControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        firstLaunch.dispose();

        // Second "launch": a fresh store reads the saved value.
        final secondLaunch = ProviderContainer.test(
          overrides: [
            preferencesStoreProvider.overrideWithValue(
              await SharedPreferencesStore.load(),
            ),
          ],
        );
        expect(secondLaunch.read(themeModeControllerProvider), ThemeMode.dark);
      },
    );

    testWidgets('Settings switches Light, Dark and System Default', (
      tester,
    ) async {
      final container = await pumpSokoMailApp(
        tester,
        signedInAs: UserRole.employee,
        location: '/settings',
      );
      BuildContext context() => tester.element(find.text('Appearance'));

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(Theme.of(context()).brightness, Brightness.dark);
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(Theme.of(context()).brightness, Brightness.light);

      await tester.tap(find.text('System Default'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the desktop top bar toggles light and dark', (tester) async {
      await pumpSokoMailApp(tester, signedInAs: UserRole.employee);
      BuildContext context() => tester.element(find.text('Inbox').first);

      await tester.tap(find.bySemanticsLabel('Dark theme'));
      await tester.pumpAndSettle();
      expect(Theme.of(context()).brightness, Brightness.dark);

      await tester.tap(find.bySemanticsLabel('Light theme'));
      await tester.pumpAndSettle();
      expect(Theme.of(context()).brightness, Brightness.light);
    });
  });
}
