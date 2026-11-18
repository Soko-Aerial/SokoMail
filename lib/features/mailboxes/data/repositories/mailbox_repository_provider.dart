import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/mailboxes/data/repositories/dev_mock_mailbox_repository.dart';
import 'package:sokomail/features/mailboxes/domain/repositories/mailbox_repository.dart';

/// Binds [MailboxRepository] to an implementation.
///
/// Phase 1 only has the development mock. The API-backed implementation is
/// added in the mailbox milestone; until then non-development builds fail
/// with a [FeatureUnavailableFailure] instead of showing invented data.
final mailboxRepositoryProvider = Provider<MailboxRepository>((ref) {
  if (AppConfig.developmentToolsCompiledIn &&
      ref.watch(appConfigProvider).useDevelopmentFixtures) {
    return const DevMockMailboxRepository();
  }
  throw const FeatureUnavailableFailure(
    debugMessage: 'MailboxRepository has no API implementation yet.',
  );
});
