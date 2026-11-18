import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/responsive_page.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';
import 'package:sokomail/features/settings/presentation/providers/theme_mode_controller.dart';
import 'package:sokomail/features/settings/presentation/widgets/settings_group.dart';
import 'package:sokomail/features/settings/presentation/widgets/theme_preview.dart';
import 'package:sokomail/shared/widgets/placeholder_notice.dart';
import 'package:sokomail/shared/widgets/sokomail_logo.dart';

/// Application settings.
///
/// Working: appearance (Light, Dark, System Default; saved on the device),
/// About, and sign-out. Placeholders, marked "Coming soon": account
/// details, security, notifications and language, which need the API.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final config = ref.watch(appConfigProvider);

    void setTheme(ThemeMode? mode) {
      if (mode == null) return;
      unawaited(
        ref.read(themeModeControllerProvider.notifier).setThemeMode(mode),
      );
    }

    void placeholder(String title, String message) => unawaited(
      showPlaceholderNotice(context, title: title, message: message),
    );

    return ResponsivePage(
      title: 'Settings',
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Account',
                        subtitle: user?.email,
                        onTap: () => placeholder(
                          'Account',
                          'Profile details are managed through the SokoMail '
                              'API, which is not connected in this build.',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.shield_outlined,
                        title: 'Security',
                        subtitle: 'Password and signed-in devices',
                        trailing: const PlaceholderTag(),
                        onTap: () => placeholder(
                          'Security',
                          'Password changes and session management arrive '
                              'with server sign-in.',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'New mail alerts',
                        trailing: const PlaceholderTag(),
                        onTap: () => placeholder(
                          'Notifications',
                          'Push notifications for Android, iOS and the web '
                              'arrive in a later release.',
                        ),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Appearance',
                    children: [
                      const SettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        subtitle: 'Choose your preferred theme',
                      ),
                      RadioGroup<ThemeMode>(
                        groupValue: themeMode,
                        onChanged: setTheme,
                        child: const Column(
                          children: [
                            _ThemeOption(
                              mode: ThemeMode.light,
                              icon: Icons.light_mode_outlined,
                              label: 'Light',
                            ),
                            _ThemeOption(
                              mode: ThemeMode.dark,
                              icon: Icons.dark_mode_outlined,
                              label: 'Dark',
                            ),
                            _ThemeOption(
                              mode: ThemeMode.system,
                              icon: Icons.brightness_auto_outlined,
                              label: 'System Default',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ThemePreview(
                          selected: themeMode,
                          onSelected: setTheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'English',
                        trailing: const PlaceholderTag(),
                        onTap: () => placeholder(
                          'Language',
                          'SokoMail is available in English. More languages '
                              'will follow.',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About SokoMail',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'SokoMail',
                          applicationVersion:
                              'Version ${AppConfig.appVersion} '
                              '(${config.environment.name})',
                          applicationIcon: const SokoMailLogo(
                            size: SokoMailLogoSize.small,
                            showTagline: false,
                          ),
                          applicationLegalese: '© SokoAerial Robotics',
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              config.useDevelopmentFixtures
                                  ? 'Demo build: mail shown is development '
                                        'sample data, not real mail.'
                                  : 'Connected to the SokoMail API.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        destructive: true,
                        onTap: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
  });

  final ThemeMode mode;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: mode,
      controlAffinity: ListTileControlAffinity.leading,
      shape: const RoundedRectangleBorder(),
      title: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
