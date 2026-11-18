import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/search/data/repositories/dev_mock_mail_search_repository.dart';
import 'package:sokomail/features/search/domain/repositories/mail_search_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';

/// Binds [MailSearchRepository]. Development builds search the local demo
/// store; other builds fail with [FeatureUnavailableFailure] until the
/// API-backed implementation exists.
final mailSearchRepositoryProvider = Provider<MailSearchRepository>((ref) {
  if (AppConfig.developmentToolsCompiledIn &&
      ref.watch(appConfigProvider).useDevelopmentFixtures) {
    return DevMockMailSearchRepository(ref.watch(devMailStoreProvider));
  }
  throw const FeatureUnavailableFailure(
    debugMessage: 'MailSearchRepository has no API implementation yet.',
  );
});
