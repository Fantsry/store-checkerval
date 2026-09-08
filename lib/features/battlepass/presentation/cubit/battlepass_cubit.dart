import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/repositories/battlepass_repository.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_state.dart';

class BattlepassCubit extends Cubit<BattlepassState> {
  final BattlepassRepository _repository;

  BattlepassCubit({required BattlepassRepository repository})
      : _repository = repository,
        super(const BattlepassInitial());

  Future<void> loadBattlepass({bool forceRefresh = false}) async {
    if (state is! BattlepassLoaded) {
      emit(const BattlepassLoading());
    }

    final result =
        await _repository.getBattlepassOverview(forceRefresh: forceRefresh);

    result.when(
      success: (overview) => emit(BattlepassLoaded(overview: overview)),
      failure: (failure) {
        if (state is! BattlepassLoaded) {
          emit(BattlepassError(message: failure.message));
        }
      },
    );
  }
}
