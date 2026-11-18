import 'package:material_ui/material_ui.dart';

enum AppButtonVariant {
  /// Filled: the main action on a screen.
  primary,

  /// Outlined: an alternative action.
  secondary,

  /// Text only: low-emphasis actions.
  tertiary,
}

/// Themed button used throughout SokoMail.
///
/// * Disabled when [onPressed] is null or [isLoading] is true.
/// * [isLoading] replaces the icon with a progress indicator and announces
///   the busy state to screen readers.
/// * [expand] makes the button fill the available width (forms on phones).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final Widget? leading = isLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null ? null : Icon(icon, size: 18));
    final text = Text(label, overflow: TextOverflow.ellipsis);

    final Widget button = switch (variant) {
      AppButtonVariant.primary =>
        leading == null
            ? FilledButton(onPressed: effectiveOnPressed, child: text)
            : FilledButton.icon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: text,
              ),
      AppButtonVariant.secondary =>
        leading == null
            ? OutlinedButton(onPressed: effectiveOnPressed, child: text)
            : OutlinedButton.icon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: text,
              ),
      AppButtonVariant.tertiary =>
        leading == null
            ? TextButton(onPressed: effectiveOnPressed, child: text)
            : TextButton.icon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: text,
              ),
    };

    return Semantics(
      // Announce progress while the label stays unchanged.
      value: isLoading ? 'In progress' : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
