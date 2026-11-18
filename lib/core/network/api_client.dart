import 'package:dio/dio.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/core/network/auth_interceptor.dart';
import 'package:sokomail/core/network/dio_failure_mapper.dart';
import 'package:sokomail/core/network/safe_logging_interceptor.dart';
import 'package:sokomail/core/platform/app_platform.dart';
import 'package:sokomail/core/security/access_token_source.dart';

/// Converts decoded JSON (`Map`, `List`, primitives or `null`) into [T].
typedef JsonDecoder<T> = T Function(Object? json);

/// Name of the header identifying the client platform to the Go API.
const clientPlatformHeader = 'X-SokoMail-Client';

/// Builds the [Dio] instance used to talk to the SokoMail Go API.
///
/// [adapter] lets tests replace the HTTP transport so no real network
/// requests are made.
///
/// Throws a [ConfigurationFailure] if `API_BASE_URL` is not configured.
Dio createDio({
  required AppConfig config,
  required AccessTokenSource accessTokens,
  HttpClientAdapter? adapter,
  void Function()? onUnauthorized,
  void Function(String message)? log,
}) {
  final baseUrl = config.apiBaseUrl;
  if (baseUrl == null) {
    throw const ConfigurationFailure(debugMessage: 'API_BASE_URL is not set.');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: {
        Headers.acceptHeader: Headers.jsonContentType,
        clientPlatformHeader: AppPlatform.current.name,
      },
    ),
  );

  if (adapter != null) dio.httpClientAdapter = adapter;

  dio.interceptors.addAll([
    AuthInterceptor(accessTokens: accessTokens, onUnauthorized: onUnauthorized),
    if (config.enableNetworkLogging) SafeLoggingInterceptor(log: log),
  ]);
  return dio;
}

/// Thin, typed wrapper around [Dio] for remote data sources.
///
/// * All failures surface as [AppFailure]s, never as [DioException]s.
/// * Every call accepts a [CancelToken]; providers should cancel it in
///   `ref.onDispose` so requests stop when a screen is closed.
/// * Decoding happens through an explicit [JsonDecoder] that produces DTOs.
///   Mapping DTOs to domain entities is the repository's responsibility.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    required JsonDecoder<T> decode,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      decode,
    );
  }

  Future<T> post<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.post<Object?>(path, data: body, cancelToken: cancelToken),
      decode,
    );
  }

  Future<T> put<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.put<Object?>(path, data: body, cancelToken: cancelToken),
      decode,
    );
  }

  Future<T> delete<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.delete<Object?>(path, data: body, cancelToken: cancelToken),
      decode,
    );
  }

  Future<T> _send<T>(
    Future<Response<Object?>> Function() request,
    JsonDecoder<T> decode,
  ) async {
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (exception) {
      throw mapDioException(exception);
    }

    try {
      return decode(response.data);
    } on FormatException {
      throw const ResponseFormatFailure();
    } on TypeError {
      // A DTO cast failed: the payload does not match the agreed contract.
      throw const ResponseFormatFailure();
    }
  }
}
