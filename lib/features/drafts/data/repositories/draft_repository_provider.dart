import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/drafts/data/repositories/dev_mock_draft_repository.dart';
import 'package:sokomail/features/drafts/domain/repositories/draft_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';

/// Binds [DraftRepository]. Development builds save into the local demo
/// store; other builds fail with [FeatureUnavailableFailure] until the
/// API-backed implementation exists.
final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  if (AppConfig.developmentToolsCompiledIn &&
      ref.watch(appConfigProvider).useDevelopmentFixtures) {
    return DevMockDraftRepository(ref.watch(devMailStoreProvider));
  }
  throw const FeatureUnavailableFailure(
    debugMessage: 'DraftRepository has no API implementation yet.',
  );
});
