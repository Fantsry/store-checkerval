import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valorant_store_tracker/app/app.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/app/router.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/notifications/data/background_task_manager.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF111412),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize core services
  await TimezoneHelper.initialize();
  await setupDI();

  // Proactively refresh Riot client version in background to stay compatible with new game updates/acts
  getIt<AuthRepository>().getClientVersion().ignore();

  // Initialize Notifications with deep-link navigation
  final notificationService = getIt<NotificationService>();
  await notificationService.init(
    onSelectNotification: (payload) {
      if (payload != null && payload.isNotEmpty) {
        AppRouter.router.push(payload);
      }
    },
  );

  // Ask for notification permission once per install. Denials are handled in
  // Settings instead of prompting on every cold start.
  final secureStorage = getIt<SecureStorageService>();
  if (!await secureStorage.isNotificationPermissionAsked()) {
    final granted = await notificationService.requestPermissions();
    await secureStorage.setNotificationPermissionAsked(true);
    if (!granted) {
      await secureStorage.setNotificationsEnabled(false);
    }
  }

  // Initialize Background Scheduler & schedule next shop reset check (00:00 UTC)
  await BackgroundTaskManager.initialize();
  if (await secureStorage.areNotificationsEnabled()) {
    await BackgroundTaskManager.scheduleNextResetCheck();
    await BackgroundTaskManager.registerPeriodicStoreCheck();
    await BackgroundTaskManager.registerPeriodicChatCheck();
  }

  runApp(const ValorantStoreApp());
}
