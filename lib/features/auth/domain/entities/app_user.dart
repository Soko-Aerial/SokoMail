import 'package:flutter/foundation.dart';

/// Application role. The Go API is the authority for roles; the client only
/// uses them to decide what to *show*. Hiding a screen is not security.
enum UserRole { employee, admin }

/// A signed-in SokoMail employee.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.primaryMailboxId,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;

  /// The mailbox opened after sign-in. `null` if the employee has not been
  /// granted access to any mailbox yet.
  final String? primaryMailboxId;

  bool get isAdmin => role == UserRole.admin;
}
