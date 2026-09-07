import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _storeRepository;
  final NotificationService? _notificationService;
  final LocalStoreService? _localStore;

  StoreCubit({
    required StoreRepository storeRepository,
    NotificationService? notificationService,
    LocalStoreService? localStore,
  })  : _storeRepository = storeRepository,
        _notificationService = notificationService,
        _localStore = localStore,
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
        emit(
          StoreLoaded(
            store: dailyStore,
            wallet: wallet,
          ),
        );

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

  Future<void> _evaluateNotifications(DailyStore store) async {
    final localStore = _localStore;
    final notificationService = _notificationService;
    if (localStore == null || notificationService == null) return;

    try {
      final wishlist = await localStore.getWishlist();
      final alertRules = await localStore.getAlertRules();
      await notificationService.evaluateStoreOffers(
        store: store,
        wishlist: wishlist,
        alertRules: alertRules,
        localStore: localStore,
        deduplicate: true,
      );
    } catch (_) {}
  }
}
