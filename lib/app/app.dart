import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/app/router.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';

class ValorantStoreApp extends StatefulWidget {
  const ValorantStoreApp({super.key});

  @override
  State<ValorantStoreApp> createState() => _ValorantStoreAppState();
}

class _ValorantStoreAppState extends State<ValorantStoreApp>
    with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyBiometricLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _applyBiometricLock();
    }
  }

  Future<void> _applyBiometricLock() async {
    try {
      final enabled = await getIt<SecureStorageService>().isBiometricEnabled();
      if (!enabled || !mounted) return;
      setState(() => _locked = true);
      await _unlock();
    } catch (_) {
      // Platform biometric APIs are unavailable in tests/unsupported devices.
    }
  }

  Future<void> _unlock() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Valorant Store Tracker',
      );
      if (authenticated && mounted) {
        setState(() => _locked = false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) return _buildLockScreen();
    return _buildApp();
  }

  Widget _buildLockScreen() {
    return MaterialApp(
      title: 'Valorant Store Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1923),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'App locked',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _unlock,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => getIt<ProfileCubit>()..loadProfile(),
        ),
        BlocProvider<CareerCubit>(
          create: (_) => getIt<CareerCubit>()..loadCareer(),
        ),
        BlocProvider<StoreCubit>(
          create: (_) => getIt<StoreCubit>()..fetchStore(),
        ),
        BlocProvider<WishlistCubit>(
          create: (_) => getIt<WishlistCubit>()..loadWishlist(),
        ),
        BlocProvider<StoreAlertCubit>(
          create: (_) => getIt<StoreAlertCubit>()..loadRules(),
        ),
        BlocProvider<InventoryCubit>(
          create: (_) => getIt<InventoryCubit>()..loadInventory(),
        ),
        BlocProvider<BattlepassCubit>(
          create: (_) => getIt<BattlepassCubit>(),
        ),
        BlocProvider<LiveMatchCubit>(
          create: (_) => getIt<LiveMatchCubit>(),
        ),
        BlocProvider<SocialCubit>(
          create: (_) => getIt<SocialCubit>()..loadFriends(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Valorant Store Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
