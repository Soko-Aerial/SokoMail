import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/shared/widgets/brand_landscape.dart';
import 'package:sokomail/shared/widgets/pill_label.dart';
import 'package:sokomail/shared/widgets/sokomail_logo.dart';

/// A navigation entry in the drawer, sidebar or bottom bar.
@immutable
class ShellDestination {
  const ShellDestination({
    required this.routeName,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });

  final String routeName;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Count shown next to the label; hidden when 0.
  final int badge;
}

/// A mailbox listed in the sidebar's Mailboxes section.
@immutable
class ShellMailboxEntry {
  const ShellMailboxEntry({
    required this.id,
    required this.label,
    required this.unread,
    required this.isShared,
    required this.isCurrent,
  });

  final String id;
  final String label;
  final int unread;
  final bool isShared;
  final bool isCurrent;
}

/// Permanent deep-green sidebar (tablet and desktop): wordmark, Compose,
/// folders, an expandable Mailboxes section, settings and a decorative
/// footer. Shows icons only when narrower than 200 px (collapsed, or while
/// animating).
class ShellSidebar extends StatefulWidget {
  const ShellSidebar({
    super.key,
    required this.width,
    required this.folders,
    required this.tools,
    required this.mailboxes,
    required this.selectedRouteName,
    required this.manageMailboxesSelected,
    required this.onSelected,
    required this.onMailboxSelected,
    required this.onManageMailboxes,
    required this.onCompose,
  });

  final double width;
  final List<ShellDestination> folders;
  final List<ShellDestination> tools;
  final List<ShellMailboxEntry> mailboxes;
  final String? selectedRouteName;
  final bool manageMailboxesSelected;
  final ValueChanged<ShellDestination> onSelected;
  final ValueChanged<String> onMailboxSelected;
  final VoidCallback onManageMailboxes;
  final VoidCallback onCompose;

  @override
  State<ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends State<ShellSidebar> {
  bool _mailboxesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final iconOnly = widget.width < 200;
    final divider = Padding(
      padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 6, vertical: 10),
      child: Divider(color: brand.onHeaderMuted.withValues(alpha: 0.22)),
    );

    List<Widget> tiles(List<ShellDestination> destinations) => [
      for (final destination in destinations) ...[
        _NavTile(
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
          label: destination.label,
          badge: destination.badge,
          selected: destination.routeName == widget.selectedRouteName,
          onTap: () => widget.onSelected(destination),
          onDark: true,
          iconOnly: iconOnly,
        ),
        const SizedBox(height: 2),
      ],
    ];

    final mailboxSection = iconOnly
        ? [
            _NavTile(
              icon: Icons.layers_outlined,
              selectedIcon: Icons.layers_rounded,
              label: 'Mailboxes',
              selected: widget.manageMailboxesSelected,
              onTap: widget.onManageMailboxes,
              onDark: true,
              iconOnly: true,
            ),
          ]
        : [
            _SectionToggle(
              label: 'Mailboxes',
              expanded: _mailboxesExpanded,
              onTap: () =>
                  setState(() => _mailboxesExpanded = !_mailboxesExpanded),
            ),
            if (_mailboxesExpanded) ...[
              for (final mailbox in widget.mailboxes) ...[
                _MailboxTile(
                  entry: mailbox,
                  onTap: () => widget.onMailboxSelected(mailbox.id),
                ),
                const SizedBox(height: 2),
              ],
              _NavTile(
                icon: Icons.tune_rounded,
                selectedIcon: Icons.tune_rounded,
                label: 'Manage mailboxes',
                selected: widget.manageMailboxesSelected,
                onTap: widget.onManageMailboxes,
                onDark: true,
                dense: true,
              ),
            ],
          ];

