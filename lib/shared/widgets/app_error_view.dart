import 'package:material_ui/material_ui.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/shared/extensions/build_context_theme.dart';
import 'package:sokomail/shared/widgets/app_button.dart';
import 'package:sokomail/shared/widgets/app_empty_state.dart';

/// Displays a failure using only its user-safe message.
///
/// Raw exception text is never shown: it may contain server details or
/// fragments of request data.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  /// Any thrown object; it is normalised with [AppFailure.from].
  final Object error;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = AppFailure.from(error);
    final onRetry = this.onRetry;
    return AppEmptyState(
      icon: Icons.error_outline,
      iconColor: context.colorScheme.error,
      title: title,
      message: failure.userMessage,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Try again',
              icon: Icons.refresh,
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}
