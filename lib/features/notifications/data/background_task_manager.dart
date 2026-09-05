import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/riot_store_remote_datasource.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';

const String dailyStoreCheckTaskKey = 'com.valorantstore.daily_check_task';
const String periodicStoreCheckTaskTag = 'valorant_store_periodic';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final secureStorage = SecureStorageService();
      final localStore = LocalStoreService();
      await localStore.init();

      final puuid = await secureStorage.getPuuid();
      final shard = await secureStorage.getShard() ?? 'ap';
      final cookieJar = await secureStorage.getCookieJar();

      if (puuid == null || cookieJar == null) {
        return Future.value(true);
      }

      // Dio instance for background task
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final authRemote = AuthRemoteDataSourceImpl(dio: dio);

      // 1. Silent reauth
      String? accessToken;
      try {
        final reauthTokens = await authRemote.reauthorizeSilent(cookieJar);
        accessToken = reauthTokens['access_token'];
        if (accessToken != null) {
          await secureStorage.setAccessToken(accessToken);
          final idToken = reauthTokens['id_token'];
          if (idToken != null) await secureStorage.setIdToken(idToken);
          final entToken = await authRemote.getEntitlementsToken(accessToken);
          await secureStorage.setEntitlementsToken(entToken);
        }
      } catch (e) {
        accessToken = await secureStorage.getAccessToken();
      }

      if (accessToken == null) {
        return Future.value(true);
      }

      final entitlementsToken = await secureStorage.getEntitlementsToken();
      final clientVersion = await secureStorage.getClientVersion() ??
          'release-09.08-shipping-9-2917531';

      // Setup dio with Riot headers
      final riotDio = Dio(
        BaseOptions(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'X-Riot-Entitlements-JWT': entitlementsToken ?? '',
            'X-Riot-ClientVersion': clientVersion,
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
      final offers = (skinsPanel['SingleItemOffers'] as List<dynamic>? ?? [])
          .map((e) => e.toString().toLowerCase())
          .toList();

      // Check wishlist
      final wishlist = await localStore.getWishlist();
      final matchedNames = <String>[];
      String? firstMatchUuid;

      for (final item in wishlist) {
        if (offers.contains(item.uuid.toLowerCase())) {
          matchedNames.add(item.displayName);
          firstMatchUuid ??= item.uuid;
        }
      }

      if (matchedNames.isNotEmpty) {
        final notificationService = NotificationService();
        await notificationService.init();
        await notificationService.showWishlistMatchNotification(
          matchedSkinNames: matchedNames,
          skinUuid: firstMatchUuid,
        );
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(true);
    }
  });
}

class BackgroundTaskManager {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    } catch (e) {
      debugPrint('Workmanager init error: $e');
    }
  }

  static Future<void> registerPeriodicStoreCheck() async {
    if (kIsWeb) return;
    try {
      await Workmanager().registerPeriodicTask(
        dailyStoreCheckTaskKey,
        dailyStoreCheckTaskKey,
        tag: periodicStoreCheckTaskTag,
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('Workmanager registration error: $e');
    }
  }

  static Future<void> cancelStoreCheck() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByTag(periodicStoreCheckTaskTag);
    } catch (e) {
      debugPrint('Workmanager cancel error: $e');
    }
  }
}
