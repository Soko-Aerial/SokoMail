import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/responsive_page.dart';
import 'package:sokomail/shared/widgets/placeholder_notice.dart';

/// PLACEHOLDER: administration (employees, mailbox permissions, settings).
///
/// The route is admin-only and hidden from other roles, but that is only a
/// convenience: the Go API must authorise every administrative request.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  static const _sections = [
    (
      Icons.badge_outlined,
      'Employees',
      'Invite employees and manage their roles.',
    ),
    (
      Icons.admin_panel_settings_outlined,
      'Mailbox permissions',
      'Grant read, send and manage access to company mailboxes.',
    ),
    (
      Icons.dns_outlined,
      'Mail server',
      'Connection to the company mail server, held by the SokoMail API.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsivePage(
      title: 'Administration',
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Administration is not available yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These tools will be enabled once SokoMail is connected '
                    'to its API, which enforces every administrative '
                    'permission.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (icon, title, description) in _sections) ...[
                    Card(
                      child: ListTile(
                        enabled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Icon(icon),
                        title: Text(title),
                        subtitle: Text(description),
                        trailing: const PlaceholderTag(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
