import 'package:dio/dio.dart';
import 'package:sokomail/core/errors/app_failure.dart';

/// Converts a [DioException] into a typed, user-safe [AppFailure].
///
/// Response bodies are deliberately not copied into the failure: server
/// error payloads may echo request data.
AppFailure mapDioException(DioException exception) {
  final debug =
      '${exception.requestOptions.method} '
      '${exception.requestOptions.uri.path}';

  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => TimeoutFailure(debugMessage: debug),
    DioExceptionType.cancel => CancelledFailure(debugMessage: debug),
    DioExceptionType.connectionError => NetworkFailure(debugMessage: debug),
    DioExceptionType.badCertificate => NetworkFailure(
      debugMessage: 'TLS certificate rejected: $debug',
    ),
    DioExceptionType.badResponse => mapStatusCode(
      exception.response?.statusCode,
      debugMessage: debug,
    ),
    DioExceptionType.unknown => switch (exception.error) {
      final AppFailure failure => failure,
      _ => UnexpectedFailure(debugMessage: debug),
    },
  };
}

/// Maps an HTTP status code to an [AppFailure].
AppFailure mapStatusCode(int? statusCode, {String? debugMessage}) {
  return switch (statusCode) {
    401 => UnauthorizedFailure(debugMessage: debugMessage),
    403 => ForbiddenFailure(debugMessage: debugMessage),
    404 => NotFoundFailure(debugMessage: debugMessage),
    408 || 504 => TimeoutFailure(debugMessage: debugMessage),
    final int code when code >= 500 => ServerFailure(
      statusCode: code,
      debugMessage: debugMessage,
    ),
    final int code when code >= 400 => InvalidRequestFailure(
      statusCode: code,
      debugMessage: debugMessage,
    ),
    _ => UnexpectedFailure(debugMessage: debugMessage),
  };
}
