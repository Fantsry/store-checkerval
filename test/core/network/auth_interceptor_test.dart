import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/network/auth_interceptor.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  late MockSecureStorageService mockStorage;
  late AuthInterceptor interceptor;

  // Helper to create a fake JWT with a specific expiration timestamp
  String createFakeJwt({required int expSecondsFromNow}) {
    final header = base64Url
        .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final exp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expSecondsFromNow;
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'exp': exp, 'sub': 'user-123'})));
    return '$header.$payload.fakeSignature';
  }

  setUp(() {
    mockStorage = MockSecureStorageService();
    interceptor = AuthInterceptor(storage: mockStorage);
  });

  group('AuthInterceptor', () {
    test('skips auth headers for valorant-api.com', () async {
      final options = RequestOptions(
        path: 'https://valorant-api.com/v1/weapons',
      );
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('attaches Bearer and Entitlements tokens for Riot endpoints', () async {
      final validToken = createFakeJwt(expSecondsFromNow: 3600);
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => validToken);
      when(() => mockStorage.getEntitlementsToken())
          .thenAnswer((_) async => validToken);
      when(() => mockStorage.getClientVersion())
          .thenAnswer((_) async => 'release-10.0');

      final options = RequestOptions(
        path: 'https://glz-ap-1.ap.a.pvp.net/core-game/v1/players/user-123',
      );
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer $validToken'));
      expect(options.headers['X-Riot-Entitlements-JWT'], equals(validToken));
      expect(options.headers['X-Riot-ClientVersion'], equals('release-10.0'));
      expect(options.headers.containsKey('X-Riot-ClientPlatform'), isTrue);
      verify(() => handler.next(options)).called(1);
    });

    test('onError passes through non-auth errors without retrying', () async {
      final options = RequestOptions(path: 'https://glz-ap-1.ap.a.pvp.net/test');
      final dioErr = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
        ),
      );

      final handler = MockErrorInterceptorHandler();

      await interceptor.onError(dioErr, handler);

      expect(options.extra['authRetried'], isNull);
      verify(() => handler.next(dioErr)).called(1);
    });

    test('recognizes GLZ 400 BAD_CLAIMS and marks retry flag', () async {
      final options = RequestOptions(path: 'https://glz-ap-1.ap.a.pvp.net/core-game/v1/players/123');
      final dioErr = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {
            'httpStatus': 400,
            'errorCode': 'BAD_CLAIMS',
            'message': 'Failure validating/decoding RSO Access Token',
          },
        ),
      );

      // When cookieJar is empty, silent reauth returns false
      when(() => mockStorage.getCookieJar()).thenAnswer((_) async => null);

      final handler = MockErrorInterceptorHandler();

      await interceptor.onError(dioErr, handler);

      // Should have attempted retry and marked authRetried
      expect(options.extra['authRetried'], isTrue);
      verify(() => handler.next(dioErr)).called(1);
    });
  });
}
