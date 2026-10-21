import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/riot_store_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/valorant_api_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/store_widget_service.dart';
import 'package:valorant_store_tracker/features/daily_store/data/storefront_alert_parser.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/social/data/datasources/riot_chat_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';

const String dailyStoreCheckTaskKey = 'com.valorantstore.daily_check_task';
const String dailyStoreResetTaskKey = 'com.valorantstore.daily_reset_task';
const String chatCheckTaskKey = 'com.valorantstore.chat_check_task';

const String periodicStoreCheckTaskTag = 'valorant_store_periodic';
const String resetStoreCheckTaskTag = 'valorant_store_reset_target';
const String periodicChatCheckTaskTag = 'valorant_chat_periodic';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[Workmanager] Executing background task: $task');

    try {
      if (task == chatCheckTaskKey) {
        return await BackgroundTaskManager.executeChatCheck();
      }

      final success = await BackgroundTaskManager.executeStoreCheck(
        deduplicate: true,
      );

      // Always schedule the next targeted reset check for 00:00 UTC tomorrow
      await BackgroundTaskManager.scheduleNextResetCheck();

      return success;
    } catch (e, stack) {
      debugPrint('[Workmanager] Background task error: $e\n$stack');
      return true;
    }
  });
}

class BackgroundTaskManager {
  static String? _extractPuuidFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      return payload['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Core logic to fetch store and evaluate alerts/wishlist.
  /// Reused by both background worker and manual diagnostic trigger.
  static Future<bool> executeStoreCheck({bool deduplicate = true}) async {
    final secureStorage = SecureStorageService();
    final localStore = LocalStoreService();
    await localStore.init();

    var puuid = await secureStorage.getPuuid();
    final shard = await secureStorage.getShard() ?? 'ap';
    final cookieJar = await secureStorage.getCookieJar();

    var accessToken = await secureStorage.getAccessToken();

    // Recover PUUID from access token JWT if missing
    if ((puuid == null || puuid.isEmpty) &&
        accessToken != null &&
        accessToken.isNotEmpty) {
      final extracted = _extractPuuidFromJwt(accessToken);
      if (extracted != null && extracted.isNotEmpty) {
        puuid = extracted;
        await secureStorage.setPuuid(puuid);
      }
    }

    if (puuid == null || puuid.isEmpty) {
      debugPrint(
        '[BackgroundTaskManager] No PUUID found. Aborting store check.',
      );
      return true;
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    final authRemote = AuthRemoteDataSourceImpl(dio: dio);

    // Silent reauth if cookieJar is available
    if (cookieJar != null && cookieJar.isNotEmpty) {
      try {
        final reauthTokens = await authRemote.reauthorizeSilent(cookieJar);
        final newAccessToken = reauthTokens['access_token'];
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          accessToken = newAccessToken;
          await secureStorage.setAccessToken(accessToken);

          final idToken = reauthTokens['id_token'];
          if (idToken != null) await secureStorage.setIdToken(idToken);

          final entToken = await authRemote.getEntitlementsToken(accessToken);
          await secureStorage.setEntitlementsToken(entToken);
        }
      } catch (e) {
        debugPrint('[BackgroundTaskManager] Silent reauth warning: $e');
        accessToken ??= await secureStorage.getAccessToken();
      }
    }

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('[BackgroundTaskManager] No valid access token. Aborting.');
      return true;
    }

    var entitlementsToken = await secureStorage.getEntitlementsToken();
    if (entitlementsToken == null || entitlementsToken.isEmpty) {
      try {
        entitlementsToken = await authRemote.getEntitlementsToken(accessToken);
        await secureStorage.setEntitlementsToken(entitlementsToken);
      } catch (_) {}
    }

    var clientVersion = await secureStorage.getClientVersion();
    if (clientVersion == null || clientVersion.isEmpty) {
      try {
        clientVersion = await authRemote.getClientVersion();
        await secureStorage.setClientVersion(clientVersion);
      } catch (_) {
        clientVersion = 'release-13.08-shipping-14-5627607';
      }
    }

    // Setup dio with Riot headers
    final riotDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementsToken ?? '',
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform':
              'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVua25vd24iDQp9',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final riotRemote = RiotStoreRemoteDataSourceImpl(dio: riotDio);
    final storefront = await riotRemote.getStorefront(
      shard: shard,
      puuid: puuid,
    );

    final skinsPanel =
        storefront['SkinsPanelLayout'] as Map<String, dynamic>? ?? {};
    final offerUuids = (skinsPanel['SingleItemOffers'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    var allSkins = await localStore.getCachedSkins() ?? [];
    if (allSkins.isEmpty) {
      // Fallback fetch catalog skins from valorant-api
      try {
        final valApiResponse = await dio.get(
          'https://valorant-api.com/v1/weapons/skins',
        );
        if (valApiResponse.statusCode == 200 && valApiResponse.data is Map) {
          final data = valApiResponse.data['data'] as List?;
          if (data != null) {
            allSkins = data
                .whereType<Map<String, dynamic>>()
                .map((j) => SkinItem.fromJson(j))
                .toList();
            await localStore.saveCachedSkins(allSkins);
          }
        }
      } catch (_) {}
    }

    final skinMap = {for (var s in allSkins) s.uuid.toLowerCase(): s};
    final levelToSkinMap = <String, SkinItem>{};
    for (final s in allSkins) {
      for (final lvl in s.levels) {
        levelToSkinMap[lvl.uuid.toLowerCase()] = s;
      }
    }

    final storeOffers =
        skinsPanel['SingleItemStoreOffers'] as List<dynamic>? ?? [];

    final dailySkins = <SkinItem>[];
    for (final offerUuid in offerUuids) {
      SkinItem? matched = skinMap[offerUuid] ?? levelToSkinMap[offerUuid];
      if (matched == null) {
        for (final o in storeOffers) {
          if (o is Map && o['OfferID']?.toString().toLowerCase() == offerUuid) {
            final rewards = o['Rewards'] as List?;
            if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
              final rId = rewards.first['ItemID']?.toString().toLowerCase();
              if (rId != null) {
                matched = skinMap[rId] ?? levelToSkinMap[rId];
                break;
              }
            }
          }
        }
      }
      if (matched != null) dailySkins.add(matched);
    }

    final remainingSecs =
        (skinsPanel['SingleItemOffersRemainingDurationInSeconds'] as num?)
            ?.toInt() ??
        86400;

    var accessoryMetadata = <String, Map<String, dynamic>>{};
    try {
      accessoryMetadata = await ValorantApiRemoteDataSourceImpl(
        dio: dio,
      ).getAccessoriesMetadata();
    } catch (_) {}

    final sections = parseStorefrontAlertSections(
      storefront: storefront,
      skinMap: skinMap,
      levelToSkinMap: levelToSkinMap,
      accessoryMetadata: accessoryMetadata,
    );

    // Keep cached sections only when Riot omitted them from this response.
    final existingStore = await localStore.getCachedDailyStore(puuid: puuid);
    final dailyStore = DailyStore(
      featuredOffers: dailySkins,
      remainingDurationSeconds: remainingSecs,
      bundles: existingStore?.bundles ?? const [],
      accessoryOffers: sections.hasAccessorySection
          ? sections.accessoryOffers
          : (existingStore?.accessoryOffers ?? const []),
      nightMarket: sections.hasNightMarketSection
          ? sections.nightMarket
          : existingStore?.nightMarket,
      lastFetched: DateTime.now(),
    );

    // Save to daily store cache
    await localStore.saveDailyStore(dailyStore, puuid: puuid);
    await StoreWidgetService().update(dailyStore);

    // Check both Wishlist and Custom Alert Rules
    final wishlist = await localStore.getWishlist();
    final alertRules = await localStore.getAlertRules();

    final notificationsEnabled = await secureStorage.areNotificationsEnabled();
    if (notificationsEnabled) {
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.evaluateStoreOffers(
        store: dailyStore,
        wishlist: wishlist,
        alertRules: alertRules,
        localStore: localStore,
        deduplicate: deduplicate,
        notificationsEnabled: notificationsEnabled,
        nightMarketAlertsEnabled: await localStore
            .areNightMarketAlertsEnabled(),
        accessoryAlertsEnabled: await localStore.areAccessoryAlertsEnabled(),
      );
    }

    return true;
  }

  /// Best-effort chat poll. XMPP is intentionally short-lived; WorkManager
  /// decides when this can run and the OS may delay it.
  static Future<bool> executeChatCheck() async {
    final secureStorage = SecureStorageService();
    final localStore = LocalStoreService();
    await localStore.init();

    if (!await localStore.areChatAlertsEnabled()) return true;
    if (!await secureStorage.areNotificationsEnabled()) return true;

    final accessToken = await secureStorage.getAccessToken();
    final selfPuuid = await secureStorage.getPuuid() ?? '';
    if (accessToken == null || accessToken.isEmpty) return true;

    final entitlementToken = await secureStorage.getEntitlementsToken();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );
    final chatDataSource = RiotChatRemoteDataSource(dio: dio);
    final socialData = await chatDataSource.fetchRemoteSocialData(
      accessToken: accessToken,
      entitlementToken: entitlementToken,
    );
    if (socialData.messages.isEmpty) return true;

    for (final message in socialData.messages) {
      if (message.senderPuuid == selfPuuid) continue;
      await localStore.saveChatMessage(
        message.senderPuuid,
        ChatMessageEntity(
          id: message.id,
          body: message.body,
          timestamp: message.timestamp,
          isMine: false,
          status: ChatMessageStatus.sent,
        ),
      );
    }

    final previous = await localStore.getLastNotifiedChatAt(selfPuuid);
    final newest = socialData.messages.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );

