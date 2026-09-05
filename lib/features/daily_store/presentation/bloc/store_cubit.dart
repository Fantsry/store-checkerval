import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _storeRepository;

  StoreCubit({required StoreRepository storeRepository})
      : _storeRepository = storeRepository,
        super(const StoreInitial());

  Future<void> fetchStore({bool forceRefresh = false}) async {
    if (state is! StoreLoaded) {
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
      },
      failure: (failure) {
        emit(StoreError(failure.message));
      },
    );
  }
}
