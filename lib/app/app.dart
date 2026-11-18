import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/router/app_router.dart';
import 'package:sokomail/app/theme/app_theme.dart';
import 'package:sokomail/features/settings/presentation/providers/theme_mode_controller.dart';

/// Root widget. Expects a `ProviderScope` above it (see `bootstrap.dart`).
class SokoMailApp extends ConsumerWidget {
  const SokoMailApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SokoMail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeControllerProvider),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
