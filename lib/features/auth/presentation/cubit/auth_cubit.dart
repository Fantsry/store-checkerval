import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_login_result.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  Timer? _mfaPollTimer;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(const AuthLoading(message: 'Checking session...'));
    final cached = await _authRepository.getCachedSession();
    if (cached != null) {
      // Emit authenticated with cached data first for instant UI
      emit(AuthAuthenticated(cached));
      // Then verify / refresh silently
      final refreshResult = await _authRepository.silentReauth();
      refreshResult.when(
        success: (session) => emit(AuthAuthenticated(session)),
        failure: (failure) {
          // If silent reauth fails due to invalid session, unauthenticate
          if (failure.statusCode == 401) {
            emit(AuthUnauthenticated(message: failure.message));
          }
        },
      );
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading(message: 'Authenticating with Riot Games...'));
    final result = await _authRepository.loginWithCredentials(
      username: username,
      password: password,
    );

    result.when(
      success: (loginResult) {
        if (loginResult is AuthLoginSuccess) {
          emit(AuthAuthenticated(loginResult.session));
        } else if (loginResult is AuthLogin2FaRequired) {
          _startMfaPolling(loginResult.sessionCookies);
          emit(
            Auth2FaRequired(
              email: loginResult.email,
              method: loginResult.method,
              sessionCookies: loginResult.sessionCookies,
            ),
          );
        }
      },
      failure: (failure) => emit(AuthError(failure.message)),
    );
  }

  void _startMfaPolling(String initialSessionCookies) {
    _mfaPollTimer?.cancel();
    String currentCookies = initialSessionCookies;

    _mfaPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (state is! Auth2FaRequired) {
        timer.cancel();
        return;
      }

      final result = await _authRepository.checkMfaStatus(
        sessionCookies: currentCookies,
      );

      result.when(
        success: (session) {
          if (session != null) {
            timer.cancel();
            emit(AuthAuthenticated(session));
          }
        },
        failure: (_) {},
      );

      // Read updated cookies from storage for next poll iteration.
      // The repository saves updated cookies from each MFA poll response.
      if (state is Auth2FaRequired) {
        final cached = await _authRepository.getCachedSession();
        if (cached != null && cached.cookieJar.isNotEmpty) {
          currentCookies = cached.cookieJar;
        }
      }
    });

    // Timeout polling after 5 minutes and inform the user
    Future.delayed(const Duration(minutes: 5), () {
      if (_mfaPollTimer?.isActive == true) {
        _mfaPollTimer?.cancel();
        if (state is Auth2FaRequired) {
          emit(const AuthError(
            'MFA approval timed out. Please try signing in again.',
          ));
        }
      }
    });
  }

  void cancelMfaPolling() {
    _mfaPollTimer?.cancel();
  }

  Future<void> submit2FaCode({
    required String code,
    required String sessionCookies,
  }) async {
    cancelMfaPolling();
    emit(const AuthLoading(message: 'Verifying 2FA security code...'));
    final result = await _authRepository.submit2FaCode(
      code: code,
      sessionCookies: sessionCookies,
    );

    result.when(
      success: (session) => emit(AuthAuthenticated(session)),
      failure: (failure) => emit(AuthError(failure.message)),
    );
  }

  Future<void> loginWithTokens({
    required String accessToken,
    required String idToken,
    required String cookieJar,
  }) async {
    cancelMfaPolling();
    emit(const AuthLoading(message: 'Connecting to Riot services...'));
    final result = await _authRepository.loginWithTokens(
      accessToken: accessToken,
      idToken: idToken,
      cookieJar: cookieJar,
    );

    result.when(
      success: (session) => emit(AuthAuthenticated(session)),
      failure: (failure) => emit(AuthError(failure.message)),
    );
  }

  Future<void> silentReauth() async {
    final result = await _authRepository.silentReauth();
    result.when(
      success: (session) => emit(AuthAuthenticated(session)),
      failure: (failure) => emit(AuthUnauthenticated(message: failure.message)),
    );
  }

  Future<void> logout() async {
    cancelMfaPolling();
    emit(const AuthLoading(message: 'Signing out...'));
    await _authRepository.logout();
    emit(const AuthUnauthenticated(message: 'Logged out successfully'));
  }

  @override
  Future<void> close() {
    _mfaPollTimer?.cancel();
    return super.close();
  }
}
