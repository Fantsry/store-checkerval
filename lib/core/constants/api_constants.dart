/// API constants — Riot Games endpoints.
///
/// Base URLs should be overridden via --dart-define-from-file for production.
/// These defaults are for development convenience only.

class ApiConstants {
  ApiConstants._();

  // ─── Riot Auth ───────────────────────────────────────────────
  static const String riotAuthBaseUrl = 'https://auth.riotgames.com';
  static const String riotAuthAuthorize = '$riotAuthBaseUrl/authorize';
  static const String riotAuthToken = '$riotAuthBaseUrl/api/v1/authorization';
  static const String riotEntitlementsUrl =
      'https://entitlements.auth.riotgames.com/api/token/v1';
  static const String riotUserInfoUrl =
      'https://auth.riotgames.com/userinfo';

  // ─── PAS Geo (Region/Shard Detection) ───────────────────────
  static const String pasGeoUrl =
      'https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant';

  // ─── Valorant Store (per-shard) ─────────────────────────────
  static String storeBaseUrl(String shard) =>
      'https://pd.$shard.a.pvp.net';

  static String storefrontUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/store/v2/storefront/$puuid';

  static String storefrontV3Url(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/store/v3/storefront/$puuid';

  static String walletUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/store/v1/wallet/$puuid';

  static String ownedItemsUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/store/v1/entitlements/$puuid';

  // ─── Player Identity & Personalization ───────────────────────
  static String nameServiceUrl(String shard) =>
      '${storeBaseUrl(shard)}/name-service/v2/players';

  static String playerLoadoutUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/personalization/v2/players/$puuid/playerloadout';

  static String accountXpUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/account-xp/v1/players/$puuid';

  static String playerCardUrl(String cardUuid) =>
      '$valorantApiBaseUrl/playercards/$cardUuid';

  static String playerTitleUrl(String titleUuid) =>
      '$valorantApiBaseUrl/playertitles/$titleUuid';

  // ─── Match History & Details (Riot PVP) ──────────────────────
  static String matchHistoryUrl(
    String shard,
    String puuid, {
    int startIndex = 0,
    int endIndex = 15,
    String? queue,
  }) =>
      '${storeBaseUrl(shard)}/match-history/v1/history/$puuid?startIndex=$startIndex&endIndex=$endIndex${queue != null ? '&queue=$queue' : ''}';

  static String matchDetailsUrl(String shard, String matchId) =>
      '${storeBaseUrl(shard)}/match-details/v1/matches/$matchId';

  static String competitiveUpdatesUrl(
    String shard,
    String puuid, {
    int startIndex = 0,
    int endIndex = 15,
  }) =>
      '${storeBaseUrl(shard)}/mmr/v1/players/$puuid/competitiveupdates?startIndex=$startIndex&endIndex=$endIndex';

  static String playerMmrUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/mmr/v1/players/$puuid';

  // ─── Inventory / Entitlements & Contracts (Riot PVP) ─────────
  static const String weaponSkinItemTypeId =
      'e7c633d8-b96c-4863-8406-3f1ee677b945';

  static String entitlementsUrl(
    String shard,
    String puuid, {
    String itemTypeId = weaponSkinItemTypeId,
  }) =>
      '${storeBaseUrl(shard)}/store/v1/entitlements/$puuid/$itemTypeId';

  static String contractsUrl(String shard, String puuid) =>
      '${storeBaseUrl(shard)}/contract-service/v1/contracts/$puuid';

  // ─── Live Game / GLZ Endpoints (Pre-Game & Core-Game) ───────
  static String glzBaseUrl(String region, String shard) {
    final r = region.toLowerCase().trim();
    final s = shard.toLowerCase().trim();
    final effectiveRegion = r.isNotEmpty ? r : (s.isNotEmpty ? s : 'ap');
    final effectiveShard = s.isNotEmpty ? s : 'ap';
    return 'https://glz-$effectiveRegion-1.$effectiveShard.a.pvp.net';
  }

  static String preGamePlayerUrl(String region, String shard, String puuid) =>
      '${glzBaseUrl(region, shard)}/pregame/v1/players/$puuid';

  static String preGameMatchUrl(String region, String shard, String matchId) =>
      '${glzBaseUrl(region, shard)}/pregame/v1/matches/$matchId';

  static String coreGamePlayerUrl(String region, String shard, String puuid) =>
      '${glzBaseUrl(region, shard)}/core-game/v1/players/$puuid';

  static String coreGameMatchUrl(String region, String shard, String matchId) =>
      '${glzBaseUrl(region, shard)}/core-game/v1/matches/$matchId';

  // ─── Valorant API (Community — Skin & Game metadata) ─────────
  static const String valorantApiBaseUrl = 'https://valorant-api.com/v1';
  static const String valorantApiVersion = '$valorantApiBaseUrl/version';
  static const String valorantApiWeapons = '$valorantApiBaseUrl/weapons';
  static const String valorantApiWeaponSkins =
      '$valorantApiBaseUrl/weapons/skins';
  static const String valorantApiWeaponSkinLevels =
      '$valorantApiBaseUrl/weapons/skinlevels';
  static const String valorantApiContentTiers =
      '$valorantApiBaseUrl/contenttiers';
  static const String valorantApiCurrencies =
      '$valorantApiBaseUrl/currencies';
  static const String valorantApiMaps = '$valorantApiBaseUrl/maps';
  static const String valorantApiAgents = '$valorantApiBaseUrl/agents';
  static const String valorantApiCompetitiveTiers =
      '$valorantApiBaseUrl/competitivetiers';
  static const String valorantApiBundles = '$valorantApiBaseUrl/bundles';
  static const String valorantApiBuddies = '$valorantApiBaseUrl/buddies';
  static const String valorantApiSprays = '$valorantApiBaseUrl/sprays';
  static const String valorantApiMissions = '$valorantApiBaseUrl/missions';
  static const String valorantApiContracts = '$valorantApiBaseUrl/contracts';
  static const String valorantApiPlayerCards = '$valorantApiBaseUrl/playercards';

  // ─── Auth OAuth2 Parameters ─────────────────────────────────
  static const String riotClientId = 'play-valorant-web-prod';
  static const String riotResponseType = 'token id_token';
  static const String riotRedirectUri =
      'https://playvalorant.com/opt_in';
  static const String riotScope = 'account openid';
  static const String riotNonce = '1';

  /// Full authorize URL for WebView login.
  static String get authorizeUrl =>
      '$riotAuthAuthorize'
      '?redirect_uri=${Uri.encodeComponent(riotRedirectUri)}'
      '&client_id=$riotClientId'
      '&response_type=${Uri.encodeComponent(riotResponseType)}'
      '&scope=${Uri.encodeComponent(riotScope)}'
      '&nonce=$riotNonce';

  // ─── Timeouts ───────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
}