    final compose = iconOnly
        ? Center(
            child: Tooltip(
              message: 'Compose',
              excludeFromSemantics: true,
              child: Semantics(
                button: true,
                label: 'Compose',
                child: Material(
                  color: brand.headerAccent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.onCompose,
                    child: SizedBox.square(
                      dimension: 52,
                      child: Icon(
                        Icons.edit_outlined,
                        color: brand.onHeaderAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: brand.headerAccent,
                foregroundColor: brand.onHeaderAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              onPressed: widget.onCompose,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Compose'),
            ),
          );

    return Material(
      color: brand.header,
      // The decorative footer fills whatever height the navigation leaves
      // and scrolls after it on short windows, so it never squeezes the list.
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              iconOnly ? 12 : 16,
              iconOnly ? 18 : 22,
              iconOnly ? 12 : 16,
              16,
            ),
            sliver: SliverList.list(
              children: [
                if (!iconOnly) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: SokoMailLogo(onDark: true),
                  ),
                  const SizedBox(height: 24),
                ],
                compose,
                const SizedBox(height: 18),
                ...tiles(widget.folders),
                divider,
                ...mailboxSection,
                divider,
                ...tiles(widget.tools),
              ],
            ),
          ),
          if (!iconOnly)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: BrandLandscape(height: 110),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modal navigation drawer (phones): deep-green header with the wordmark
/// and account, destinations on a light sheet, and a branded footer.
class ShellDrawer extends StatelessWidget {
  const ShellDrawer({
    super.key,
    required this.sections,
    required this.selectedRouteName,
    required this.onSelected,
    required this.accountHeader,
  });

  /// Groups of destinations separated by dividers.
  final List<List<ShellDestination>> sections;
  final String? selectedRouteName;
  final ValueChanged<ShellDestination> onSelected;
  final Widget accountHeader;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = math.min(320.0, size.width * 0.86);

    return Drawer(
      width: width,
      backgroundColor: brand.header,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SokoMailLogo(onDark: true),
                  const SizedBox(height: 18),
                  accountHeader,
                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  children: [
                    for (final (index, section) in sections.indexed) ...[
                      if (index > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Divider(),
                        ),
                      for (final destination in section)
                        _NavTile(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: destination.label,
                          badge: destination.badge,
                          selected: destination.routeName == selectedRouteName,
                          onTap: () {
                            Scaffold.of(context).closeDrawer();
                            onSelected(destination);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (size.height >= 720) const _DrawerFooter(),
        ],
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 132,
        child: Stack(
          children: [
            const Positioned.fill(child: BrandLandscape(height: 132)),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SokoAerial Robotics',
                    style: text.titleMedium?.copyWith(color: brand.onHeader),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AERIAL ROBOTICS FOR A SAFER, MORE CONNECTED WORLD',
                    style: text.labelSmall?.copyWith(
                      color: brand.onHeaderMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom folder bar (phones), as in the mobile design.
class ShellBottomBar extends StatelessWidget {
  const ShellBottomBar({
    super.key,
    required this.destinations,
    required this.selectedRouteName,
    required this.onSelected,
  });

  final List<ShellDestination> destinations;
  final String? selectedRouteName;
  final ValueChanged<ShellDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                for (final destination in destinations)
                  Expanded(
                    child: _BottomItem(
                      destination: destination,
                      selected: destination.routeName == selectedRouteName,
                      onTap: () => onSelected(destination),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brandColors;
    final badge = destination.badge;
    final label = badge > 0
        ? '${destination.label}, $badge'
        : destination.label;
    final colour = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? brand.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 24,
                      color: colour,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.onDark = false,
    this.iconOnly = false,
    this.dense = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final bool onDark;
  final bool iconOnly;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brandColors;

    final foreground = onDark ? brand.onHeader : scheme.onSurface;
    final iconColor = onDark
        ? (selected ? brand.onHeader : brand.onHeaderMuted)
        : (selected ? scheme.primary : scheme.onSurfaceVariant);
    final background = selected
        ? (onDark ? brand.headerSelected : brand.accentSoft)
        : Colors.transparent;
    final badgeTone = onDark
        ? (selected ? CountBadgeTone.onHeaderSelected : CountBadgeTone.onHeader)
        : (selected ? CountBadgeTone.filled : CountBadgeTone.muted);
    final iconWidget = Icon(
      selected ? selectedIcon : icon,
      size: dense ? 20 : 22,
      color: iconColor,
    );
    final height = dense ? 40.0 : 46.0;

    if (iconOnly) {
      return Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          selected: selected,
          label: badge > 0 ? '$label, $badge' : label,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Badge(
                    isLabelVisible: badge > 0,
                    backgroundColor: brand.headerAccent,
                    textColor: brand.onHeaderAccent,
                    label: Text('$badge'),
                    child: iconWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (dense
                                  ? Theme.of(context).textTheme.bodyMedium
                                  : Theme.of(context).textTheme.titleSmall)
                              ?.copyWith(
                                color: foreground,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                    ),
                  ),
                  if (badge > 0) CountBadge(count: badge, tone: badgeTone),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MailboxTile extends StatelessWidget {
  const _MailboxTile({required this.entry, required this.onTap});

  final ShellMailboxEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final current = entry.isCurrent;
    return Semantics(
      button: true,
      selected: current,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    entry.isShared
                        ? (current
                              ? Icons.work_rounded
                              : Icons.work_outline_rounded)
                        : (current
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded),
                    size: 20,
                    color: current ? brand.headerAccent : brand.onHeaderMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: brand.onHeader,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (entry.unread > 0)
                    CountBadge(
                      count: entry.unread,
                      tone: CountBadgeTone.onHeader,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: brand.onHeader),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: brand.onHeaderMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
