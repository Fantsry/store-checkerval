import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_login_result.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  /// Completes authentication with tokens obtained from Riot login WebView or direct auth.
  Future<Result<AuthSession>> loginWithTokens({
    required String accessToken,
    required String idToken,
    required String cookieJar,
  });

  /// Direct credentials login with automatic 2FA detection.
  Future<Result<AuthLoginResult>> loginWithCredentials({
    required String username,
    required String password,
  });

  /// Completes login by verifying 2FA multi-factor authentication code.
  Future<Result<AuthSession>> submit2FaCode({
    required String code,
    required String sessionCookies,
  });

  /// Checks if user approved sign-in via Riot Mobile push notification.
  Future<Result<AuthSession?>> checkMfaStatus({
    required String sessionCookies,
  });

  /// Silent re-authentication using saved session cookies.
  Future<Result<AuthSession>> silentReauth();

  /// Logs out and clears stored credentials.
  Future<Result<void>> logout();

  /// Checks if a valid session exists in secure storage.
  Future<bool> isLoggedIn();

  /// Returns cached session from secure storage if available.
  Future<AuthSession?> getCachedSession();

  /// Gets cached or fetches newest Valorant client version.
  Future<Result<String>> getClientVersion();
}
