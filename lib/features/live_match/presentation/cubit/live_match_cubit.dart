import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';

class LiveMatchCubit extends Cubit<LiveMatchState> {
  final LiveMatchRepository _repository;

  LiveMatchCubit({required LiveMatchRepository repository})
      : _repository = repository,
        super(const LiveMatchInitial());

  Future<void> scanLiveMatch() async {
    emit(const LiveMatchLoading());

    final result = await _repository.checkLiveMatch();

    result.when(
      success: (data) => emit(LiveMatchLoaded(matchData: data)),
      failure: (failure) => emit(LiveMatchError(message: failure.message)),
    );
  }
}
