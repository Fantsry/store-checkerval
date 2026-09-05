import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String storeChannelId = 'valorant_store_channel';
  static const String storeChannelName = 'Store Wishlist Alerts';
  static const String storeChannelDescription =
      'Notifications when wishlisted skins appear in your daily store';

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

    // Create Android notification channel
    final androidChannel = AndroidNotificationChannel(
      storeChannelId,
      storeChannelName,
      description: storeChannelDescription,
      importance: Importance.high,
      enableVibration: true,
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

  Future<void> showWishlistMatchNotification({
    required List<String> matchedSkinNames,
    String? skinUuid,
  }) async {
    if (matchedSkinNames.isEmpty) return;

    final title = matchedSkinNames.length == 1
        ? '🎯 Wishlist Skin in Store!'
        : '🎯 ${matchedSkinNames.length} Wishlist Skins in Store!';

    final body = matchedSkinNames.length == 1
        ? '${matchedSkinNames.first} is available in your daily store today!'
        : '${matchedSkinNames.join(", ")} are in your store today!';

    final androidDetails = AndroidNotificationDetails(
      storeChannelId,
      storeChannelName,
      channelDescription: storeChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Wishlist Skin Alert',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Valorant Daily Store',
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
}