    if (previous == null) {
      await localStore.setLastNotifiedChatAt(selfPuuid, DateTime.now());
      return true;
    }

    final fresh =
        socialData.messages
            .where(
              (message) =>
                  message.senderPuuid != selfPuuid &&
                  message.timestamp.isAfter(previous),
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (fresh.isEmpty) return true;

    final latest = fresh.first;
    var senderName = 'Teman Riot';
    for (final friend in socialData.roster) {
      if (friend.puuid == latest.senderPuuid && friend.name.isNotEmpty) {
        senderName = friend.name;
        break;
      }
    }
    if (senderName == 'Teman Riot') {
      for (final raw in await localStore.getSavedFriendsJson()) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['puuid']?.toString() == latest.senderPuuid) {
            final name = map['gameName']?.toString() ?? '';
            final tag = map['tagLine']?.toString() ?? '';
            senderName = tag.isEmpty ? name : '$name#$tag';
            break;
          }
        } catch (_) {}
      }
    }

    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.showChatNotification(
      senderName: senderName,
      body: latest.body,
      senderPuuid: latest.senderPuuid,
    );
    await localStore.setLastNotifiedChatAt(selfPuuid, newest.timestamp);
    return true;
  }

  static Future<bool> _areNotificationsEnabled() async {
    try {
      return await SecureStorageService().areNotificationsEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Workmanager().initialize(callbackDispatcher);
    } catch (e) {
      debugPrint('Workmanager init error: $e');
    }
  }

  /// Schedules a targeted one-off task specifically for the next 00:00 UTC (07:00 WIB) reset.
  /// Adds a 1-minute buffer (07:01 WIB) to ensure Riot's storefront rotation is live.
  static Future<void> scheduleNextResetCheck() async {
    if (kIsWeb) return;
    if (!await _areNotificationsEnabled()) return;
    try {
      final timeUntilReset = TimezoneHelper.timeUntilReset;
      // 1 minute buffer after 00:00 UTC
      final delay = timeUntilReset + const Duration(minutes: 1);

      debugPrint(
        '[BackgroundTaskManager] Scheduling targeted reset check in: ${delay.inMinutes}m (${TimezoneHelper.formatDuration(delay)})',
      );

      await Workmanager().registerOneOffTask(
        dailyStoreResetTaskKey,
        dailyStoreResetTaskKey,
        tag: resetStoreCheckTaskTag,
        initialDelay: delay,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('[BackgroundTaskManager] Error scheduling reset check: $e');
    }
  }

  /// Registers a periodic background check as a safety net.
  /// Runs without battery-low constraint so it triggers even on lower battery.
  static Future<void> registerPeriodicStoreCheck() async {
    if (kIsWeb) return;
    if (!await _areNotificationsEnabled()) return;
    try {
      await Workmanager().registerPeriodicTask(
        dailyStoreCheckTaskKey,
        dailyStoreCheckTaskKey,
        tag: periodicStoreCheckTaskTag,
        frequency: const Duration(hours: 1),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint('Workmanager registration error: $e');
    }
  }

  static Future<void> registerPeriodicChatCheck() async {
    if (kIsWeb) return;
    if (!await _areNotificationsEnabled()) return;
    final localStore = LocalStoreService();
    await localStore.init();
    if (!await localStore.areChatAlertsEnabled()) return;
    try {
      await Workmanager().registerPeriodicTask(
        chatCheckTaskKey,
        chatCheckTaskKey,
        tag: periodicChatCheckTaskTag,
        frequency: const Duration(minutes: 30),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint('Workmanager chat registration error: $e');
    }
  }

  static Future<void> cancelChatCheck() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByTag(periodicChatCheckTaskTag);
    } catch (e) {
      debugPrint('Workmanager chat cancel error: $e');
    }
  }

  /// Cancels both periodic safety-net and targeted reset tasks.
  static Future<void> cancelStoreCheck() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByTag(periodicStoreCheckTaskTag);
      await Workmanager().cancelByTag(resetStoreCheckTaskTag);
    } catch (e) {
      debugPrint('Workmanager cancel error: $e');
    }
  }

  /// Manually triggers store check immediately (ignoring today's deduplication)
  /// so users can verify background pipeline directly in Settings.
  static Future<bool> triggerImmediateBackgroundCheck() async {
    return await executeStoreCheck(deduplicate: false);
  }
}
