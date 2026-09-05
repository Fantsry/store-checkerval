import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valorant_store_tracker/app/app.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/app/router.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
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
      systemNavigationBarColor: Color(0xFF1B2733),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize core services
  await TimezoneHelper.initialize();
  await setupDI();

  // Initialize Notifications with deep-link navigation
  final notificationService = getIt<NotificationService>();
  await notificationService.init(
    onSelectNotification: (payload) {
      if (payload != null && payload.isNotEmpty) {
        AppRouter.router.push(payload);
      }
    },
  );

  // Initialize Background Scheduler
  await BackgroundTaskManager.initialize();
  await BackgroundTaskManager.registerPeriodicStoreCheck();

  runApp(const ValorantStoreApp());
}
