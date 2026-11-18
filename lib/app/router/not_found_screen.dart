import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/router/route_paths.dart';
import 'package:sokomail/shared/widgets/app_button.dart';
import 'package:sokomail/shared/widgets/app_empty_state.dart';

/// Shown for any URL that does not match a SokoMail route.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.path});

  /// The unmatched path (query string excluded).
  final String path;

  @override
  Widget build(BuildContext context) {
    final shownPath = path.length > 80 ? '${path.substring(0, 80)}...' : path;
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: AppEmptyState(
        icon: Icons.link_off,
        title: 'Page not found',
        message: 'There is no SokoMail page at "$shownPath".',
        action: AppButton(
          label: 'Go to SokoMail',
          icon: Icons.home_outlined,
          onPressed: () => context.go(RoutePaths.root),
        ),
      ),
    );
  }
}
