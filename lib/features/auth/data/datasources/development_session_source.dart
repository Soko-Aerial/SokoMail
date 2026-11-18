// =============================================================================
// DEVELOPMENT ONLY - NOT AUTHENTICATION.
//
// Creates a local user so that navigation can be exercised before the
// SokoMail Go API exists. No credentials are checked and no server is
// contacted. Callers must check `AppConfig.allowDevelopmentSession`, which is
// always false in release builds.
// =============================================================================

import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/shared/dev/dev_sample_data.dart';

class DevelopmentSessionSource {
  const DevelopmentSessionSource();

  AppUser createUser(UserRole role) {
    return AppUser(
      id: 'dev-user-${role.name}',
      email: 'dev.employee@example.com',
      displayName: role == UserRole.admin
          ? 'Development Administrator'
          : 'Development Employee',
      role: role,
      primaryMailboxId: DevSampleData.personalMailboxId,
    );
  }
}
