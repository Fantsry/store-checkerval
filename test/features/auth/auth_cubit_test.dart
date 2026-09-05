import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_login_result.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthCubit authCubit;

  const tSession = AuthSession(
    accessToken: 'access_123',
    idToken: 'id_123',
    entitlementsToken: 'ent_123',
    puuid: 'puuid_123',
    shard: 'ap',
    region: 'ap',
    cookieJar: 'ssid=test',
    gameName: 'TestUser',
    tagLine: '0001',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authCubit = AuthCubit(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, equals(const AuthInitial()));
    });

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when no session is cached',
      build: () {
        when(() => mockAuthRepository.getCachedSession())
            .thenAnswer((_) async => null);
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        const AuthLoading(message: 'Checking session...'),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when loginWithTokens succeeds',
      build: () {
        when(() => mockAuthRepository.loginWithTokens(
              accessToken: any(named: 'accessToken'),
              idToken: any(named: 'idToken'),
              cookieJar: any(named: 'cookieJar'),
            )).thenAnswer((_) async => const Result.success(tSession));
        return authCubit;
      },
      act: (cubit) => cubit.loginWithTokens(
        accessToken: 'access_123',
        idToken: 'id_123',
        cookieJar: 'ssid=test',
      ),
      expect: () => [
        const AuthLoading(message: 'Connecting to Riot services...'),
        const AuthAuthenticated(tSession),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Auth2FaRequired] when 2FA is triggered during loginWithCredentials',
      build: () {
        when(() => mockAuthRepository.loginWithCredentials(
              username: any(named: 'username'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Result.success(
              AuthLogin2FaRequired(
                email: 'j***@gmail.com',
                method: 'email',
                sessionCookies: 'asid=123',
              ),
            ));
        return authCubit;
      },
      act: (cubit) => cubit.loginWithCredentials(
        username: 'riot_user',
        password: 'password123',
      ),
      expect: () => [
        const AuthLoading(message: 'Authenticating with Riot Games...'),
        const Auth2FaRequired(
          email: 'j***@gmail.com',
          method: 'email',
          sessionCookies: 'asid=123',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when submit2FaCode succeeds',
      build: () {
        when(() => mockAuthRepository.submit2FaCode(
              code: any(named: 'code'),
              sessionCookies: any(named: 'sessionCookies'),
            )).thenAnswer((_) async => const Result.success(tSession));
        return authCubit;
      },
      act: (cubit) => cubit.submit2FaCode(
        code: '123456',
        sessionCookies: 'asid=123',
      ),
      expect: () => [
        const AuthLoading(message: 'Verifying 2FA security code...'),
        const AuthAuthenticated(tSession),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when submit2FaCode fails',
      build: () {
        when(() => mockAuthRepository.submit2FaCode(
              code: any(named: 'code'),
              sessionCookies: any(named: 'sessionCookies'),
            )).thenAnswer((_) async =>
            const Result.failure(AuthFailure(message: 'Incorrect 2FA code')));
        return authCubit;
      },
      act: (cubit) => cubit.submit2FaCode(
        code: '000000',
        sessionCookies: 'asid=123',
      ),
      expect: () => [
        const AuthLoading(message: 'Verifying 2FA security code...'),
        const AuthError('Incorrect 2FA code'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when loginWithTokens fails',
      build: () {
        when(() => mockAuthRepository.loginWithTokens(
              accessToken: any(named: 'accessToken'),
              idToken: any(named: 'idToken'),
              cookieJar: any(named: 'cookieJar'),
            )).thenAnswer((_) async =>
            const Result.failure(AuthFailure(message: 'Invalid credentials')));
        return authCubit;
      },
      act: (cubit) => cubit.loginWithTokens(
        accessToken: 'bad',
        idToken: 'bad',
        cookieJar: '',
      ),
      expect: () => [
        const AuthLoading(message: 'Connecting to Riot services...'),
        const AuthError('Invalid credentials'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on logout',
      build: () {
        when(() => mockAuthRepository.logout())
            .thenAnswer((_) async => const Result.success(null));
        return authCubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        const AuthLoading(message: 'Signing out...'),
        const AuthUnauthenticated(message: 'Logged out successfully'),
      ],
    );
  });
}
