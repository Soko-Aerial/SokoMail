import 'package:material_ui/material_ui.dart';
import 'package:sokomail/shared/widgets/sokomail_logo.dart';

/// Deep-green header with the centred SokoMail wordmark (mobile inbox and
/// the tablet shell).
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, this.leading, this.actions = const []});

  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      leading: leading,
      title: const SokoMailLogo(onDark: true, size: SokoMailLogoSize.small),
      actions: [...actions, const SizedBox(width: 4)],
    );
  }
}
