import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

/// Circular initials avatar with a colour chosen deterministically from the
/// name, so a sender always gets the same colour.
class SenderAvatar extends StatelessWidget {
  const SenderAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.background,
    this.foreground,
  });

  final String name;
  final double size;

  /// Overrides the colour picked from the name (e.g. the signed-in user).
  final Color? background;
  final Color? foreground;

  /// "Engineering Team" -> "ET", "R&D Robotics" -> "RD", "Operations" -> "OP".
  static String initialsOf(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.contains(RegExp('[A-Za-z]')))
        .toList();
    if (words.isEmpty) return '?';

    final first = words.first;
    final capitals = first.replaceAll(RegExp('[^A-Z]'), '');
    if (capitals.length >= 2) return capitals.substring(0, 2);
    if (words.length >= 2) {
      return (first[0] + words[1].replaceAll(RegExp('[^A-Za-z]'), '')[0])
          .toUpperCase();
    }
    final letters = first.replaceAll(RegExp('[^A-Za-z]'), '');
    return letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandColors.avatarColors;
    final seed = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final colors = palette[seed % palette.length];

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? colors.background,
          shape: BoxShape.circle,
        ),
        child: Text(
          initialsOf(name),
          style: TextStyle(
            color: foreground ?? colors.foreground,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
