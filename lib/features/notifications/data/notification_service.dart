import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String storeChannelId = 'valorant_store_channel';
  static const String storeChannelName = 'Store Wishlist & Item Alerts';
  static const String storeChannelDescription =
      'Notifications when wishlist skins or target weapon tiers appear in your daily store';

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
        ? '👀 Skin incaranmu nongol di store nih!'
        : '🎉 Hoki parah! Ada ${matchedSkinNames.length} skin wishlist kamu!';

    final body = matchedSkinNames.length == 1
        ? 'Wih rezeki! ${matchedSkinNames.first} lagi mejeng di daily store kamu hari ini. Buruan bungkus sebelum reset! 🛒🔥'
        : 'Gokil! ${matchedSkinNames.join(", ")} nongol barengan di daily store kamu hari ini. Gas amankan sebelum kelewatan ya! 💸✨';

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
      ticker: '🔥 Skin Wishlist Muncul!',
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
        ? '🚨 Masuk radar! Ada skin incaranmu nih'
        : '🚨 Masuk radar! Ada $totalItems skin incaran kamu';

    final buffer = StringBuffer();
    for (final entry in ruleMatches.entries) {
      buffer.writeln('🎯 ${entry.key}: ${entry.value.join(", ")}');
    }
    buffer.write('Yuk intip store-nya sekarang sebelum rotasinya ganti! 🏃‍♂️💨');
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
      ticker: '⚡ Radar Skin Valorant!',
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

  /// Sends a test notification to verify sounds, banners, and vibration.
  Future<void> showTestNotification() async {
    const title = '🔔 Mantap! Notifikasi toko udah nyala!';
    const body =
        'Tes sukses! Tenang aja, pas skin impianmu atau skin incaranmu (Melee, Vandal, dll.) nongol di store, kita langsung colek kamu. Siapin VP-mu ya! 🎮💸';

    const androidDetails = AndroidNotificationDetails(
      storeChannelId,
      storeChannelName,
      channelDescription: storeChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: '🔔 Tes Notifikasi Berhasil',
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

  /// Evaluates both Wishlist items and Custom Alert Rules against [store].
  /// Deduplicates so the user is only notified once per store day (00:00 UTC cycle).
  Future<void> evaluateStoreOffers({
    required DailyStore store,
    required List<WishlistItem> wishlist,
    required List<StoreAlertRule> alertRules,
    required LocalStoreService localStore,
    bool deduplicate = true,
  }) async {
    if (store.featuredOffers.isEmpty) return;

    // Check if already notified for today's store rotation (UTC 00:00 reset)
    final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    if (deduplicate) {
      final lastNotified = await localStore.getLastNotifiedStoreDate();
      if (lastNotified == todayKey) {
        return; // Already notified today
      }
    }

    // 1. Evaluate Wishlist Matches
    final matchedWishlistNames = <String>[];
    String? firstWishlistUuid;

    for (final skin in store.featuredOffers) {
      final isWishlisted = wishlist.any((w) {
        if (w.uuid.toLowerCase() == skin.uuid.toLowerCase()) return true;
        if (skin.levels.any(
            (lvl) => lvl.uuid.toLowerCase() == w.uuid.toLowerCase())) {
          return true;
        }
        return w.displayName.trim().toLowerCase() ==
            skin.displayName.trim().toLowerCase();
      });

      if (isWishlisted) {
        matchedWishlistNames.add(skin.displayName);
        firstWishlistUuid ??= skin.uuid;
      }
    }

    // 2. Evaluate Custom Alert Rules Matches
    final ruleMatches = <String, List<String>>{};
    final activeRules = alertRules.where((r) => r.isEnabled).toList();

    for (final rule in activeRules) {
      for (final skin in store.featuredOffers) {
        if (rule.matches(skin)) {
          final list = ruleMatches.putIfAbsent(rule.displayName, () => []);
          if (!list.contains(skin.displayName)) {
            list.add(skin.displayName);
          }
        }
      }
    }

    bool hasNotified = false;

    // Trigger Wishlist notification
    if (matchedWishlistNames.isNotEmpty) {
      await showWishlistMatchNotification(
        matchedSkinNames: matchedWishlistNames,
        skinUuid: firstWishlistUuid,
      );
      hasNotified = true;
    }

    // Trigger Custom Alert notification
    if (ruleMatches.isNotEmpty) {
      await showCustomAlertNotification(
        ruleMatches: ruleMatches,
      );
      hasNotified = true;
    }

    if (hasNotified && deduplicate) {
      await localStore.setLastNotifiedStoreDate(todayKey);
    }
  }
}
