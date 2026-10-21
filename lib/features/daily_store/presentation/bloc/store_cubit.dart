import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/daily_store/data/store_widget_service.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _storeRepository;
  final NotificationService? _notificationService;
  final LocalStoreService? _localStore;
  final SecureStorageService? _secureStorage;
  final StoreWidgetService? _widgetService;

  StoreCubit({
    required StoreRepository storeRepository,
    NotificationService? notificationService,
    LocalStoreService? localStore,
    SecureStorageService? secureStorage,
    StoreWidgetService? widgetService,
  }) : _storeRepository = storeRepository,
       _notificationService = notificationService,
       _localStore = localStore,
       _secureStorage = secureStorage,
       _widgetService = widgetService,
       super(const StoreInitial());

  Future<void> fetchStore({bool forceRefresh = false}) async {
    if (forceRefresh || state is! StoreLoaded) {
      emit(const StoreLoading());
    }

    final storeResult = await _storeRepository.getDailyStore(
      forceRefresh: forceRefresh,
    );
    final walletResult = await _storeRepository.getUserWallet();

    final wallet = walletResult.valueOrNull ?? const UserWallet();

    storeResult.when(
      success: (dailyStore) {
        emit(StoreLoaded(store: dailyStore, wallet: wallet));

        unawaited(_widgetService?.update(dailyStore));

        // Evaluate wishlist & custom alert notifications
        if (_notificationService != null && _localStore != null) {
          _evaluateNotifications(dailyStore);
        }
      },
      failure: (failure) {
        emit(StoreError(failure.message));
      },
    );
  }

  void reset() => emit(const StoreInitial());

  Future<void> _evaluateNotifications(DailyStore store) async {
    final localStore = _localStore;
    final notificationService = _notificationService;
    if (localStore == null || notificationService == null) return;

    try {
      final notificationsEnabled =
          await _secureStorage?.areNotificationsEnabled() ?? true;
      if (!notificationsEnabled) return;

      final wishlist = await localStore.getWishlist();
      final alertRules = await localStore.getAlertRules();
      await notificationService.evaluateStoreOffers(
        store: store,
        wishlist: wishlist,
        alertRules: alertRules,
        localStore: localStore,
        deduplicate: true,
        notificationsEnabled: notificationsEnabled,
        languageCode: await localStore.getLocale(),
        nightMarketAlertsEnabled: await localStore
            .areNightMarketAlertsEnabled(),
        accessoryAlertsEnabled: await localStore.areAccessoryAlertsEnabled(),
      );
    } catch (_) {}
  }
}
