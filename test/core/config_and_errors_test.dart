import 'package:flutter_test/flutter_test.dart';
import 'package:sokomail/core/config/app_config.dart';
import 'package:sokomail/core/errors/app_failure.dart';
import 'package:sokomail/core/errors/provider_retry_policy.dart';

void main() {
  group('AppConfig', () {
    test('defaults without dart-defines', () {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.development);
      expect(config.apiBaseUrl, isNull);
      // Tests run in debug mode, where development fixtures are compiled in.
      expect(config.useDevelopmentFixtures, isTrue);
      expect(config.allowDevelopmentSession, isTrue);
    });

    test('parses environments', () {
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
      expect(AppEnvironment.parse(' Production '), AppEnvironment.production);
      expect(() => AppEnvironment.parse('qa'), throwsFormatException);
    });

    test('validates API_BASE_URL', () {
      Uri? parse(String raw, {bool requireHttps = false}) =>
          AppConfig.parseApiBaseUrl(raw, requireHttps: requireHttps);

      expect(parse(''), isNull);
      expect(
        parse('https://api.example.com'),
        Uri.parse('https://api.example.com'),
      );
      expect(parse('http://localhost:8080'), isNotNull);
      expect(
        () => parse('http://api.example.com', requireHttps: true),
        throwsFormatException,
      );
      expect(() => parse('/relative'), throwsFormatException);
      expect(() => parse('ftp://example.com'), throwsFormatException);
    });
  });

  group('AppFailure', () {
    test('unknown errors become a generic failure', () {
      expect(AppFailure.from(StateError('boom')), isA<UnexpectedFailure>());
      expect(AppFailure.from(const NotFoundFailure()), isA<NotFoundFailure>());
    });

    test('toString never includes debug details', () {
      const failure = ServerFailure(debugMessage: 'GET /secret');
      expect(failure.toString(), 'ServerFailure');
    });
  });

  group('providerRetryPolicy', () {
    test('retries transient failures with backoff', () {
      expect(
        providerRetryPolicy(0, const NetworkFailure()),
        const Duration(milliseconds: 400),
      );
      expect(
        providerRetryPolicy(2, const TimeoutFailure()),
        const Duration(milliseconds: 1600),
      );
      expect(providerRetryPolicy(1, const ServerFailure()), isNotNull);
    });

    test('gives up after three attempts', () {
      expect(providerRetryPolicy(3, const NetworkFailure()), isNull);
    });

    test('never retries non-transient failures', () {
      expect(providerRetryPolicy(0, const UnauthorizedFailure()), isNull);
      expect(providerRetryPolicy(0, const ForbiddenFailure()), isNull);
      expect(providerRetryPolicy(0, const FeatureUnavailableFailure()), isNull);
      expect(providerRetryPolicy(0, StateError('bug')), isNull);
    });
  });
}
