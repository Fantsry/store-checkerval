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
  static const _keyGameName = 'riot_game_name';
  static const _keyTagLine = 'riot_tag_line';
  static const _keyNotificationPermissionAsked =
      'notification_permission_asked';
  static const _keyNotificationsEnabled = 'notifications_enabled';

  // ─── Game Name & TagLine ────────────────────────────────────
  Future<String?> getGameName() => _storage.read(key: _keyGameName);
  Future<void> setGameName(String gameName) =>
      _storage.write(key: _keyGameName, value: gameName);

  Future<String?> getTagLine() => _storage.read(key: _keyTagLine);
  Future<void> setTagLine(String tagLine) =>
      _storage.write(key: _keyTagLine, value: tagLine);

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

  // ─── Notification Permission ────────────────────────────────
  Future<bool> isNotificationPermissionAsked() async {
    final value = await _storage.read(key: _keyNotificationPermissionAsked);
    return value == 'true';
  }

  Future<void> setNotificationPermissionAsked(bool asked) =>
      _storage.write(
        key: _keyNotificationPermissionAsked,
        value: asked.toString(),
      );

  /// Defaults to true so existing installs keep their scheduled checks.
  Future<bool> areNotificationsEnabled() async {
    final value = await _storage.read(key: _keyNotificationsEnabled);
    return value != 'false';
  }

  Future<void> setNotificationsEnabled(bool enabled) =>
      _storage.write(
        key: _keyNotificationsEnabled,
        value: enabled.toString(),
      );

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
  Future<void> clearAll() async {
    final permissionAsked = await isNotificationPermissionAsked();
    final notificationsEnabled = await areNotificationsEnabled();
    await _storage.deleteAll();
    if (permissionAsked) {
      await setNotificationPermissionAsked(true);
    }
    await setNotificationsEnabled(notificationsEnabled);
  }

  /// Check if user has a stored session (either valid access token or saved cookie jar).
  Future<bool> hasSession() async {
    final puuid = await getPuuid();
    if (puuid == null || puuid.isEmpty) return false;
    final accessToken = await getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) return true;
    final cookieJar = await getCookieJar();
    return cookieJar != null && cookieJar.isNotEmpty;
  }
}
