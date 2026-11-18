import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/inbox/data/repositories/dev_mock_message_list_repository.dart';
import 'package:sokomail/features/inbox/domain/repositories/message_list_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';

/// Binds [MessageListRepository] to an implementation. Development builds
/// use the local demo store; other builds fail with
/// [FeatureUnavailableFailure] until the API-backed implementation exists.
final messageListRepositoryProvider = Provider<MessageListRepository>((ref) {
  if (AppConfig.developmentToolsCompiledIn &&
      ref.watch(appConfigProvider).useDevelopmentFixtures) {
    return DevMockMessageListRepository(ref.watch(devMailStoreProvider));
  }
  throw const FeatureUnavailableFailure(
    debugMessage: 'MessageListRepository has no API implementation yet.',
  );
});
