import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String storeChannelId = 'valorant_store_channel';
  static const String storeChannelName = 'Store Wishlist & Item Alerts';
  static const String storeChannelDescription =
      'Notifications when wishlist skins or target weapon tiers appear in your daily store';
  static const String chatChannelId = 'valorant_chat_channel';
  static const String chatChannelName = 'Riot Chat Messages';
  static const String chatChannelDescription =
      'Notifications for new direct messages from your Riot friends';

  Future<void> init({void Function(String? payload)? onSelectNotification}) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && onSelectNotification != null) {
          onSelectNotification(response.payload);
        }
      },
    );

    // Create Android notification channel with max priority and lock-screen visibility
    final androidChannel = AndroidNotificationChannel(
      storeChannelId,
      storeChannelName,
      description: storeChannelDescription,
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFFF4655),
      playSound: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          chatChannelId,
          chatChannelName,
          description: chatChannelDescription,
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF4655),
        ),
      );
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Sends a notification when a wishlisted skin appears in daily store.
  Future<void> showWishlistMatchNotification({
    required List<String> matchedSkinNames,
    String? skinUuid,
  }) async {
    if (matchedSkinNames.isEmpty) return;

    final title = matchedSkinNames.length == 1
        ? 'Skin incaranmu ada di store!'
        : 'Ada ${matchedSkinNames.length} skin wishlist kamu di store!';

    final body = matchedSkinNames.length == 1
        ? '${matchedSkinNames.first} tersedia di daily store kamu hari ini. Cek sebelum reset!'
        : '${matchedSkinNames.join(", ")} tersedia di daily store kamu hari ini. Cek sebelum reset!';

    final androidDetails = AndroidNotificationDetails(
      storeChannelId,
      storeChannelName,
      channelDescription: storeChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFFFF4655),
      ledColor: const Color(0xFFFF4655),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Skin Wishlist Muncul',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Toko Valorant Hari Ini',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
      payload: skinUuid != null ? '/skin/$skinUuid' : '/store',
    );
  }

  /// Sends a notification when custom alert rules (e.g. any Melee, Vandal Premium+) match.
  Future<void> showCustomAlertNotification({
    required Map<String, List<String>> ruleMatches,
  }) async {
    if (ruleMatches.isEmpty) return;

    final totalItems =
        ruleMatches.values.fold<int>(0, (prev, list) => prev + list.length);
    final title = totalItems == 1
        ? 'Masuk radar! Ada skin incaranmu'
        : 'Masuk radar! Ada $totalItems skin incaran kamu';

    final buffer = StringBuffer();
    for (final entry in ruleMatches.entries) {
      buffer.writeln('${entry.key}: ${entry.value.join(", ")}');
    }
    buffer.write('Silakan cek store kamu sekarang sebelum rotasi berganti.');
    final body = buffer.toString().trim();

    final androidDetails = AndroidNotificationDetails(
      storeChannelId,
      storeChannelName,
      channelDescription: storeChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFFFF4655),
      ledColor: const Color(0xFFFF4655),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Radar Skin Valorant',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Alert Toko Valorant',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      title,
      body,
      details,
      payload: '/store',
    );
  }

  Future<void> showNightMarketNotification({
    required List<NightMarketItem> matches,
  }) async {
    if (matches.isEmpty) return;

    final title = matches.length == 1
        ? 'Night Market: skin incaranmu muncul!'
        : 'Night Market: ${matches.length} skin incaranmu muncul!';
    final lines = matches
        .map(
          (item) =>
              '${item.skin.displayName} - ${item.discountPercent}% OFF '
              '(${item.discountedCost} VP)',
        )
        .join('\n');
    final body =
        '$lines\nBuka aplikasi sebelum Night Market berganti.';

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.show(
      2,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          storeChannelId,
          storeChannelName,
          channelDescription: storeChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          enableLights: true,
          color: const Color(0xFFFF4655),
          ledColor: const Color(0xFFFF4655),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Night Market',
          ),
        ),
        iOS: iosDetails,
      ),
      payload: '/store',
    );
  }

  Future<void> showAccessoryNotification({
    required List<AccessoryStoreItem> items,
  }) async {
    if (items.isEmpty) return;

    final title = 'Accessory store minggu ini sudah tersedia';
    final preview = items.take(5).map((item) => item.displayName).join(', ');
    final remaining = items.length > 5 ? ' +${items.length - 5} lainnya' : '';
    final body =
        '$preview$remaining\nCek koleksi Kingdom Credits kamu sekarang.';

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.show(
      3,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          storeChannelId,
          storeChannelName,
          channelDescription: storeChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          enableLights: true,
          color: const Color(0xFFFF4655),
          ledColor: const Color(0xFFFF4655),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Accessory Store',
          ),
        ),
        iOS: iosDetails,
      ),
      payload: '/store',
    );
  }

  Future<void> showChatNotification({
    required String senderName,
    required String body,
    String? senderPuuid,
  }) async {
    final title = 'Pesan baru dari $senderName';
    final preview = body.length > 140 ? '${body.substring(0, 140)}...' : body;
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.show(
      4,
      title,
      preview,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chatChannelId,
          chatChannelName,
          channelDescription: chatChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(
            preview,
            contentTitle: title,
            summaryText: 'Riot Chat',
          ),
        ),
        iOS: iosDetails,
      ),
      payload: senderPuuid == null || senderPuuid.isEmpty
          ? '/social'
          : '/social?friend=$senderPuuid',
    );
  }

  /// Sends a test notification to verify sounds, banners, and vibration.
  Future<void> showTestNotification() async {
    const title = 'Notifikasi toko sudah aktif';
    const body =
        'Tes sukses! Saat skin incaranmu muncul di store, kamu akan langsung mendapatkan notifikasi.';

    const androidDetails = AndroidNotificationDetails(
      storeChannelId,
      storeChannelName,
      channelDescription: storeChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Tes Notifikasi Berhasil',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Status Toko Valorant',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      999,
      title,
      body,
      details,
      payload: '/store',
    );
  }

  /// Evaluates wishlist, custom rules, Night Market, and accessory offers.
  ///
  /// Daily offers are deduplicated per UTC store day. Night Market and
  /// accessory alerts are deduplicated per rotation, so they still work even
  /// when the daily store was already announced.
  Future<void> evaluateStoreOffers({
    required DailyStore store,
    required List<WishlistItem> wishlist,
    required List<StoreAlertRule> alertRules,
    required LocalStoreService localStore,
    required bool notificationsEnabled,
    bool nightMarketAlertsEnabled = true,
    bool accessoryAlertsEnabled = true,
    bool deduplicate = true,
  }) async {
    if (!notificationsEnabled) return;

    final activeRules = alertRules.where((r) => r.isEnabled).toList();
    final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    // ─── Daily store ──────────────────────────────────────────
    var dailyAlreadyNotified = false;
    if (deduplicate) {
      dailyAlreadyNotified =
          await localStore.getLastNotifiedStoreDate() == todayKey;
    }

    if (!dailyAlreadyNotified && store.featuredOffers.isNotEmpty) {
      final matchedWishlistNames = <String>[];
      String? firstWishlistUuid;

      for (final skin in store.featuredOffers) {
        if (_matchesWishlist(skin, wishlist)) {
          matchedWishlistNames.add(skin.displayName);
          firstWishlistUuid ??= skin.uuid;
        }
      }

      final ruleMatches = <String, List<String>>{};
      for (final rule in activeRules) {
        for (final skin in store.featuredOffers) {
          if (!rule.matches(skin)) continue;
          final list = ruleMatches.putIfAbsent(rule.displayName, () => []);
          if (!list.contains(skin.displayName)) {
            list.add(skin.displayName);
          }
        }
      }

      var hasNotified = false;
      if (matchedWishlistNames.isNotEmpty) {
        await showWishlistMatchNotification(
          matchedSkinNames: matchedWishlistNames,
          skinUuid: firstWishlistUuid,
        );
        hasNotified = true;
      }
      if (ruleMatches.isNotEmpty) {
        await showCustomAlertNotification(ruleMatches: ruleMatches);
        hasNotified = true;
      }

      if (hasNotified && deduplicate) {
        await localStore.setLastNotifiedStoreDate(todayKey);
      }
    }

    // ─── Night Market ─────────────────────────────────────────
    final nightMarketOffers = store.nightMarket?.offers ?? const [];
    if (nightMarketAlertsEnabled && nightMarketOffers.isNotEmpty) {
      final rotationKey = (nightMarketOffers
              .map((item) => item.skin.uuid.toLowerCase())
              .toSet()
              .toList()
            ..sort())
          .join('|');

      final alreadyNotified = deduplicate &&
          await localStore.getLastNotifiedNightMarketRotation() ==
              rotationKey;

      if (!alreadyNotified) {
        final matches = nightMarketOffers.where((item) {
          if (_matchesWishlist(item.skin, wishlist)) return true;
          return activeRules.any((rule) => rule.matches(item.skin));
        }).toList();

        if (matches.isNotEmpty) {
          await showNightMarketNotification(matches: matches);
          if (deduplicate) {
            await localStore.setLastNotifiedNightMarketRotation(rotationKey);
          }
        }
      }
    }

    // ─── Accessory store ──────────────────────────────────────
    if (accessoryAlertsEnabled && store.accessoryOffers.isNotEmpty) {
      final rotationKey = (store.accessoryOffers
              .map((item) => item.uuid.toLowerCase())
              .toSet()
              .toList()
            ..sort())
          .join('|');

      final alreadyNotified = deduplicate &&
          await localStore.getLastNotifiedAccessoryRotation() == rotationKey;

      if (!alreadyNotified) {
        await showAccessoryNotification(items: store.accessoryOffers);
        if (deduplicate) {
          await localStore.setLastNotifiedAccessoryRotation(rotationKey);
        }
      }
    }
  }

  bool _matchesWishlist(SkinItem skin, List<WishlistItem> wishlist) {
    return wishlist.any((w) {
      if (w.uuid.toLowerCase() == skin.uuid.toLowerCase()) return true;
      if (skin.levels.any(
          (lvl) => lvl.uuid.toLowerCase() == w.uuid.toLowerCase())) {
        return true;
      }
      return w.displayName.trim().toLowerCase() ==
          skin.displayName.trim().toLowerCase();
    });
  }
}
