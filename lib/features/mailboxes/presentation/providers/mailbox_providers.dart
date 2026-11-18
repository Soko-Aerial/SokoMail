import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/features/mailboxes/data/repositories/mailbox_repository_provider.dart';
import 'package:sokomail/features/mailboxes/domain/entities/mailbox.dart';

/// Mailboxes the signed-in employee can access.
///
/// Auto-disposed: the list is discarded when the signed-in shell unmounts
/// (for example on sign-out), so it is never reused across sessions.
final accessibleMailboxesProvider = FutureProvider.autoDispose<List<Mailbox>>(
  (ref) => ref.watch(mailboxRepositoryProvider).getAccessibleMailboxes(),
);
