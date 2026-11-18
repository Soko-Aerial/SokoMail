// Renders representative screens to PNG for visual review against the
// approved designs. Skipped by default; run explicitly:
//
//   flutter test test/tool/app_screenshots_test.dart --dart-define=UPDATE_SCREENSHOTS=true
//
// Output: docs/screenshots/*.png. Fonts (Roboto, Material Icons) are loaded
// from the Flutter SDK so text renders as on Android and the web.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/app.dart';
import 'package:sokomail/app/router/app_router.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';
import 'package:sokomail/features/settings/presentation/providers/theme_mode_controller.dart';

const _enabled = bool.fromEnvironment('UPDATE_SCREENSHOTS');
const _outputDir = 'docs/screenshots';

/// `<flutter>/bin/cache/artifacts/material_fonts`, found from the test
/// runner's own location inside the SDK.
Directory _sdkFonts() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path) {
    final fonts = Directory('${dir.path}/material_fonts');
    if (fonts.existsSync()) return fonts;
    dir = dir.parent;
  }
  throw StateError('Flutter SDK fonts not found');
}

Future<void> _loadFonts() async {
  final fonts = _sdkFonts();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('${fonts.path}/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

final _boundary = GlobalKey();

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  UserRole? role = UserRole.employee,
  String? location,
  ThemeMode mode = ThemeMode.light,
}) async {
  // Real shadows (the test binding draws them as outlines by default).
  debugDisableShadows = false;
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: ProviderScope(retry: (_, _) => null, child: const SokoMailApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = tester.container();
  await container.read(themeModeControllerProvider.notifier).setThemeMode(mode);
  if (role != null) {
    container
        .read(authControllerProvider.notifier)
        .startDevelopmentSession(role);
  }
  await tester.pumpAndSettle();
  if (location != null) {
    container.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  double ratio = 1,
}) async {
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_outputDir).createSync(recursive: true);
    File('$_outputDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

const _message = '/mail/dev-personal/messages/dev-msg-001?folder=inbox';

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  final shots = <String, Future<void> Function(WidgetTester)>{
    'desktop_light': (t) async {
      await _pump(
        t,
        const Size(1440, 900),
        role: UserRole.admin,
        location: _message,
      );
      await _capture(t, 'desktop_light');
    },
    'desktop_dark': (t) async {
      await _pump(
        t,
        const Size(1440, 900),
        role: UserRole.admin,
        mode: ThemeMode.dark,
        location: _message,
      );
      await _capture(t, 'desktop_dark');
    },
    'desktop_sidebar_collapsed': (t) async {
      await _pump(t, const Size(1280, 800));
      await t.tap(find.byIcon(Icons.menu_open_rounded));
      await t.pumpAndSettle();
      await _capture(t, 'desktop_sidebar_collapsed');
    },
    'tablet_two_pane': (t) async {
      await _pump(t, const Size(834, 1112), location: _message);
      await _capture(t, 'tablet_two_pane');
    },
    'mobile_inbox': (t) async {
      await _pump(t, const Size(390, 844));
      await _capture(t, 'mobile_inbox', ratio: 2);
    },
    'mobile_inbox_dark': (t) async {
      await _pump(t, const Size(390, 844), mode: ThemeMode.dark);
      await _capture(t, 'mobile_inbox_dark', ratio: 2);
    },
    'mobile_drawer': (t) async {
      await _pump(t, const Size(390, 844), role: UserRole.admin);
      await t.tap(find.byType(DrawerButton));
      await t.pumpAndSettle();
      await _capture(t, 'mobile_drawer', ratio: 2);
    },
    'mobile_message': (t) async {
      await _pump(t, const Size(390, 844), location: _message);
      await _capture(t, 'mobile_message', ratio: 2);
    },
    'mobile_settings': (t) async {
      await _pump(t, const Size(390, 844), location: '/settings');
      await _capture(t, 'mobile_settings', ratio: 2);
    },
    'mobile_compose_dark': (t) async {
      await _pump(
        t,
        const Size(390, 844),
        mode: ThemeMode.dark,
        location:
            '/compose?mode=reply&mailboxId=dev-personal&messageId=dev-msg-001',
      );
      await _capture(t, 'mobile_compose_dark', ratio: 2);
    },
    'mobile_login': (t) async {
      await _pump(t, const Size(390, 844), role: null);
      await _capture(t, 'mobile_login', ratio: 2);
    },
    'desktop_login': (t) async {
      await _pump(t, const Size(1440, 900), role: null);
      await _capture(t, 'desktop_login');
    },
  };

  for (final MapEntry(key: name, value: body) in shots.entries) {
    testWidgets(name, body, skip: !_enabled);
  }
}
