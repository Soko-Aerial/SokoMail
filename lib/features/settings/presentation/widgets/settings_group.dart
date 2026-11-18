import 'package:material_ui/material_ui.dart';

/// iOS-style grouped list: rounded card with divided rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        Card(
          child: Column(
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const Divider(indent: 56),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A settings row with leading icon and optional subtitle/trailing.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    final color = destructive ? scheme.error : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: const RoundedRectangleBorder(),
      leading: Icon(icon, color: color ?? scheme.onSurface),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing:
          trailing ??
          (onTap != null && !destructive
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }
}
