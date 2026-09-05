/// GoRouter configuration with deep link support.
///
/// Routes:
/// - /login          → Login WebView
/// - /               → Main shell (bottom nav)
///   - /store        → Daily Store
///   - /wishlist     → Wishlist
///   - /settings     → Settings
/// - /skin/:id       → Skin Detail (deep link from notification)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/presentation/login_page.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/pages/store_page.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/pages/skin_detail_page.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/pages/catalog_page.dart';
import 'package:valorant_store_tracker/features/settings/presentation/settings_page.dart';
import 'package:valorant_store_tracker/app/shell_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/store',
    redirect: _guard,
    routes: [
      // ─── Login ────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ─── Main Shell (Bottom Nav) ─────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/store',
            name: 'store',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StorePage(),
            ),
          ),
          GoRoute(
            path: '/wishlist',
            name: 'wishlist',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WishlistPage(),
            ),
            routes: [
              GoRoute(
                path: 'catalog',
                name: 'catalog',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CatalogPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),

      // ─── Skin Detail (Deep Link from Notification) ──────
      GoRoute(
        path: '/skin/:skinId',
        name: 'skinDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final skinId = state.pathParameters['skinId']!;
          return SkinDetailPage(skinId: skinId);
        },
      ),
    ],
  );

  /// Auth guard — redirect to login if no session.
  static Future<String?> _guard(
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!getIt.isRegistered<SecureStorageService>()) {
      return null;
    }

    final storage = getIt<SecureStorageService>();
    final hasSession = await storage.hasSession();
    final isLoginRoute = state.matchedLocation == '/login';

    if (!hasSession && !isLoginRoute) {
      return '/login';
    }
    if (hasSession && isLoginRoute) {
      return '/store';
    }

    return null;
  }
}
