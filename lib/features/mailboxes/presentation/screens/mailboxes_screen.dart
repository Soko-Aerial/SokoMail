import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/responsive_page.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/features/mailboxes/domain/entities/mailbox.dart';
import 'package:sokomail/features/mailboxes/presentation/providers/mailbox_providers.dart';
import 'package:sokomail/shared/widgets/app_empty_state.dart';
import 'package:sokomail/shared/widgets/app_error_view.dart';
import 'package:sokomail/shared/widgets/app_loading_indicator.dart';
import 'package:sokomail/shared/widgets/pill_label.dart';

/// Mailbox selection: every mailbox the employee may access, with its type
/// and permissions. Access is granted by an administrator through the API.
class MailboxesScreen extends ConsumerWidget {
  const MailboxesScreen({
    super.key,
    required this.selectedMailboxId,
    required this.onMailboxSelected,
    this.onBack,
  });

  final String? selectedMailboxId;
  final ValueChanged<String> onMailboxSelected;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mailboxes = ref.watch(accessibleMailboxesProvider);

    return ResponsivePage(
      title: 'Mailboxes',
      onBack: onBack,
      body: mailboxes.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView(
          title: 'Could not load mailboxes',
          error: error,
          onRetry: () => ref.invalidate(accessibleMailboxesProvider),
        ),
        data: (mailboxes) => mailboxes.isEmpty
            ? const AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No mailboxes assigned',
                message: 'Ask an administrator to grant you mailbox access.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final mailbox in mailboxes) ...[
                            _MailboxCard(
                              mailbox: mailbox,
                              selected: mailbox.id == selectedMailboxId,
                              onTap: () => onMailboxSelected(mailbox.id),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Mailbox access is managed by your administrator.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MailboxCard extends StatelessWidget {
  const _MailboxCard({
    required this.mailbox,
    required this.selected,
    required this.onTap,
  });

  final Mailbox mailbox;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brandColors;
    final shared = mailbox.kind == MailboxKind.shared;

    return Card(
      color: selected ? brand.accentSoft : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  shared ? Icons.group_outlined : Icons.person_outline_rounded,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mailbox.displayName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      mailbox.emailAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PillLabel(shared ? 'Shared' : 'Personal'),
                        for (final permission in MailboxPermission.values)
                          if (mailbox.permissions.contains(permission))
                            PillLabel(switch (permission) {
                              MailboxPermission.read => 'Read',
                              MailboxPermission.send => 'Send',
                              MailboxPermission.manage => 'Manage',
                            }),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
