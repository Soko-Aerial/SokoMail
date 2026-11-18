import 'package:dio/dio.dart';
import 'package:sokomail/core/security/access_token_source.dart';

/// Attaches the session's access token to API requests and reports `401`
/// responses.
///
/// Extension points for the authentication milestone:
/// * [AccessTokenSource] decides where tokens come from (secure storage on
///   mobile; on the web the browser sends HttpOnly cookies instead).
/// * [onUnauthorized] is where token refresh or sign-out will be triggered.
///
/// A [QueuedInterceptor] processes requests one at a time, which prevents
/// several parallel requests from refreshing the same token simultaneously.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this._accessTokens, this.onUnauthorized});

  /// Set `options.extra[AuthInterceptor.skipAuthKey] = true` on requests that
  /// must not carry credentials (for example sign-in itself).
  static const skipAuthKey = 'sokomail.skipAuth';

  final AccessTokenSource _accessTokens;
  final void Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await _accessTokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
