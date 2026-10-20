/// StoreCheckerVal GoRouter configuration
///
/// 5-Tab Shell:
/// - /home        → Dashboard (Player card, store preview, recent match, live radar)
/// - /store       → Daily rotating store, bundle hero, night market
/// - /tracker     → Match history, ACS, K/D, rank overview
/// - /collection  → Inventory arsenal, valuation, filters
/// - /profile     → Settings, notifications, logout
///
/// Modals & Fullscreen:
/// - /match-detail → Full match analysis (Scoreboard, Rounds, Performance)
/// - /live-match   → Real-time match telemetry
/// - /wishlist     → Wishlist manager
/// - /catalog      → Full skin catalog
/// - /battlepass   → Battlepass progression

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/app/shell_page.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/presentation/login_page.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/pages/battlepass_page.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/pages/career_page.dart';
import 'package:valorant_store_tracker/features/career/presentation/pages/match_detail_page.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/pages/skin_detail_page.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/pages/store_page.dart';
import 'package:valorant_store_tracker/features/home/presentation/pages/home_page.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/pages/inventory_page.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/pages/live_match_page.dart';
import 'package:valorant_store_tracker/features/settings/presentation/settings_page.dart';
import 'package:valorant_store_tracker/features/social/presentation/pages/social_page.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/pages/catalog_page.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/pages/wishlist_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: _guard,
    routes: [
      // ─── Login ────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ─── Main Shell (5 Bottom Nav Tabs) ───────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/store',
            name: 'store',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StorePage(),
            ),
          ),
          GoRoute(
            path: '/tracker',
            name: 'tracker',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CareerPage(),
            ),
          ),
          // Backward compat alias
          GoRoute(
            path: '/career',
            redirect: (_, __) => '/tracker',
          ),
          GoRoute(
            path: '/collection',
            name: 'collection',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InventoryPage(),
            ),
          ),
          // Backward compat alias
          GoRoute(
            path: '/inventory',
            redirect: (_, __) => '/collection',
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
          // Backward compat alias
          GoRoute(
            path: '/settings',
            redirect: (_, __) => '/profile',
          ),
        ],
      ),

      // ─── Full-Screen Push Pages ───────────────────────────
      GoRoute(
        path: '/match-detail',
        name: 'matchDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final match = state.extra as MatchSummary;
          return MatchDetailPage(match: match);
        },
      ),
      GoRoute(
        path: '/live-match',
        name: 'liveMatch',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LiveMatchPage(),
      ),
      GoRoute(
        path: '/social',
        name: 'social',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SocialPage(),
      ),
      GoRoute(
        path: '/friends',
        name: 'friends',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SocialPage(),
      ),
      GoRoute(
        path: '/wishlist',
        name: 'wishlist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WishlistPage(),
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
        path: '/battlepass',
        name: 'battlepass',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BattlepassPage(),
      ),
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

  /// Auth guard — redirect to login if no active session.
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
      return '/home';
    }

    return null;
  }
}
