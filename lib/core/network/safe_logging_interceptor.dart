import 'package:dio/dio.dart';
import 'package:sokomail/core/utils/app_logger.dart';

/// Debug-only request logging that cannot expose secrets.
///
/// Only the HTTP method, URL path, status code and duration are logged.
/// Headers (Authorization, Cookie), query strings (search terms) and bodies
/// (credentials, message content) are never logged.
class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor({void Function(String message)? log})
    : _log = log ?? const AppLogger('network').debug;

  static const _startedAtKey = 'sokomail.requestStartedAt';

  final void Function(String message) _log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    _log('-> ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    _log(
      '<- ${response.statusCode} ${options.method} ${options.uri.path}'
      '${_elapsed(options)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final status = err.response?.statusCode;
    _log(
      'x ${err.type.name}${status == null ? '' : ' $status'} '
      '${options.method} ${options.uri.path}${_elapsed(options)}',
    );
    handler.next(err);
  }

  String _elapsed(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! DateTime) return '';
    return ' (${DateTime.now().difference(startedAt).inMilliseconds}ms)';
  }
}
