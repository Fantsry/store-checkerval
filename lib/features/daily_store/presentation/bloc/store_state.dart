import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';

sealed class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {
  const StoreInitial();
}

class StoreLoading extends StoreState {
  const StoreLoading();
}

class StoreLoaded extends StoreState {
  final DailyStore store;
  final UserWallet wallet;
  final bool isOffline;

  const StoreLoaded({
    required this.store,
    this.wallet = const UserWallet(),
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [store, wallet, isOffline];
}

class StoreError extends StoreState {
  final String message;
  const StoreError(this.message);

  @override
  List<Object?> get props => [message];
}
