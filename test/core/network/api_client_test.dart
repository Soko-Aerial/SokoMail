import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/core/network/api_client.dart';
import 'package:sokomail/core/network/auth_interceptor.dart';
import 'package:sokomail/core/security/access_token_source.dart';

/// Transport double: records requests and returns canned responses. No real
/// network traffic is ever produced.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FixedToken implements AccessTokenSource {
  const _FixedToken(this.token);

  final String? token;

  @override
  Future<String?> readAccessToken() async => token;
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

final _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: Uri.parse('https://api.example.test/v1/'),
  useDevelopmentFixtures: false,
);

void main() {
  late _FakeAdapter adapter;
  late ApiClient client;
  late int unauthorizedCalls;

  ApiClient buildClient({
    String? token,
    AppConfig? config,
    void Function(String)? log,
  }) {
    final dio = createDio(
      config: config ?? _config,
      accessTokens: _FixedToken(token),
      adapter: adapter,
      onUnauthorized: () => unauthorizedCalls++,
      log: log,
    );
    return ApiClient(dio);
  }

  setUp(() {
    unauthorizedCalls = 0;
    adapter = _FakeAdapter((_) => _json({'ok': true}));
    client = buildClient();
  });

  test('requires a configured base URL', () {
    expect(
      () => createDio(
        config: const AppConfig(
          environment: AppEnvironment.development,
          apiBaseUrl: null,
          useDevelopmentFixtures: false,
        ),
        accessTokens: const NoAccessTokenSource(),
      ),
      throwsA(isA<ConfigurationFailure>()),
    );
  });

  test('sends standard headers to the configured base URL', () async {
    final result = await client.get(
      'mailboxes',
      decode: (json) => (json! as Map<String, Object?>)['ok']! as bool,
    );

    expect(result, isTrue);
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://api.example.test/v1/mailboxes');
    expect(request.headers[Headers.acceptHeader], Headers.jsonContentType);
    expect(request.headers[clientPlatformHeader], isNotNull);
    expect(request.connectTimeout, _config.connectTimeout);
    expect(request.receiveTimeout, _config.receiveTimeout);
  });

  group('authentication', () {
    test('no Authorization header without a token', () async {
      await client.get('me', decode: (_) => null);
      expect(adapter.requests.single.headers['Authorization'], isNull);
    });

    test('attaches a bearer token when available', () async {
      client = buildClient(token: 'token-123');
      await client.get('me', decode: (_) => null);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer token-123',
      );
    });

    test('requests can opt out of credentials', () async {
      final dio = createDio(
        config: _config,
        accessTokens: const _FixedToken('token-123'),
        adapter: adapter,
      );
      await dio.get<Object?>(
        'login',
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );
      expect(adapter.requests.single.headers['Authorization'], isNull);
    });
  });

  group('error mapping', () {
    final cases = <int, Matcher>{
      400: isA<InvalidRequestFailure>(),
      401: isA<UnauthorizedFailure>(),
      403: isA<ForbiddenFailure>(),
      404: isA<NotFoundFailure>(),
      422: isA<InvalidRequestFailure>(),
      500: isA<ServerFailure>(),
      503: isA<ServerFailure>(),
    };

    for (final MapEntry(key: status, value: matcher) in cases.entries) {
      test('HTTP $status', () async {
        adapter = _FakeAdapter((_) => _json({'error': 'x'}, status: status));
        client = buildClient();
        await expectLater(
          client.get('x', decode: (_) => null),
          throwsA(matcher),
        );
      });
    }

    test('401 notifies the unauthorized hook', () async {
      adapter = _FakeAdapter((_) => _json(null, status: 401));
      client = buildClient();
      await expectLater(
        client.get('x', decode: (_) => null),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(unauthorizedCalls, 1);
    });

    test('timeouts', () async {
      adapter = _FakeAdapter(
        (options) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      );
      client = buildClient();
      await expectLater(
        client.get('x', decode: (_) => null),
        throwsA(isA<TimeoutFailure>()),
      );
    });

    test('connection errors', () async {
      adapter = _FakeAdapter(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
      );
      client = buildClient();
      await expectLater(
        client.get('x', decode: (_) => null),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('cancellation', () async {
      final token = CancelToken()..cancel();
      await expectLater(
        client.get('x', decode: (_) => null, cancelToken: token),
        throwsA(isA<CancelledFailure>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('responses that do not match the expected shape', () async {
      await expectLater(
        client.get('x', decode: (json) => (json! as List<Object?>).length),
        throwsA(isA<ResponseFormatFailure>()),
      );
    });
  });

  test('logging never includes tokens, query strings or bodies', () async {
    final logs = <String>[];
    client = buildClient(
      token: 'secret-token',
      config: AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: Uri.parse('https://api.example.test/v1/'),
        useDevelopmentFixtures: false,
        enableNetworkLogging: true,
      ),
      log: logs.add,
    );

    await client.post(
      'session?search=secret-query',
      body: {'password': 'secret-password'},
      decode: (_) => null,
    );

    expect(logs, isNotEmpty);
    final output = logs.join('\n');
    expect(output, contains('POST /v1/session'));
    expect(output, isNot(contains('secret')));
    expect(output, isNot(contains('Bearer')));
  });
}
