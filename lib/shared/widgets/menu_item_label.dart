import 'package:material_ui/material_ui.dart';

/// Icon and label for a popup menu entry.
///
/// Popup menus are at most 280 px wide, so the label wraps instead of
/// overflowing with long translations or large text sizes.
class MenuItemLabel extends StatelessWidget {
  const MenuItemLabel(this.icon, this.label, {super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}
