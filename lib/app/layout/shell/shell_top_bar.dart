import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/settings/presentation/providers/theme_mode_controller.dart';
import 'package:sokomail/shared/widgets/menu_item_label.dart';
import 'package:sokomail/shared/widgets/sender_avatar.dart';

/// Deep-green top bar (tablet and desktop): sidebar toggle, mail search with
/// a Ctrl/Cmd+K shortcut, theme toggle, notifications, help and account.
class ShellTopBar extends StatelessWidget {
  const ShellTopBar({
    super.key,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.onSearch,
    required this.onNotifications,
    required this.onHelp,
    required this.accountMenuBuilder,
  });

  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final ValueChanged<String> onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onHelp;

  /// Builds the account menu; `showName` is false when space is short.
  final Widget Function(bool showName) accountMenuBuilder;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final iconStyle = IconButton.styleFrom(foregroundColor: brand.onHeader);

    return SizedBox(
      height: 72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The two-line name block needs the width, and fits the bar's
          // height only near the default text size; otherwise the avatar
          // stands alone (the name is in the account menu).
          final roomy =
              constraints.maxWidth >= 900 &&
              MediaQuery.textScalerOf(context).scale(14) <= 16;
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            child: Row(
              children: [
                IconButton(
                  style: iconStyle,
                  tooltip: sidebarCollapsed
                      ? 'Expand sidebar'
                      : 'Collapse sidebar',
                  icon: Icon(
                    sidebarCollapsed
                        ? Icons.menu_rounded
                        : Icons.menu_open_rounded,
                  ),
                  onPressed: onToggleSidebar,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: _TopSearch(onSearch: onSearch),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const ThemeModeToggle(),
                const SizedBox(width: 6),
                IconButton(
                  style: iconStyle,
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: onNotifications,
                ),
                IconButton(
                  style: iconStyle,
                  tooltip: 'Help & Support',
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: onHelp,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 28,
                    child: VerticalDivider(
                      width: 1,
                      color: brand.onHeaderMuted.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                accountMenuBuilder(roomy),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopSearch extends StatefulWidget {
  const _TopSearch({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<_TopSearch> createState() => _TopSearchState();
}

class _TopSearchState extends State<_TopSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'top-search');

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Ctrl+K (Cmd+K on Apple platforms) focuses mail search.
  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyK) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    final modifier = _apple
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;
    if (!modifier) return false;
    _focusNode.requestFocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    final text = Theme.of(context).textTheme;

    return TextField(
      key: const ValueKey('top-search'),
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      style: text.bodyLarge?.copyWith(color: brand.onHeader),
      cursorColor: brand.headerAccent,
      onSubmitted: (value) {
        final query = value.trim();
        if (query.isEmpty) return;
        widget.onSearch(query);
        _controller.clear();
        _focusNode.unfocus();
      },
      decoration: InputDecoration(
        hintText: 'Search emails, people, or attachments...',
        hintStyle: text.bodyLarge?.copyWith(color: brand.onHeaderMuted),
        isDense: true,
        filled: true,
        fillColor: brand.headerField,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        prefixIcon: Icon(Icons.search_rounded, color: brand.onHeaderMuted),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _KeyHint(label: _apple ? '⌘ K' : 'Ctrl K'),
        ),
        suffixIconConstraints: const BoxConstraints(minHeight: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brand.onHeaderMuted.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.headerAccent, width: 1.6),
        ),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: brand.headerField,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: brand.onHeaderMuted.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: brand.onHeaderMuted),
        ),
      ),
    );
  }
}

/// Sun/moon switch between light and dark themes on the deep-green frame.
/// "System Default" is available in Settings.
class ThemeModeToggle extends ConsumerWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    void set(ThemeMode mode) => unawaited(
      ref.read(themeModeControllerProvider.notifier).setThemeMode(mode),
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.brandColors.headerField,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleSegment(
              icon: Icons.light_mode_rounded,
              label: 'Light theme',
              selected: brightness == Brightness.light,
              onTap: () => set(ThemeMode.light),
            ),
            _ToggleSegment(
              icon: Icons.dark_mode_rounded,
              label: 'Dark theme',
              selected: brightness == Brightness.dark,
              onTap: () => set(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? brand.headerAccent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: selected ? brand.onHeaderAccent : brand.onHeaderMuted,
            ),
          ),
        ),
      ),
    );
  }
}

enum AccountMenuAction { mailboxes, settings, signOut }

/// The signed-in employee's avatar with the account menu.
///
/// On the deep-green frame: avatar only, or with name and organisation
/// ([showName]). In the drawer header: avatar, name and address
/// ([detailed]).
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({
    super.key,
    required this.user,
    required this.isDevelopmentSession,
    required this.onSelected,
    this.showName = false,
    this.detailed = false,
  });

  final AppUser user;
  final bool isDevelopmentSession;
  final ValueChanged<AccountMenuAction> onSelected;
  final bool showName;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brandColors;
    final avatar = SenderAvatar(
      name: user.displayName,
      size: detailed ? 48 : 38,
      background: brand.headerAccent,
      foreground: brand.onHeaderAccent,
    );

    Widget nameBlock(String secondLine, {required bool large}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (large ? theme.textTheme.titleMedium : theme.textTheme.titleSmall)
                  ?.copyWith(color: brand.onHeader),
        ),
        Text(
          secondLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: brand.onHeaderMuted,
          ),
        ),
      ],
    );

    final Widget child = detailed
        ? Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: nameBlock(user.email, large: true)),
              Icon(Icons.expand_more_rounded, color: brand.onHeader),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              if (showName) ...[
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: nameBlock('SokoAerial Robotics', large: false),
                ),
              ],
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, color: brand.onHeaderMuted),
            ],
          );

    return PopupMenuButton<AccountMenuAction>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<AccountMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName, style: theme.textTheme.titleSmall),
              Text(user.email, style: theme.textTheme.bodySmall),
              if (isDevelopmentSession)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Development session (not server-authenticated)',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: AccountMenuAction.mailboxes,
          child: MenuItemLabel(Icons.layers_outlined, 'Mailboxes'),
        ),
        const PopupMenuItem(
          value: AccountMenuAction.settings,
          child: MenuItemLabel(Icons.settings_outlined, 'Settings'),
        ),
        const PopupMenuItem(
          value: AccountMenuAction.signOut,
          child: MenuItemLabel(Icons.logout_rounded, 'Sign out'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: child,
      ),
    );
  }
}
