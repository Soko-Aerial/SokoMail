import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';
import 'package:sokomail/shared/extensions/build_context_theme.dart';
import 'package:sokomail/shared/widgets/app_button.dart';
import 'package:sokomail/shared/widgets/app_text_field.dart';
import 'package:sokomail/shared/widgets/brand_landscape.dart';
import 'package:sokomail/shared/widgets/sokomail_logo.dart';

/// Sign-in screen.
///
/// PLACEHOLDER: server sign-in is disabled until the SokoMail Go API exists.
/// The form shows the intended layout only; nothing typed here is stored or
/// sent. Debug builds additionally offer a clearly labelled development
/// session. Navigation after sign-in is handled by the router guard.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final showDevelopmentSession =
        AppConfig.developmentToolsCompiledIn && config.allowDevelopmentSession;

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ServerSignInCard(),
          if (showDevelopmentSession) ...[
            const SizedBox(height: 16),
            _DevelopmentSessionCard(
              onContinue: (role) => ref
                  .read(authControllerProvider.notifier)
                  .startDevelopmentSession(role),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide: brand panel beside the form.
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(
                  flex: 6,
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Narrow: green brand header, form on a rounded sheet.
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BrandHeader(),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                        child: Center(child: form),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Deep-green brand header for narrow screens.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    return ColoredBox(
      color: brand.header,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 36),
            const SokoMailLogo(onDark: true, size: SokoMailLogoSize.large),
            const SizedBox(height: 12),
            Text(
              'Secure company email',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: brand.onHeaderMuted),
            ),
            const SizedBox(height: 12),
            const BrandLandscape(height: 96),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

/// Deep-green brand panel beside the form on wide screens.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    return ColoredBox(
      color: brand.header,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BrandLandscape(height: 220),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SokoMailLogo(
                    onDark: true,
                    size: SokoMailLogoSize.large,
                  ),
                  const Spacer(),
                  Text(
                    'Secure company email for SokoAerial Robotics.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: brand.onHeader),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Every mailbox you have been granted, on every device.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: brand.onHeaderMuted),
                  ),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerSignInCard extends StatelessWidget {
  const _ServerSignInCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sign in to SokoMail', style: context.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Use your SokoAerial Robotics account.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              const AppTextField(
                label: 'Work email',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: [AutofillHints.email],
                enabled: false,
              ),
              const SizedBox(height: 12),
              const AppTextField(
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                autofillHints: [AutofillHints.password],
                enabled: false,
              ),
              const SizedBox(height: 18),
              const AppButton(
                label: 'Sign in',
                icon: Icons.login_rounded,
                onPressed: null,
                expand: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Server sign-in becomes available when the SokoMail API is '
                'connected.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevelopmentSessionCard extends StatelessWidget {
  const _DevelopmentSessionCard({required this.onContinue});

  final ValueChanged<UserRole> onContinue;

  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: status.warning, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: context.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Development session',
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Local development only. Not authenticated by a server, uses '
              'sample data, and is excluded from release builds.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Continue as employee',
              icon: Icons.person_outline_rounded,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => onContinue(UserRole.employee),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Continue as administrator',
              icon: Icons.admin_panel_settings_outlined,
              variant: AppButtonVariant.tertiary,
              expand: true,
              onPressed: () => onContinue(UserRole.admin),
            ),
          ],
        ),
      ),
    );
  }
}
