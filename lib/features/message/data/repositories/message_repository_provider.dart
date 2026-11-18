import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/features/message/data/repositories/dev_mock_message_repository.dart';
import 'package:sokomail/features/message/domain/repositories/message_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';

/// Binds [MessageRepository] to an implementation. Development builds use
/// the local demo store; other builds fail with [FeatureUnavailableFailure]
/// until the API-backed implementation exists.
///
/// This provider is the message feature's public data API: other features
/// (inbox, compose) may use it, but not the classes behind it.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  if (AppConfig.developmentToolsCompiledIn &&
      ref.watch(appConfigProvider).useDevelopmentFixtures) {
    return DevMockMessageRepository(ref.watch(devMailStoreProvider));
  }
  throw const FeatureUnavailableFailure(
    debugMessage: 'MessageRepository has no API implementation yet.',
  );
});
