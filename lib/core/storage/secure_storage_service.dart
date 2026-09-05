/// Secure storage service — wrapper around [FlutterSecureStorage].
///
/// Stores tokens, cookies, and session data in platform Keystore/Keychain.
/// Each piece of data is stored per-key for easy partial invalidation.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  // ─── Keys ───────────────────────────────────────────────────
  static const _keyAccessToken = 'riot_access_token';
  static const _keyIdToken = 'riot_id_token';
  static const _keyEntitlementsToken = 'riot_entitlements_token';
  static const _keyPuuid = 'riot_puuid';
  static const _keySsidCookie = 'riot_ssid_cookie';
  static const _keyCookieJar = 'riot_cookie_jar';
  static const _keyShard = 'riot_shard';
  static const _keyRegion = 'riot_region';
  static const _keyClientVersion = 'valorant_client_version';
  static const _keyClientVersionTimestamp = 'valorant_client_version_ts';
  static const _keyBiometricEnabled = 'biometric_enabled';

  // ─── Access Token ───────────────────────────────────────────
  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  // ─── ID Token ───────────────────────────────────────────────
  Future<String?> getIdToken() => _storage.read(key: _keyIdToken);

  Future<void> setIdToken(String token) =>
      _storage.write(key: _keyIdToken, value: token);

  // ─── Entitlements Token ─────────────────────────────────────
  Future<String?> getEntitlementsToken() =>
      _storage.read(key: _keyEntitlementsToken);

  Future<void> setEntitlementsToken(String token) =>
      _storage.write(key: _keyEntitlementsToken, value: token);

  // ─── PUUID ──────────────────────────────────────────────────
  Future<String?> getPuuid() => _storage.read(key: _keyPuuid);

  Future<void> setPuuid(String puuid) =>
      _storage.write(key: _keyPuuid, value: puuid);

  // ─── SSID Cookie ────────────────────────────────────────────
  Future<String?> getSsidCookie() => _storage.read(key: _keySsidCookie);

  Future<void> setSsidCookie(String cookie) =>
      _storage.write(key: _keySsidCookie, value: cookie);

  // ─── Full Cookie Jar (JSON-encoded) ─────────────────────────
  Future<String?> getCookieJar() => _storage.read(key: _keyCookieJar);

  Future<void> setCookieJar(String cookieJarJson) =>
      _storage.write(key: _keyCookieJar, value: cookieJarJson);

  // ─── Shard & Region ─────────────────────────────────────────
  Future<String?> getShard() => _storage.read(key: _keyShard);

  Future<void> setShard(String shard) =>
      _storage.write(key: _keyShard, value: shard);

  Future<String?> getRegion() => _storage.read(key: _keyRegion);

  Future<void> setRegion(String region) =>
      _storage.write(key: _keyRegion, value: region);

  // ─── Client Version ─────────────────────────────────────────
  Future<String?> getClientVersion() =>
      _storage.read(key: _keyClientVersion);

  Future<void> setClientVersion(String version) =>
      _storage.write(key: _keyClientVersion, value: version);

  Future<String?> getClientVersionTimestamp() =>
      _storage.read(key: _keyClientVersionTimestamp);

  Future<void> setClientVersionTimestamp(String timestamp) =>
      _storage.write(key: _keyClientVersionTimestamp, value: timestamp);

  // ─── Biometric ──────────────────────────────────────────────
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _keyBiometricEnabled, value: enabled.toString());

  // ─── Clear Operations ───────────────────────────────────────
  /// Clear only tokens (keep cookies for reauth attempt).
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyIdToken),
      _storage.delete(key: _keyEntitlementsToken),
    ]);
  }

  /// Clear everything (full logout).
  Future<void> clearAll() => _storage.deleteAll();

  /// Check if user has a stored session.
  Future<bool> hasSession() async {
    final puuid = await getPuuid();
    final accessToken = await getAccessToken();
    return puuid != null &&
        puuid.isNotEmpty &&
        accessToken != null &&
        accessToken.isNotEmpty;
  }
}
