import 'package:material_ui/material_ui.dart';

/// Renders a plain-text message body with light structure: paragraphs,
/// bullet lists ("• ", "- ", "* ") with olive dots, and a bold heading for a
/// short line ending in ":" that introduces a list.
///
/// No HTML or markup is interpreted, so untrusted message content cannot
/// inject formatting or links (see the security notes in
/// docs/architecture/overview.md).
class MessageBodyText extends StatelessWidget {
  const MessageBodyText(this.text, {super.key});

  final String text;

  static final _bullet = RegExp(r'^\s*[•\-*]\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge;
    final lines = text.split('\n');

    bool nextIsBullet(int index) {
      for (var i = index + 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        return _bullet.hasMatch(lines[i]);
      }
      return false;
    }

    final children = <Widget>[];
    var previousBlank = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.trim().isEmpty) {
        if (!previousBlank) children.add(const SizedBox(height: 12));
        previousBlank = true;
        continue;
      }
      previousBlank = false;

      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(bullet.group(1)!, style: style)),
              ],
            ),
          ),
        );
        continue;
      }

      final isHeading =
          line.endsWith(':') && line.length <= 40 && nextIsBullet(i);
      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: isHeading ? 6 : 0),
          child: Text(
            line,
            style: isHeading
                ? style?.copyWith(fontWeight: FontWeight.w700)
                : style,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
