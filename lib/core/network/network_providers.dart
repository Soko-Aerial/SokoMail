import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/network/api_client.dart';
import 'package:sokomail/core/security/access_token_source.dart';

/// The configured [Dio] instance. Only remote data sources may use it,
/// through [apiClientProvider]; UI code must never read this provider.
///
/// Phase 1 makes no network requests, so nothing reads it yet. Reading it
/// without `API_BASE_URL` throws a `ConfigurationFailure`.
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(
    config: ref.watch(appConfigProvider),
    accessTokens: ref.watch(accessTokenSourceProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
